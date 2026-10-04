#!/usr/bin/env bash
# Clears the stale "ghost cursor" left on screen after hot-plugging a monitor.
# Listens to Hyprland's event socket and, when a monitor is added, toggles DPMS off/on
# (the same as running: hyprctl dispatch dpms off && sleep 0.5 && hyprctl dispatch dpms on).
# Started from UserConfigs/Startup_Apps.conf.

DELAY=2 # seconds to let the new monitor settle before redrawing

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
[[ -S "$socket" ]] || exit 1

# Only one instance per Hyprland session (the lock is released when this script exits)
exec 9>"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/monitor-hotplug-fix.lock"
flock -n 9 || exit 0

last_fix=0
nc -U "$socket" | while IFS= read -r event; do
  [[ "$event" == monitoradded\>\>* ]] || continue
  now=$(date +%s)
  # several monitoradded events can arrive together; fix once per burst
  ((now - last_fix < DELAY + 2)) && continue
  last_fix=$now
  (
    sleep "$DELAY"
    hyprctl dispatch dpms off >/dev/null
    sleep 0.5
    hyprctl dispatch dpms on >/dev/null
  ) &
done
