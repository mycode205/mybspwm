#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do
    sleep 1
done

# ==================================
# AUTOMATIC HARDWARE DETECTION
# ==================================

# 1. Detect dynamic network hardware interfaces
export WIRELESS_INT=$(ip link | awk -F': ' '/wl/{print $2}' | head -n 1)
export WIRED_INT=$(ip link | awk -F': ' '/enp|eth/{print $2}' | head -n 1)

# 2. Auto detect primary monitor with fallback selection
MONITOR=$(xrandr | grep " connected primary" | cut -d" " -f1)

# Fallback to first available connected screen if no primary is explicitly set
if [ -z "$MONITOR" ]; then
    MONITOR=$(xrandr | grep " connected" | head -n1 | cut -d" " -f1)
fi

echo "Using monitor: $MONITOR"
echo "Detected Network Interfaces -> Wireless: ${WIRELESS_INT:-None} | Wired: ${WIRED_INT:-None}"

# ==================================
# LAUNCH POLYBAR
# ==================================
# Exports the variables to make them visible to polybar's environment engine
export MONITOR=$MONITOR

polybar main &