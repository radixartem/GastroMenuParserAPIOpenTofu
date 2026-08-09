#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/opt/gastro-api
ENV_FILE="$APP_DIR/.env"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/postgres_YYYYMMDDTHHMMSSZ.dump" >&2
  exit 1
fi

BACKUP_FILE=$1
[[ -f "$BACKUP_FILE" ]] || { echo "Backup file not found: $BACKUP_FILE" >&2; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

echo "WARNING: this replaces the application database contents."
read -r -p "Type RESTORE to continue: " confirmation
[[ "$confirmation" == "RESTORE" ]] || { echo "Cancelled."; exit 1; }

docker compose --env-file "$ENV_FILE" -f "$APP_DIR/docker-compose.yml" stop api

docker compose --env-file "$ENV_FILE" -f "$APP_DIR/docker-compose.yml" exec -T postgres   pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner < "$BACKUP_FILE"

docker compose --env-file "$ENV_FILE" -f "$APP_DIR/docker-compose.yml" start api

echo "Restore completed."
