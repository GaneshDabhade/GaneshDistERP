README.md — ERPNext Backup & Restore (Frappe-Recommended)

Commit-ready README for backing up and restoring an ERPNext site deployed via Docker Compose using the Frappe-recommended approach.
This file is safe to add to your repository provided you do not add actual DB dumps, site_config.json with secrets, or sites/*/private files into the repo.

Summary

This repository contains your Docker Compose (pwd.yml) and the instructions/scripts to:

bring up ERPNext containers,

take the canonical Frappe backup (database + files) using bench --site <site> backup --with-files,

back up custom app source (and fixtures),

copy backup artifacts off the container to the host and offsite,

restore a full site on a fresh host (order-aware and safe),

run migrations, build assets, and verify the restore.

Important: The canonical bench backup is the supported single source-of-truth for site data. Custom app source code, fixtures and dependency lists must be stored in Git separately.

⚠️ Before you commit

Do not commit any database dumps (*.sql, *.sql.gz) or sites/*/private/* content to a public repository.

Do not commit site_config.json or common_site_config.json with real credentials. Commit redacted templates only (e.g. site_config.template.json).

Keep app source code (custom apps) in Git — it is safe to commit (remove any secrets first).

Variables — edit these before running commands
# Edit these values to match your environment
COMPOSE_FILE="pwd.yml"             # Compose file in this repo
SITE="frontend"                    # ERPNext site name
BACKEND="backend"                  # backend service name in compose
BENCH_PATH="/home/frappe/frappe-bench"  # bench path inside container
HOST_BACKUP_DIR="$HOME/erp-backups"     # where backups will be copied on the host

1. Bring up services

From the directory containing pwd.yml:

# Optional: pull latest images specified in compose
docker compose -f $COMPOSE_FILE pull

# Start containers in detached mode
docker compose -f $COMPOSE_FILE up -d

# Show container status
docker compose -f $COMPOSE_FILE ps

# Follow backend logs (helpful when create-site runs)
docker compose -f $COMPOSE_FILE logs -f $BACKEND

# If you want to watch create-site service logs:
docker compose -f $COMPOSE_FILE logs -f create-site


Note: create-site may auto-create the frontend site using the bench new-site command. That is fine — you can restore over it later using --force.

2. Canonical Frappe backup (DB + files)

This is the recommended, supported Frappe backup. It creates a logical SQL dump and file archives.

# Run canonical backup inside the backend container
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && bench --site $SITE backup --with-files"

# Verify produced backups
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "ls -lh $BENCH_PATH/sites/$SITE/private/backups"


Typical backup artifacts (in sites/<site>/private/backups):

frontend-database-YYYY-MM-DD-HHMMSS.sql.gz — logical DB dump

files-YYYY-MM-DD-HHMMSS.tar.gz — uploaded files / attachments

(sometimes) public-YYYY-...tar.gz

Add checksum for integrity:

docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "sha256sum $BENCH_PATH/sites/$SITE/private/backups/* > $BENCH_PATH/sites/$SITE/private/backups/sha256sums.txt"
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cat $BENCH_PATH/sites/$SITE/private/backups/sha256sums.txt"

3. Custom apps — backup strategy (source control + fixtures)

bench backup does NOT include custom app source code. For each custom app you must preserve:

Full app directory: apps/<your_app>/ — store in Git (preferred).

hooks.py and config/fixtures.json (fixtures exported via bench --site <site> export-fixtures).

requirements.txt and any frontend build files (e.g. package.json).

patches, patches.txt, migration scripts, and any custom build steps.

APP_README.md for app-specific install notes (env vars, order).

Commands to export fixtures and copy app tarballs out of the container:

# Export fixtures (if hooks.py defines them)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && bench --site $SITE export-fixtures || true"

# Create a tarball of a custom app and copy to host (repeat for each custom app)
BACKEND_CID=$(docker compose -f $COMPOSE_FILE ps -q $BACKEND)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && tar czf /tmp/my_app.tar.gz apps/my_app"
docker cp $BACKEND_CID:/tmp/my_app.tar.gz $HOST_BACKUP_DIR/my_app-$(date +%F).tar.gz


Best practice: push each custom app repo to GitHub (private if needed), and keep config/fixtures.json inside the app repo.

4. Copy backups off the container and offsite

Copy canonical backups to the host, then upload to offsite storage (S3, rclone, restic, etc.)

CONTAINER=$(docker compose -f $COMPOSE_FILE ps -q $BACKEND)
mkdir -p $HOST_BACKUP_DIR/$SITE-$(date +%F_%H%M%S)
docker cp ${CONTAINER}:$BENCH_PATH/sites/$SITE/private/backups/. $HOST_BACKUP_DIR/$SITE-$(date +%F_%H%M%S)/

# Example: upload to S3 (requires awscli configured)
aws s3 cp $HOST_BACKUP_DIR/$SITE-$(date +%F_%H%M%S)/ s3://my-secure-bucket/erpnext/$SITE-$(date +%F_%H%M%S)/ --recursive


Encrypt backups before offsite storage (GPG or use restic/borg).

5. Restore — safe order and exact commands

Critical rule: Custom app code must be present in /home/frappe/frappe-bench/apps/ on the target host BEFORE you restore the DB.
If DB is restored first, it may contain records referencing doctypes defined by custom apps that are absent and migrations/hooks may fail.

A. Prepare the target VM / host

Copy pwd.yml and any custom app repos/tarballs to the VM.

Start the compose stack:

docker compose -f $COMPOSE_FILE up -d
docker compose -f $COMPOSE_FILE ps


If you prefer, temporarily disable create-site service in the compose file to avoid auto-creation.

B. Deploy custom app code BEFORE DB restore

Option 1 — copy tarballs into backend and extract:

# copy tarball into container and extract under apps/
docker cp ~/restore/my_app.tar.gz $(docker compose -f $COMPOSE_FILE ps -q $BACKEND):/tmp/
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && tar xzf /tmp/my_app.tar.gz -C . && chown -R frappe:frappe apps/my_app || true"


Option 2 — clone from Git into a host folder that will be accessible to the container:

# on VM host
cd ~/frappe_docker  # folder where compose runs
git clone git@github.com:you/my_app.git apps/my_app
# ensure container sees it (volumes should already include sites/logs; copying may be needed)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "chown -R frappe:frappe /home/frappe/frappe-bench/apps/my_app || true"

C. Install app dependencies & build assets
# install python dependencies per app (if requirements.txt present)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && for app in apps/*; do if [ -f \$app/requirements.txt ]; then pip install -r \$app/requirements.txt || true; fi; done"

# build assets
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && bench build || true"

D. Copy DB and files backup into backend container
docker cp ~/restore/frontend-database-YYYY.sql.gz $(docker compose -f $COMPOSE_FILE ps -q $BACKEND):$BENCH_PATH/sites/$SITE/private/backups/
docker cp ~/restore/files-YYYY.tar.gz $(docker compose -f $COMPOSE_FILE ps -q $BACKEND):$BENCH_PATH/sites/$SITE/private/backups/

E. Run canonical restore (inside backend container)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "
  set -e;
  cd $BENCH_PATH;

  # restore DB (use --force to overwrite an existing site)
  bench --site $SITE --force restore sites/$SITE/private/backups/frontend-database-YYYY.sql.gz;

  # extract uploaded files (if present)
  cd sites/$SITE;
  for f in private/backups/files-*.tar.gz; do
    [ -f \"\$f\" ] && tar -xzvf \"\$f\" -C . || true;
  done;

  # fix permissions
  chown -R frappe:frappe $BENCH_PATH/sites;

  # run migrations, clear cache, rebuild
  cd $BENCH_PATH;
  bench --site $SITE migrate || true;
  bench --site $SITE clear-cache || true;
  bench build || true;
"

F. Restart services and verify
docker compose -f $COMPOSE_FILE restart
docker compose -f $COMPOSE_FILE ps


Verify basic site functionality:

# list sites
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "ls -la $BENCH_PATH/sites"

# check counts for a sample doctype (example: Item)
docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && bench --site $SITE console --eval \"import frappe; print(frappe.db.sql('select count(*) from `tabItem`')[0][0])\""


If FRAPPE_SITE_NAME_HEADER is frontend, add an /etc/hosts entry on your client machine:

<VM_IP> frontend


Then open http://frontend:8080 or use http://<VM_IP>:8080.

6. Post-restore common fixes

If doctypes from a custom app appear missing: ensure the app was copied to apps/ and run:

docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "cd $BENCH_PATH && bench --site $SITE install-app my_app || true && bench --site $SITE migrate"


Fix permissions:

docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "chown -R frappe:frappe $BENCH_PATH/sites"


Restart workers:

docker compose -f $COMPOSE_FILE restart queue-short queue-long scheduler websocket

7. Automation example (simple backup script + cron)

Simple backup script (example — do not commit DB dumps to repo):

#!/usr/bin/env bash
COMPOSE_FILE="pwd.yml"
SITE="frontend"
HOST_BACKUP_DIR="$HOME/erp-backups"
TS=$(date +%F_%H%M%S)
DEST="$HOST_BACKUP_DIR/$SITE-$TS"
mkdir -p "$DEST"
docker compose -f $COMPOSE_FILE exec backend bash -lc "cd $BENCH_PATH && bench --site $SITE backup --with-files"
CID=$(docker compose -f $COMPOSE_FILE ps -q backend)
docker cp ${CID}:$BENCH_PATH/sites/$SITE/private/backups/. "$DEST/"
# optional: push to S3 (awscli configured)
# aws s3 cp "$DEST" s3://my-bucket/erpnext/$SITE-$TS/ --recursive


Cron entry (edit with crontab -e):

0 2 * * * /home/ubuntu/erpnext-backup.sh >> /var/log/erpnext-backup.log 2>&1


Retention: keep 7 daily, 8 weekly, 12 monthly. Use find to prune or use restic/borg for deduplication & encryption.

8. Security checklist & best practices

✅ Keep custom apps in Git (private if necessary).

✅ Do not commit DB dumps or sites/*/private to public repos.

