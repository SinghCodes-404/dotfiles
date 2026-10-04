#!/usr/bin/env bash
# Daily wallpaper suggestions that learn your taste by folder (used by WallpaperSelect.sh, SUPER W)
#
# Usage:
#   WallpaperSuggest.sh suggest <wallpaper_dir>     print today's suggestions as "tag<TAB>path" (tag: fav|new|explore)
#   WallpaperSuggest.sh log <path> [select|random]  record an applied wallpaper
#
# How it works:
#   - Taste is scored per folder NAME (walls-main/anime and new-pack/anime share the "anime" score).
#     Images directly in the wallpaper dir share the "(root)" key.
#   - Each wallpaper you pick from the menu adds 0.5^(age/HALF_LIFE_DAYS) to its folder; every folder
#     starts at BASE_SCORE so unused folders still show up. "random" applies don't count as taste.
#   - Files first seen by the menu within NEW_DAYS get NEW_SLOTS reserved tiles.
#   - Wallpapers applied within RECENT_DAYS are not suggested.
#   - The set is generated once per day (seeded by the date) and cached, so it stays stable all day.
#   - Only static images are suggested (no gifs or videos).

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
HISTORY="$STATE_DIR/history" # epoch<TAB>source<TAB>path
INDEX="$STATE_DIR/index"     # first_seen_epoch<TAB>path   (0 = existed before this system)
DAILY="$STATE_DIR/daily"     # line 1: YYYYMMDD, then tag<TAB>path

TOTAL_SLOTS=11
NEW_SLOTS=2
EXPLORE_SLOTS=2
NEW_DAYS=7
RECENT_DAYS=14
HALF_LIFE_DAYS=30
BASE_SCORE=0.5

mkdir -p "$STATE_DIR"
touch "$HISTORY"

list_images() {
  find -L "$1" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
    -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \) -print | sort
}

# Record when each image was first seen. On the very first run everything is marked 0 (old),
# so only images added afterwards count as new arrivals.
update_index() {
  local images="$1" now
  now=$(date +%s)
  if [[ ! -s "$INDEX" ]]; then
    awk '{ print 0 "\t" $0 }' "$images" >"$INDEX"
  else
    awk -F'\t' -v idx="$INDEX" -v now="$now" '
      FILENAME == idx { seen[$2] = 1; next }
      !($0 in seen)   { print now "\t" $0 }
    ' "$INDEX" "$images" >>"$INDEX"
  fi
}

# Reuse today's cached set if it is from today and every file still exists
print_cached_daily() {
  [[ -f "$DAILY" ]] || return 1
  [[ "$(head -n1 "$DAILY")" == "$(date +%Y%m%d)" ]] || return 1
  local tag path
  while IFS=$'\t' read -r tag path; do
    [[ -f "$path" ]] || return 1
  done < <(tail -n +2 "$DAILY")
  tail -n +2 "$DAILY"
}

