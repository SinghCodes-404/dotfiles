#!/usr/bin/env bash
# Prevent full-system freezes when RAM runs out.
#   1. zram   - compressed swap in RAM (no disk used)
#   2. earlyoom - kills the biggest browser tab BEFORE the system locks up
#   3. sysctl tuning recommended for zram, and zswap disabled (it shouldn't run alongside zram)
#
# Run:    sudo bash ~/dotfiles/scripts/setup-memory-protection.sh
# Undo:   sudo bash ~/dotfiles/scripts/setup-memory-protection.sh --undo

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0 ${1:-}"
  exit 1
fi

ZRAM_CONF=/etc/systemd/zram-generator.conf
SYSCTL_CONF=/etc/sysctl.d/99-vm-zram-parameters.conf
ZSWAP_CONF=/etc/tmpfiles.d/disable-zswap.conf
EARLYOOM_CONF=/etc/default/earlyoom

if [[ "${1:-}" == "--undo" ]]; then
  echo "==> Undoing memory protection"
  systemctl disable --now earlyoom.service 2>/dev/null || true
  swapoff /dev/zram0 2>/dev/null || true
  systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
  rm -f "$ZRAM_CONF" "$SYSCTL_CONF" "$ZSWAP_CONF" "$EARLYOOM_CONF"
  systemctl daemon-reload
  echo "Config files removed. Packages left installed (remove with: pacman -Rns earlyoom zram-generator)."
  echo "Reboot to restore all kernel defaults."
  exit 0
fi

echo "==> Installing zram-generator and earlyoom"
pacman -S --needed --noconfirm zram-generator earlyoom

echo "==> Writing $ZRAM_CONF"
cat >"$ZRAM_CONF" <<'EOF'
# Compressed swap in RAM: half of RAM, capped at 8 GB, zstd compression
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF

echo "==> Writing $SYSCTL_CONF"
cat >"$SYSCTL_CONF" <<'EOF'
# Recommended for zram (ArchWiki: Zram#Optimizing swap on zram)
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

echo "==> Writing $ZSWAP_CONF"
cat >"$ZSWAP_CONF" <<'EOF'
# zswap is on by default in this kernel; disable it because zram is used instead
w- /sys/module/zswap/parameters/enabled - - - - 0
EOF

echo "==> Writing $EARLYOOM_CONF"
# Act when available RAM <= 5% AND free swap <= 10%.
# Prefer killing browser/electron renderers; never kill the desktop, audio or terminals.
# (No spaces/quotes in the regexes: systemd splits $EARLYOOM_ARGS on whitespace.)
cat >"$EARLYOOM_CONF" <<'EOF'
EARLYOOM_ARGS="-r 3600 -n -m 5 -s 10 --prefer (^|/)(Isolated.Web.Co|Web.Content|firefox|chrome|chromium|electron|code|cursor)$ --avoid (^|/)(Hyprland|Xwayland|waybar|swaync|ags|hypridle|hyprlock|pipewire|pipewire-pulse|wireplumber|systemd|systemd-.*|gdm|gdm-.*|dbus-.*|alacritty|kitty|sshd)$"
EOF

echo "==> Activating"
systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service
sysctl -q -p "$SYSCTL_CONF"
echo 0 >/sys/module/zswap/parameters/enabled
systemctl enable --now earlyoom.service

echo
echo "==> Verification"
swapon --show
echo "zswap enabled: $(cat /sys/module/zswap/parameters/enabled)"
echo "swappiness:    $(cat /proc/sys/vm/swappiness)"
systemctl --no-pager --lines=3 status earlyoom.service | sed -n '1,3p;/mem avail/p' || true
journalctl -u earlyoom -b --no-pager -n 5 | tail -n 5
echo
echo "Done. Everything is active now and persists across reboots."
