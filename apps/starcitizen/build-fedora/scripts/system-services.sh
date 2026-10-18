#!/bin/sh

source /opt/gow/bash-lib/utils.sh

# Steam Big Picture First time setup needs a couple of services

mkdir -p /run/dbus
dbus-daemon --system --fork --nosyslog
gow_log "*** DBus started ***"
# On Fedora the bluez package installs bluetoothd at
# /usr/libexec/bluetooth/bluetoothd (not on $PATH). Debian/Ubuntu put it
# under /usr/sbin, which /is/ on $PATH. Resolve via command -v first,
# fall back to the known Fedora location so this survives either base.
BLUETOOTHD="$(command -v bluetoothd || true)"
: "${BLUETOOTHD:=/usr/libexec/bluetooth/bluetoothd}"
"$BLUETOOTHD" --nodetach &
gow_log "*** Bluez started ***"
NetworkManager
gow_log "*** NetworkManager started ***"
# Watchdog will stop steam when selecting Turn off, Suspend or Restart from the Steam power menu
steamos-dbus-watchdog.sh &
gow_log "*** D-Bus Watchdog started ***"

disown
