#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration variables
GPS_DEVICE="${GPS_DEVICE:-/dev/ttyAMA0}"
PPS_DEVICE="${PPS_DEVICE:-/dev/pps0}"
GPS_SPEED="${GPS_SPEED:-9600}"
GPSD_SOCKET="${GPSD_SOCKET:-/var/run/gpsd.sock}"
DEBUG_LEVEL="${DEBUG_LEVEL:-1}" #gpsd debug level
LOG_LEVEL="${LOG_LEVEL:-0}" #chrony log level



# Function to log messages with timestamps
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to check if device exists
check_device() {
    local device="$1"
    if [[ ! -e "$device" ]]; then
        log "WARNING: Device $device does not exist"
        return 1
    fi
    return 0
}

# Function to start gpsd
start_gpsd() {
    log "Starting GPSD service..."
    
    # Check if GPS device exists
    if ! check_device "$GPS_DEVICE"; then
        log "ERROR: GPS device $GPS_DEVICE not found"
        return 1
    fi
    
    # Check if PPS device exists (optional)
    local pps_arg=""
    if check_device "$PPS_DEVICE"; then
        pps_arg="$PPS_DEVICE"
        log "PPS device found: $PPS_DEVICE"
    else
        log "WARNING: PPS device $PPS_DEVICE not found, continuing without PPS"
    fi
    
    # Build gpsd command
    local gpsd_cmd=(
	gpsd
        -G              # Listen on all addresses
        -n              # Don't wait for client to connect
        -D"$DEBUG_LEVEL" # Debug level
        -F "$GPSD_SOCKET" # Control socket
        -s "$GPS_SPEED"   # Fixed speed
        "$GPS_DEVICE"
    )
    
    # Add PPS device if available
    [[ -n "$pps_arg" ]] && gpsd_cmd+=("$pps_arg")
    
    # Add any additional arguments
    gpsd_cmd+=("$@")
    
    log "Executing: ${gpsd_cmd[*]}"
    "${gpsd_cmd[@]}" &
    local gpsd_pid=$!
    log "GPSD started with PID: $gpsd_pid"
    echo "$gpsd_pid" > /var/run/gpsd.pid
    
    return 0
}

# Function to start chronyd
start_chronyd() {
    log "Starting Chrony service..."
    
    # Check if chronyd exists
    if [[ ! -x "/usr/sbin/chronyd" ]]; then
        log "ERROR: chronyd not found at /usr/sbin/chronyd"
        return 1
    fi

    # Check if chrony user exists
    if ! id -u chrony &>/dev/null; then
        log "ERROR: User 'chrony' does not exist"
        return 1
    fi

    # confirm correct permissions on chrony run directory
        if [ -d /run/chrony ]; then
        chown -R chrony:chrony /run/chrony
        chmod o-rx /run/chrony
        # remove previous pid file if it exist
        rm -f /var/run/chrony/chronyd.pid
    fi

    # confirm correct permissions on chrony variable state directory
    if [ -d /var/lib/chrony ]; then
        chown -R chrony:chrony /var/lib/chrony
    fi

    # LOG_LEVEL environment variable is not present, so populate with chrony default (0)
    # chrony log levels: 0 (informational), 1 (warning), 2 (non-fatal error) and 3 (fatal error)
    if [ -z "${LOG_LEVEL}" ]; then
        LOG_LEVEL=0
    else
    # confirm log level is between 0-3, since these are the only log levels supported
        if expr "${LOG_LEVEL}" : "[^0123]" > /dev/null; then
            # level outside of supported range, let's set to default (0)
            LOG_LEVEL=0
        fi
    fi

    # enable control of system clock, enabled by default
    SYSCLK=""
    if [[ "${ENABLE_SYSCLK:-true}" = false ]]; then
        SYSCLK="-x"
    fi
    
    local chronyd_cmd=(
        /usr/sbin/chronyd
        -u chrony       # Run as chrony user
        -d              # Foreground mode
        ${SYSCLK}       # Allow system clock control
        -L"$LOG_LEVEL"  # Log level
    )
    
    log "Executing: ${chronyd_cmd[*]}"
    "${chronyd_cmd[@]}" &
    local chronyd_pid=$!
    log "Chronyd started with PID: $chronyd_pid"
    echo "$chronyd_pid" > /var/run/chronyd.pid
    
    return 0
}

# Function to handle shutdown signals
cleanup() {
    log "Received shutdown signal, cleaning up..."
    
    # Kill chronyd if running
    if [[ -f /var/run/chronyd.pid ]]; then
        local chronyd_pid=$(cat /var/run/chronyd.pid)
        if kill -0 "$chronyd_pid" 2>/dev/null; then
            log "Stopping chronyd (PID: $chronyd_pid)"
            kill -TERM "$chronyd_pid"
            wait "$chronyd_pid" 2>/dev/null || true
        fi
        rm -f /var/run/chronyd.pid
    fi
    
    # Kill gpsd if running
    if [[ -f /var/run/gpsd.pid ]]; then
        local gpsd_pid=$(cat /var/run/gpsd.pid)
        if kill -0 "$gpsd_pid" 2>/dev/null; then
            log "Stopping gpsd (PID: $gpsd_pid)"
            kill -TERM "$gpsd_pid"
            wait "$gpsd_pid" 2>/dev/null || true
        fi
        rm -f /var/run/gpsd.pid
    fi
    
    log "Cleanup completed"
    exit 0
}

# Function to wait for services and monitor them
monitor_services() {
    log "Monitoring services..."
    
    while true; do
        # Check if gpsd is still running
        if [[ -f /var/run/gpsd.pid ]]; then
            local gpsd_pid=$(cat /var/run/gpsd.pid)
            if ! kill -0 "$gpsd_pid" 2>/dev/null; then
                log "ERROR: GPSD process died unexpectedly"
                cleanup
                exit 1
            fi
        fi
        
        # Check if chronyd is still running
        if [[ -f /var/run/chronyd.pid ]]; then
            local chronyd_pid=$(cat /var/run/chronyd.pid)
            if ! kill -0 "$chronyd_pid" 2>/dev/null; then
                log "ERROR: Chronyd process died unexpectedly"
                cleanup
                exit 1
            fi
        fi
        
        sleep 5
    done
}

# Main execution
main() {
    log "=== GPS/Chrony Startup Script ==="
    log "Container info:"
    log "  User: $(whoami) UID: $(id -u) GID: $(id -g)"
    log "  GPS Device: $GPS_DEVICE"
    log "  PPS Device: $PPS_DEVICE"
    log "  GPS Speed: $GPS_SPEED"
    log "  GPSD Debug Level: $DEBUG_LEVEL"
    log "  Chrony Log Level: $LOG_LEVEL"
    
    # Set up signal handlers
    trap cleanup SIGTERM SIGINT SIGQUIT
    
    # Start services

    # start chronyd first
    if ! start_chronyd; then
        log "ERROR: Failed to start Chronyd"
        cleanup
        exit 1
    fi

    sleep 2

    # now start gpsd
    if ! start_gpsd "$@"; then
        log "ERROR: Failed to start GPSD"
        exit 1
    fi
    
    # Give gpsd a moment to initialize

    sleep 10
    
    log "All services started successfully"

    
    # Monitor services, not working correctly right now
    #monitor_services

    wait  #hack to keep containers running, remove after monitor services is fixed
}

# Run main function with all arguments
main "$@"