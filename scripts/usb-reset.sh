#!/usr/bin/env bash
# Revive the AMD USB controller 0000:06:00.4 after "HC died" (2 external ports + Bluetooth lose power).
# Run:  sudo bash ~/dotfiles/scripts/usb-reset.sh
# Only touches that one controller; keyboard/mouse on the other controller (06:00.3) keep working.

set -u
CTRL="${1:-0000:06:00.4}"
DRV=/sys/bus/pci/drivers/xhci_hcd

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi
[[ -e /sys/bus/pci/devices/$CTRL ]] || { echo "Controller $CTRL not found"; exit 1; }

echo "==> Unbinding $CTRL from xhci_hcd"
[[ -e $DRV/$CTRL ]] && echo -n "$CTRL" >$DRV/unbind
sleep 2
echo "==> Binding $CTRL again"
echo -n "$CTRL" >$DRV/bind 2>/dev/null
sleep 3

if [[ -e $DRV/$CTRL ]] && ls /sys/bus/pci/devices/$CTRL/ | grep -q '^usb'; then
  echo "==> Controller is back"
else
  echo "==> Rebind failed, trying PCI remove + rescan"
  echo 1 >/sys/bus/pci/devices/$CTRL/remove
  sleep 2
  echo 1 >/sys/bus/pci/rescan
  sleep 3
fi

lsusb -t
