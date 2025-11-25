#!/bin/bash
# Automatic backup script for CloseFriend database

set -e

# Configuration
BACKUP_DIR="/var/backups/closefriend"
DB_NAME="closefriend"
RETENTION_DAYS=7

# Create backup directory
mkdir -p $BACKUP_DIR

# Generate backup filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/closefriend_$TIMESTAMP.sql"

# Perform backup
echo "Starting backup of $DB_NAME..."
sudo -u postgres pg_dump $DB_NAME > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE
echo "Backup created: $BACKUP_FILE.gz"

# Delete old backups (older than RETENTION_DAYS)
find $BACKUP_DIR -name "closefriend_*.sql.gz" -mtime +$RETENTION_DAYS -delete
echo "Old backups cleaned (kept last $RETENTION_DAYS days)"

# Show backup size
du -h $BACKUP_FILE.gz

echo "✓ Backup completed successfully"
