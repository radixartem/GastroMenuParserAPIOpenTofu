#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/opt/gastro-api
ENV_FILE="$APP_DIR/.env"
BACKUP_DIR=/var/backups/gastro-api
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
FILE="$BACKUP_DIR/postgres_${TIMESTAMP}.dump"

[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
export AWS_ACCESS_KEY_ID="$OBJ_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$OBJ_SECRET_KEY"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

cleanup() { rm -f "$FILE"; }
trap cleanup ERR INT TERM

docker compose --env-file "$ENV_FILE" -f "$APP_DIR/docker-compose.yml" exec -T postgres   pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$FILE"

test -s "$FILE"

aws s3 cp "$FILE" "s3://${OBJ_BUCKET}/postgres/$(basename "$FILE")"   --endpoint-url "$OBJ_ENDPOINT"   --region "${OBJ_REGION:-fsn1}"

find "$BACKUP_DIR" -type f -name 'postgres_*.dump' -mtime +1 -delete
aws s3 ls "s3://${OBJ_BUCKET}/postgres/" --endpoint-url "$OBJ_ENDPOINT" --region "${OBJ_REGION:-fsn1}"   | awk '{print $4}' | while read -r object; do
      [[ -z "$object" ]] && continue
      if [[ "$object" =~ postgres_([0-9]{8}T[0-9]{6}Z)\.dump$ ]]; then
        ts="${BASH_REMATCH[1]}"
        epoch=$(date -d "$ts" +%s 2>/dev/null || echo 0)
        cutoff=$(date -d "-${BACKUP_RETENTION_DAYS:-14} days" +%s)
        if (( epoch > 0 && epoch < cutoff )); then
          aws s3 rm "s3://${OBJ_BUCKET}/postgres/$object" --endpoint-url "$OBJ_ENDPOINT" --region "${OBJ_REGION:-fsn1}"
        fi
      fi
    done

rm -f "$FILE"
trap - ERR INT TERM
echo "Backup completed: $TIMESTAMP"
