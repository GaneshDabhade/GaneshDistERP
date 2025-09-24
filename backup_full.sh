#!/usr/bin/env bash
# backup_full.sh
# Purpose: Export fixtures, package custom apps, run bench backup (DB + files),
# and copy all artifacts to host folder ($HOST_BACKUP_DIR).
#
# Usage:
#   ./backup_full.sh
#
# EDIT THESE VARIABLES as needed:
COMPOSE_FILE="pwd.yml"
SITE="frontend"
BACKEND="backend"
BENCH_PATH="/home/frappe/frappe-bench"
HOST_BACKUP_DIR="$HOME/erp-backups"

set -euo pipefail
IFS=$'\n\t'

TIMESTAMP=$(date +%F_%H%M%S)
OUT_DIR="${HOST_BACKUP_DIR}/${SITE}-${TIMESTAMP}"

mkdir -p "$OUT_DIR"
echo "Backup output folder: $OUT_DIR"

# Obtain backend container id
CONTAINER=$(docker compose -f "$COMPOSE_FILE" ps -q "$BACKEND" 2>/dev/null || true)
if [ -z "$CONTAINER" ]; then
  echo "ERROR: Could not find backend container with 'docker compose -f $COMPOSE_FILE ps -q $BACKEND'."
  echo "Run 'docker compose -f $COMPOSE_FILE up -d' and retry, or set CONTAINER manually."
  docker compose -f "$COMPOSE_FILE" ps
  exit 1
fi
echo "Backend container: $CONTAINER"

# 1) Export fixtures (UI changes -> JSON inside apps/)
echo "Exporting fixtures (if hooks configured)..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE export-fixtures || true"

# 2) Discover apps and package custom ones (skip frappe & erpnext)
echo "Packaging custom apps..."
APPS_RAW=$(docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "ls -1 $BENCH_PATH/apps" | tr -d '\r' || true)
CORE_EXCLUDE="frappe erpnext"
for a in $APPS_RAW; do
  skip=false
  for ex in $CORE_EXCLUDE; do
    if [ "$a" = "$ex" ]; then skip=true; break; fi
  done
  if [ "$skip" = false ]; then
    echo " - Packaging app: $a"
    docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && tar czf /tmp/${a}.tar.gz apps/${a}"
    docker cp "${CONTAINER}:/tmp/${a}.tar.gz" "$OUT_DIR/${a}.tar.gz"
    docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "rm -f /tmp/${a}.tar.gz || true"
  fi
done

# 3) Record pip freeze (optional)
echo "Recording pip freeze..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "pip freeze > /tmp/pip-freeze-${TIMESTAMP}.txt || true"
docker cp "${CONTAINER}:/tmp/pip-freeze-${TIMESTAMP}.txt" "$OUT_DIR/pip-freeze-${TIMESTAMP}.txt" || true
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "rm -f /tmp/pip-freeze-${TIMESTAMP}.txt || true"

# 4) Run canonical Frappe backup (DB + files)
echo "Running bench backup (DB + files)..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE backup --with-files"

# 5) Copy produced backups from container to host
echo "Copying produced site backups to host folder..."
docker cp "${CONTAINER}:${BENCH_PATH}/sites/${SITE}/private/backups/." "$OUT_DIR/"

# 6) Generate checksums on host
echo "Generating checksums..."
(cd "$OUT_DIR" && sha256sum * > sha256sums.txt || true)

echo ""
echo "Backup completed successfully."
echo "All artifacts are in: $OUT_DIR"
echo "IMPORTANT: Move $OUT_DIR to secure / offsite storage (S3 / restic / external disk)."
