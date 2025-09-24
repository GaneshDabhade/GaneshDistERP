#!/usr/bin/env bash
# restore_full.sh
# Usage:
#   ./restore_full.sh /path/to/backup-folder
# If no argument provided, the script will pick the latest folder under $HOST_BACKUP_DIR matching $SITE-*
#
# WARNING: This will run bench restore --force which will overwrite the site's DB. Use with caution.
#
COMPOSE_FILE="pwd.yml"
SITE="frontend"
BACKEND="backend"
BENCH_PATH="/home/frappe/frappe-bench"
HOST_BACKUP_DIR="$HOME/erp-backups"

set -euo pipefail
IFS=$'\n\t'

# choose restore folder (arg1 or latest)
if [ $# -ge 1 ] && [ -d "$1" ]; then
  RESTORE_DIR="$1"
else
  # find most recent matching folder
  RESTORE_DIR=$(ls -1dt "${HOST_BACKUP_DIR}/${SITE}-"* 2>/dev/null | head -n 1 || true)
fi

if [ -z "$RESTORE_DIR" ] || [ ! -d "$RESTORE_DIR" ]; then
  echo "ERROR: No restore folder found. Provide the path to a backup folder as first argument or place backups under $HOST_BACKUP_DIR"
  ls -1 "$HOST_BACKUP_DIR" || true
  exit 1
fi

echo "Using restore folder: $RESTORE_DIR"

# find backend container
CONTAINER=$(docker compose -f "$COMPOSE_FILE" ps -q "$BACKEND" 2>/dev/null || true)
if [ -z "$CONTAINER" ]; then
  echo "ERROR: Could not determine backend container. Ensure 'docker compose -f $COMPOSE_FILE up -d' has been run."
  docker compose -f "$COMPOSE_FILE" ps
  exit 1
fi
echo "Backend container: $CONTAINER"

# 0) Stop workers/scheduler/websocket to avoid jobs while DB replaced
echo "Stopping background workers and scheduler..."
docker compose -f "$COMPOSE_FILE" stop queue-short queue-long scheduler websocket || true

# 1) Copy app tarballs found in restore folder into container and extract
echo "Copying and extracting app tarballs (if any)..."
shopt -s nullglob
for tarball in "$RESTORE_DIR"/*.tar.gz; do
  bn=$(basename "$tarball")
  # skip site files and DB dumps (files-*.tar.gz and *database*.sql.gz)
  if [[ "$bn" =~ ^files-.*\.tar\.gz$ ]] || [[ "$bn" =~ database.*\.sql\.gz$ ]] || [[ "$bn" =~ frontend-database.*\.sql\.gz$ ]]; then
    echo "Skipping archive (files/db): $bn"
    continue
  fi
  echo " - copying $bn -> container:/tmp/"
  docker cp "$tarball" "${CONTAINER}:/tmp/$bn"
  echo " - extracting $bn inside container to $BENCH_PATH"
  docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && tar xzf /tmp/$bn -C . && chown -R frappe:frappe apps || true"
  docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "rm -f /tmp/$bn || true"
done
shopt -u nullglob

# 2) Install python deps per app (if requirements.txt present) and bench build
echo "Installing app dependencies (if present) and building assets..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && for app in apps/*; do if [ -d \"\$app\" ] && [ -f \"\$app/requirements.txt\" ]; then echo Installing for \$app; pip install -r \"\$app/requirements.txt\" || true; fi; done"
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench build || true"

# 3) Optionally ensure apps are installed on the site (safe)
echo "Attempting app install (will skip if already installed)..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && for app in apps/*; do if [ -d \"\$app\" ]; then appn=\$(basename \$app); echo \"Ensuring app \$appn is installed...\"; bench --site $SITE install-app \$appn || true; fi; done"

# 4) Copy DB dump and files archives into container backups folder
echo "Copying DB dump and files archives into container backups folder..."
# copy DB dump (pick first matching frontend-database or *database*.sql.gz)
DB_ARCHIVE=""
for f in "$RESTORE_DIR"/*database*.sql.gz "$RESTORE_DIR"/frontend-database*.sql.gz; do
  [ -f "$f" ] && DB_ARCHIVE="$f" && break
done

if [ -z "$DB_ARCHIVE" ]; then
  echo "ERROR: No DB archive (*.sql.gz) found in $RESTORE_DIR"
  exit 1
fi
echo "DB archive found: $(basename "$DB_ARCHIVE")"
docker cp "$DB_ARCHIVE" "${CONTAINER}:${BENCH_PATH}/sites/${SITE}/private/backups/"

# copy files archives (files-*.tar.gz)
FILES_COPIED=0
for f in "$RESTORE_DIR"/files-*.tar.gz; do
  [ -f "$f" ] || continue
  echo "Copying files archive: $(basename "$f")"
  docker cp "$f" "${CONTAINER}:${BENCH_PATH}/sites/${SITE}/private/backups/"
  FILES_COPIED=$((FILES_COPIED+1))
done
echo "Files archives copied: $FILES_COPIED"

# 5) Put site into maintenance mode
echo "Setting maintenance mode ON for site $SITE..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE set-maintenance-mode on || true"

# 6) Run canonical restore (DB import) - replace with exact filename
DB_BN=$(basename "$DB_ARCHIVE")
echo "Running bench --site $SITE --force restore for $DB_BN ..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE --force restore sites/$SITE/private/backups/$DB_BN"

# 7) Extract uploaded files into site (if any)
echo "Extracting files archives into sites/$SITE ..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH/sites/$SITE && for f in private/backups/files-*.tar.gz; do [ -f \"\$f\" ] && tar -xzvf \"\$f\" -C . || true; done"

# 8) Fix ownership, migrate, clear-cache and build
echo "Fixing ownership and running migrate/clear-cache/build..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "chown -R frappe:frappe $BENCH_PATH/sites || true"
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE migrate || true"
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE clear-cache || true"
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench build || true"

# 9) Start workers and take site out of maintenance
echo "Starting background workers and scheduler..."
docker compose -f "$COMPOSE_FILE" start queue-short queue-long scheduler websocket || true
docker compose -f "$COMPOSE_FILE" restart backend frontend || true

echo "Disabling maintenance mode..."
docker compose -f "$COMPOSE_FILE" exec "$BACKEND" bash -lc "cd $BENCH_PATH && bench --site $SITE set-maintenance-mode off || true"

echo ""
echo "Restore completed. Verify site in browser and inspect logs:"
echo "  docker compose -f $COMPOSE_FILE logs backend --tail=200"
