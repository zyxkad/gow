#!/bin/sh

source /opt/gow/bash-lib/utils.sh

mkdir -p /run/dbus
dbus-daemon --system --fork --nosyslog
gow_log "*** DBus started ***"
bluetoothd --nodetach &
gow_log "*** Bluez started ***"
NetworkManager
gow_log "*** NetworkManager started ***"

disown
