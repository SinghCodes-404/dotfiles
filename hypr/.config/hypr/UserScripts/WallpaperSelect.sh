#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
SUGGEST="$HOME/.config/hypr/UserScripts/WallpaperSuggest.sh"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# awww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if package bc exists
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Kill existing wallpaper daemons for video
kill_wallpaper_for_video() {
  awww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Kill existing wallpaper daemons for image
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Retrieve wallpapers (both images & videos)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

if ((${#PICS[@]} == 0)); then
  notify-send -i "$iDIR/error.png" "No wallpapers" "Nothing found in $wallDIR"
  exit 1
fi

# ". random" only picks static images
STATIC_PICS=()
for pic_path in "${PICS[@]}"; do
  [[ "$pic_path" =~ \.(jpg|jpeg|png|bmp|tiff|webp)$ || "$pic_path" =~ \.(JPG|JPEG|PNG|BMP|TIFF|WEBP)$ ]] && STATIC_PICS+=("$pic_path")
done
((${#STATIC_PICS[@]} == 0)) && STATIC_PICS=("${PICS[@]}")
RANDOM_PIC="${STATIC_PICS[$((RANDOM % ${#STATIC_PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi command (-format i returns the row index, so each row maps to its exact path)
rofi_command="rofi -i -dmenu -format i -config $rofi_theme -theme-str $rofi_override"

# Menu rows: ". random", today's suggestions (see WallpaperSuggest.sh), then every wallpaper sorted.
# ENTRIES[i] is the file for row i and LABELS[i] is the text shown.
ENTRIES=("$RANDOM_PIC")
LABELS=("$RANDOM_PIC_NAME")
declare -A SUGGESTED=()
while IFS=$'\t' read -r tag pic_path; do
  [[ -n "$pic_path" && -f "$pic_path" ]] || continue
  SUGGESTED["$pic_path"]=1
  ENTRIES+=("$pic_path")
  if [[ "$tag" == "new" ]]; then
    LABELS+=("[new] ${pic_path##*/}")
  else
    LABELS+=("${pic_path##*/}")
  fi
done < <("$SUGGEST" suggest "$wallDIR")

mapfile -t sorted_options < <(printf '%s\n' "${PICS[@]}" | sort)
for pic_path in "${sorted_options[@]}"; do
  [[ -n "${SUGGESTED[$pic_path]}" ]] && continue
  ENTRIES+=("$pic_path")
  LABELS+=("${pic_path##*/}")
done

# Print rofi rows (with preview icons) in the same order as ENTRIES
menu() {
  local i pic_path pic_name
  for i in "${!ENTRIES[@]}"; do
    pic_path="${ENTRIES[$i]}"
    pic_name=${pic_path##*/}
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "${LABELS[$i]}" "$cache_gif_image"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
      fi
      printf "%s\x00icon\x1f%s\n" "${LABELS[$i]}" "$cache_preview_image"
    else
      printf "%s\x00icon\x1f%s\n" "${LABELS[$i]}" "$pic_path"
    fi
  done
}

modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"

  # Check if it's a live wallpaper (video)
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # For video wallpapers:
    sed -i '/^\s*exec-once\s*=\s*awww-daemon\s*--format\s*xrgb\s*$/s/^/\#/' "$startup_config"
    sed -i '/^\s*#\s*exec-once\s*=\s*mpvpaper\s*.*$/s/^#\s*//;' "$startup_config"

    # Update the livewallpaper variable with the selected video path (using $HOME)
    selected_file="${selected_file/#$HOME/\$HOME}" # Replace /home/user with $HOME
    sed -i "s|^\$livewallpaper=.*|\$livewallpaper=\"$selected_file\"|" "$startup_config"

    echo "Configured for live wallpaper (video)."
  else
    # For image wallpapers:
    sed -i '/^\s*#\s*exec-once\s*=\s*awww-daemon\s*--format\s*xrgb\s*$/s/^\s*#\s*//;' "$startup_config"

    sed -i '/^\s*exec-once\s*=\s*mpvpaper\s*.*$/s/^/\#/' "$startup_config"

    echo "Configured for static wallpaper (image)."
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"

  kill_wallpaper_for_image

  if ! pgrep -x "awww-daemon" >/dev/null; then
    echo "Starting awww-daemon..."
    awww-daemon --format xrgb &
  fi

  for mon in $(hyprctl monitors | grep "^Monitor" | awk '{print $2}'); do awww img -o "$mon" "$image_path" $SWWW_PARAMS; done

  # Run additional scripts (pass the image path to avoid cache race conditions)
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  sleep 1

}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Apply video wallpaper using mpvpaper
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

# Main function
main() {
  choice=$(menu | $rofi_command)

  # rofi prints the selected row index; nothing (or -1 for typed text) means no selection
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice >= ${#ENTRIES[@]})); then
    echo "No choice selected. Exiting."
    exit 0
  fi

  selected_file="${ENTRIES[$choice]}"

  if [[ ! -f "$selected_file" ]]; then
    echo "File not found: $selected_file"
    exit 1
  fi

  # Remember the pick so suggestions learn which folders you like
  "$SUGGEST" log "$selected_file" select

  # Modify the Startup_Apps.conf file based on wallpaper type
  modify_startup_config "$selected_file"

  # **CHECK FIRST** if it's a video or an image **before calling any function**
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main
