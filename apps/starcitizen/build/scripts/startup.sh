#!/bin/bash
set -e

source /opt/gow/bash-lib/utils.sh

gow_log "StarCitizen startup.sh"

mkdir -p "$HOME/"

# Scaling support
export STEAM_GAMESCOPE_FANCY_SCALING_SUPPORT=1

if ! [ -f /home/retro/Games/star-citizen/.lughelper ]; then
  /usr/local/libexec/lug-helper/lug-helper.sh -g -i </dev/null 2>&1
fi

if [ -n "$RUN_GAMESCOPE" ]; then
  GAMESCOPE_BIN="$(command -v gamescope)"

  # Setup socket for gamescope statistics shown in mango and steam
  # Create run directory file for startup and stats sockets
  tmpdir="$([[ -n ${XDG_RUNTIME_DIR+x} ]] && mktemp -p "$XDG_RUNTIME_DIR" -d -t gamescope.XXXXXXX)"
  socket="${tmpdir:+$tmpdir/startup.socket}"
  stats="${tmpdir:+$tmpdir/stats.pipe}"
  # Fail early if we don't have a proper runtime directory setup
  if [[ -z $tmpdir || -z ${XDG_RUNTIME_DIR+x} ]]; then
	echo >&2 "!! Failed to find run directory in which to create stats session sockets (is \$XDG_RUNTIME_DIR set?)"
	exit 0
  fi

  export GAMESCOPE_STATS="$stats"
  mkfifo -- "$stats"
  mkfifo -- "$socket"

  # Attempt to claim global session if we're the first one running (e.g. /run/1000/gamescope)
  linkname="gamescope-stats"
  #   shellcheck disable=SC2031 # (broken warning)
  sessionlink="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/}${linkname}" # Account for XDG_RUNTIME_DIR="" (notfragileatall)
  lockfile="$sessionlink".lck
  exec 9>"$lockfile" # Keep as an fd such that the lock lasts as long as the session if it is taken
  if flock -n 9 && rm -f "$sessionlink" && ln -sf "$tmpdir" "$sessionlink"; then
	# Took the lock.  Don't blow up if those commands fail, though.
	echo >&2 "Claimed global gamescope stats session at \"$sessionlink\""
  else
	echo >&2 "!! Failed to claim global gamescope stats session"
  fi

  GAMESCOPE_WIDTH=${GAMESCOPE_WIDTH:-1920}
  GAMESCOPE_HEIGHT=${GAMESCOPE_HEIGHT:-1080}
  GAMESCOPE_REFRESH=${GAMESCOPE_REFRESH:-60}
  GAMESCOPE_MODE=${GAMESCOPE_MODE:-"-b"}

  # shellcheck disable=SC2086
  # -w/-h pin the internal (XWayland) mode list to the output resolution so
  # games don't pick a standard preset (e.g. 1440p) that gamescope then
  # letterboxes into a non-16:9 output.
  "${GAMESCOPE_BIN}" -e ${GAMESCOPE_MODE} -R $socket -T $stats -W "${GAMESCOPE_WIDTH}" -H "${GAMESCOPE_HEIGHT}" -w "${GAMESCOPE_WIDTH}" -h "${GAMESCOPE_HEIGHT}" -r "${GAMESCOPE_REFRESH}" &

  # Read the variables we need from the socket
  if read -r -t 3 response_x_display response_wl_display <> "$socket"; then
	export DISPLAY="$response_x_display"
	export GAMESCOPE_WAYLAND_DISPLAY="$response_wl_display"
	unset WAYLAND_DISPLAY
	# We're done!
  else
	echo "gamescope failed"
	exit 1
  fi

  # Launch mango.
  # NOTE: on the Ubuntu base-app, `mangoapp` is not installed (upstream
  # MangoHud's release tarball ships only mangohud + mangoplot). On the
  # Fedora base-app, `mangoapp` is part of the mangohud RPM. Bash will
  # print "command not found" on Ubuntu and carry on; the gamescope stats
  # overlay is silently disabled there. See images/base-app/build/Dockerfile
  # (_INSTALL_MANGO block) for the full context.
  mangoapp &

  # Start Steam
  # shellcheck disable=SC2086
  dbus-run-session -- /home/retro/Games/star-citizen/sc-launch.sh

elif [ -n "$RUN_SWAY" ]; then
  # Enable MangoHud for all vulkan (including Proton) games
  # unless the user has explicitly disabled it in config.
  export MANGOHUD=${MANGOHUD:-1}

  # Start Steam
  source /opt/gow/launch-comp.sh
  launcher /home/retro/Games/star-citizen/sc-launch.sh
else
  # shellcheck disable=SC2086
  exec /home/retro/Games/star-citizen/sc-launch.sh
fi