✅ Keep site_config.json and common_site_config.json out of public repos — commit redacted templates only.

✅ Test full restore on a staging VM monthly.

✅ Keep ERPNext/Frappe version parity between backup source and restore target.

✅ Encrypt backups before sending offsite (GPG, restic, borg).

✅ Document app install order and environment variables in APP_README.md per app.

9. Troubleshooting quick reference

Blank site / wrong site served

Cause: Host header mismatch (FRAPPE_SITE_NAME_HEADER set to frontend).

Fix: Add /etc/hosts mapping <VM_IP> frontend on the client or change env var in compose.

Restore fails: missing custom app / doctype

Cause: DB references doctypes defined by a missing app.

Fix: Deploy app code into apps/ first; run bench --site <site> migrate.

Permissions errors after file extract

Fix: docker compose -f $COMPOSE_FILE exec $BACKEND bash -lc "chown -R frappe:frappe $BENCH_PATH/sites"

DB connection refused

Fix: Verify db container is Up and common_site_config.json points to db:3306.

Large DB import issues

Use mysqldump from db container and import directly into MariaDB if you face timeouts.

10. Recommended .gitignore for this repo

Add this to .gitignore to avoid accidentally committing dumps or private files:

# avoid committing backups and large/private files
**/private/backups/*
**/private/*
sites/*/files/*
*.sql
*.sql.gz
*.tar.gz
*.env
node_modules/
dist/
__pycache__/
*.pyc

11. Appendix — One-line cheat sheets

Take canonical backup and copy out to host:

docker compose -f pwd.yml exec backend bash -lc "cd /home/frappe/frappe-bench && bench --site frontend backup --with-files" && \
CID=$(docker compose -f pwd.yml ps -q backend) && \
mkdir -p ~/erp-backups/frontend-$(date +%F_%H%M%S) && \
docker cp ${CID}:/home/frappe/frappe-bench/sites/frontend/private/backups/. ~/erp-backups/frontend-$(date +%F_%H%M%S)/


Restore after apps present and backups copied into container:

docker compose -f pwd.yml exec backend bash -lc "cd /home/frappe/frappe-bench && bench --site frontend --force restore sites/frontend/private/backups/frontend-database-YYYY.sql.gz && cd sites/frontend && for f in private/backups/files-*.tar.gz; do tar -xzvf \$f -C .; done && chown -R frappe:frappe /home/frappe/frappe-bench/sites && bench --site frontend migrate && bench --site frontend clear-cache && bench build"
