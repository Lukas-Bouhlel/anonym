#!/usr/bin/env bash
set -euo pipefail

# Safe production cleanup helper.
# Default mode is dry-run: it prints what would be removed.
# Run with APPLY=1 to delete files.

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
BACKUP_ARCHIVES_DIR="${BACKUP_ARCHIVES_DIR:-$HOME_DIR/BACKUP_ARCHIVES}"
BACKUP_SERVER_DIR="${BACKUP_SERVER_DIR:-$HOME_DIR/BACKUP_SERVER_DIR}"
BACKUP_DIR="${BACKUP_DIR:-$HOME_DIR/BACKUP_DIR}"

BACKUP_ARCHIVES_DAYS="${BACKUP_ARCHIVES_DAYS:-14}"
BACKUP_SERVER_DAYS="${BACKUP_SERVER_DAYS:-14}"
BACKUP_DIR_DAYS="${BACKUP_DIR_DAYS:-14}"
KEEP_LATEST="${KEEP_LATEST:-3}"

APPLY="${APPLY:-0}"
CLEAN_CACHE="${CLEAN_CACHE:-1}"
CLEAN_APT="${CLEAN_APT:-1}"
JOURNAL_VACUUM_DAYS="${JOURNAL_VACUUM_DAYS:-7}"
DOCKER_PRUNE="${DOCKER_PRUNE:-0}"

log() {
  printf '%s\n' "$*"
}

run() {
  if [ "$APPLY" = "1" ]; then
    "$@"
  else
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  fi
}

ensure_safe_dir() {
  local dir="$1"
  local label="$2"

  if [ -z "$dir" ] || [ "$dir" = "/" ] || [ "$dir" = "$HOME_DIR" ]; then
    log "Refusing unsafe $label directory: $dir"
    exit 1
  fi

  case "$dir" in
    "$HOME_DIR"/BACKUP*|"$HOME_DIR"/.cache|"$HOME_DIR"/.npm) ;;
    *)
      log "Refusing $label outside expected backup/cache paths: $dir"
      exit 1
      ;;
  esac
}

delete_old_top_level_entries() {
  local dir="$1"
  local days="$2"
  local label="$3"

  [ -d "$dir" ] || {
    log "$label: missing directory, skipping: $dir"
    return
  }
  ensure_safe_dir "$dir" "$label"

  log ""
  log "$label: keeping the $KEEP_LATEST newest entries, removing entries older than $days days in $dir"

  local keep_file
  keep_file="$(mktemp)"
  find "$dir" -mindepth 1 -maxdepth 1 -printf '%T@ %p\n' \
    | sort -rn \
    | head -n "$KEEP_LATEST" \
    | cut -d' ' -f2- > "$keep_file"

  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    if grep -Fxq "$entry" "$keep_file"; then
      log "keep latest: $entry"
      continue
    fi

    run rm -rf -- "$entry"
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -mtime +"$days" -print)

  rm -f "$keep_file"
}

show_disk() {
  log ""
  log "Disk usage:"
  df -h /
  log ""
  du -sh "$BACKUP_ARCHIVES_DIR" "$BACKUP_SERVER_DIR" "$BACKUP_DIR" "$HOME_DIR/.npm" "$HOME_DIR/.cache" 2>/dev/null || true
}

log "Cleanup mode: $([ "$APPLY" = "1" ] && echo apply || echo dry-run)"
show_disk

delete_old_top_level_entries "$BACKUP_ARCHIVES_DIR" "$BACKUP_ARCHIVES_DAYS" "backup archives"
delete_old_top_level_entries "$BACKUP_SERVER_DIR" "$BACKUP_SERVER_DAYS" "server backups"
delete_old_top_level_entries "$BACKUP_DIR" "$BACKUP_DIR_DAYS" "database backups"

if [ "$CLEAN_CACHE" = "1" ]; then
  log ""
  log "User cache cleanup"
  ensure_safe_dir "$HOME_DIR/.cache" "cache"
  run rm -rf -- "$HOME_DIR/.cache"
  run mkdir -p -- "$HOME_DIR/.cache"

  if command -v npm >/dev/null 2>&1; then
    run npm cache clean --force
  fi
fi

if [ "$CLEAN_APT" = "1" ] && command -v apt-get >/dev/null 2>&1; then
  log ""
  log "APT cleanup"
  run sudo apt-get clean
  run sudo apt-get autoremove -y
fi

if command -v journalctl >/dev/null 2>&1; then
  log ""
  log "Journal cleanup"
  run sudo journalctl --vacuum-time="${JOURNAL_VACUUM_DAYS}d"
fi

if [ "$DOCKER_PRUNE" = "1" ] && command -v docker >/dev/null 2>&1; then
  log ""
  log "Docker cleanup"
  run docker system prune -af
fi

show_disk

if [ "$APPLY" != "1" ]; then
  log ""
  log "Dry-run only. Re-run with APPLY=1 after reviewing the planned deletions."
fi
