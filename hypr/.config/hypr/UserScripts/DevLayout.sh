#!/bin/bash
# Launch dev layout: terminal on ws1, browser on ws2
# Window rules automatically place apps — this script just opens them.

hyprctl dispatch workspace 1
sleep 0.3
alacritty &

sleep 0.5
hyprctl dispatch workspace 2
sleep 0.3
xdg-open "about:blank" &

sleep 0.5
hyprctl dispatch workspace 1