generate_daily() {
  local wall_dir="${1%/}" images="$2"
  awk -F'\t' \
    -v hist="$HISTORY" -v idx="$INDEX" -v root="$wall_dir" \
    -v now="$(date +%s)" -v seed="$(date +%Y%m%d)" \
    -v total="$TOTAL_SLOTS" -v new_slots="$NEW_SLOTS" -v explore_slots="$EXPLORE_SLOTS" \
    -v new_days="$NEW_DAYS" -v recent_days="$RECENT_DAYS" \
    -v half_life="$HALF_LIFE_DAYS" -v base="$BASE_SCORE" '
    function key(p,   d) {
      d = p
      sub(/\/[^\/]*$/, "", d)
      if (d == root) return "(root)"
      sub(/^.*\//, "", d)
      return d
    }
    # pick a folder with remaining files; mode "fav" weights by score, "explore" by 1/score
    function pick_folder(mode,   i, k, w, sum, r) {
      sum = 0
      for (i = 1; i <= nf; i++) {
        k = folders[i]
        if (avail[k] <= 0) continue
        sum += (mode == "fav") ? score[k] : 1 / score[k]
      }
      if (sum <= 0) return ""
      r = rand() * sum
      for (i = 1; i <= nf; i++) {
        k = folders[i]
        if (avail[k] <= 0) continue
        w = (mode == "fav") ? score[k] : 1 / score[k]
        if (r < w) return k
        r -= w
      }
      return ""
    }
    # pick a random unpicked file from folder k
    function pick_from(k,   start, i, j, p) {
      start = int(rand() * fcount[k])
      for (i = 0; i < fcount[k]; i++) {
        j = (start + i) % fcount[k] + 1
        p = fpath[k, j]
        if (!(p in picked)) return p
      }
      return ""
    }
    function take(p, tag,   k) {
      picked[p] = 1
      k = key(p)
      avail[k]--
      out_n++
      out[out_n] = tag "\t" p
    }
    BEGIN { srand(seed) }
    FILENAME == hist {
      age = (now - $1) / 86400
      if ($2 != "random") score[key($3)] += 0.5 ^ (age / half_life)
      if (age < recent_days) recent[$3] = 1
      next
    }
    FILENAME == idx { first[$2] = $1; next }
    {
      p = $0
      if (p in recent) next
      k = key(p)
      if (!(k in fcount)) { nf++; folders[nf] = k }
      fcount[k]++
      fpath[k, fcount[k]] = p
      avail[k]++
      if (first[p] > 0 && now - first[p] < new_days * 86400) { nn++; newp[nn] = p }
    }
    END {
      for (i = 1; i <= nf; i++) score[folders[i]] += base

      # new arrivals: shuffle, take up to new_slots
      for (i = nn; i > 1; i--) { j = int(rand() * i) + 1; t = newp[i]; newp[i] = newp[j]; newp[j] = t }
      got = 0
      for (i = 1; i <= nn && got < new_slots; i++) { take(newp[i], "new"); got++ }

      fav_slots = total - got - explore_slots
      for (n = 0; n < fav_slots; n++) {
        k = pick_folder("fav"); if (k == "") break
        p = pick_from(k); if (p == "") break
        take(p, "fav")
      }
      for (n = 0; n < explore_slots; n++) {
        k = pick_folder("explore"); if (k == "") break
        p = pick_from(k); if (p == "") break
        take(p, "explore")
      }
      # top up if any pool ran short
      while (out_n < total) {
        k = pick_folder("explore"); if (k == "") break
        p = pick_from(k); if (p == "") break
        take(p, "fav")
      }

      # favourites first, then new arrivals, then exploration
      split("fav new explore", order, " ")
      for (o = 1; o <= 3; o++)
        for (i = 1; i <= out_n; i++)
          if (index(out[i], order[o] "\t") == 1) print out[i]
    }
  ' "$HISTORY" "$INDEX" "$images"
}

cmd_suggest() {
  local wall_dir="$1" images
  [[ -d "$wall_dir" ]] || { echo "Usage: $0 suggest <wallpaper_dir>" >&2; return 1; }

  images=$(mktemp)
  trap 'rm -f "$images"' RETURN
  list_images "$wall_dir" >"$images"
  update_index "$images"

  print_cached_daily && return 0

  local result
  result=$(generate_daily "$wall_dir" "$images")
  { date +%Y%m%d; [[ -n "$result" ]] && printf '%s\n' "$result"; } >"$DAILY"
  [[ -n "$result" ]] && printf '%s\n' "$result"
  return 0
}

cmd_log() {
  local path="$1" source="${2:-select}"
  [[ -n "$path" ]] || { echo "Usage: $0 log <path> [select|random]" >&2; return 1; }
  printf '%s\t%s\t%s\n' "$(date +%s)" "$source" "$path" >>"$HISTORY"
}

case "$1" in
suggest) cmd_suggest "$2" ;;
log) cmd_log "$2" "$3" ;;
*)
  echo "Usage: $0 {suggest <wallpaper_dir>|log <path> [select|random]}" >&2
  exit 1
  ;;
esac
