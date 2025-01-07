#!/bin/bash

# Exit on errors
set -e

# Define paths
DEV_FOLDER="dev-bemeir"
ROOT_DIR="../" # Root directory relative to the `dev-bemeir` folder
BACKUP_DIR="$DEV_FOLDER/config-backup"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Files to manage
SERVICES_YAML="$ROOT_DIR/config/services.yaml"
SERVICES_LOCAL_YAML="$DEV_FOLDER/config/services_local.yaml"
ENV_FILE="$DEV_FOLDER/.env"
ENV_LOCAL_FILE="$DEV_FOLDER/.env.local"
SQL_FILE="$DEV_FOLDER/main.sql"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to backup services.yaml
backup_services() {
    echo "Backing up $SERVICES_YAML to $BACKUP_DIR/services.yaml.backup.$TIMESTAMP..."
    if [ -f "$SERVICES_YAML" ]; then
        cp "$SERVICES_YAML" "$BACKUP_DIR/services.yaml.backup.$TIMESTAMP"
        echo "Backup created: $BACKUP_DIR/services.yaml.backup.$TIMESTAMP."
    else
        echo "Warning: $SERVICES_YAML not found. Skipping backup."
    fi
}

# Function to replace services.yaml with services_local.yaml
replace_services() {
    echo "Overwriting $SERVICES_YAML with $SERVICES_LOCAL_YAML..."
    cp "$SERVICES_LOCAL_YAML" "$SERVICES_YAML"
    echo "$SERVICES_YAML has been updated with $SERVICES_LOCAL_YAML."
}

# Function to copy .env and .env.local to root
copy_env_files() {
    echo "Copying .env and .env.local to project root..."
    cp "$ENV_FILE" "$ROOT_DIR"
    cp "$ENV_LOCAL_FILE" "$ROOT_DIR"
    echo ".env and .env.local have been copied to the root."
}

# Function to restore the database
restore_database() {
    echo "Restoring database from $SQL_FILE..."
    if [ -f "$SQL_FILE" ]; then
        ddev import-db --src="$SQL_FILE"
        echo "Database restored successfully."
    else
        echo "Error: $SQL_FILE not found. Skipping database restoration."
    fi
}

# Placeholder for future DB dump and download functionality
dump_and_download_database() {
    echo "This function will handle database dump and download in the future."
    # Example placeholder logic:
    # - SSH into remote server to dump DB
    # - Download the dump locally
}

# Main script execution
echo "Starting script from dev-bemeir..."

# Ensure required files exist
if [ ! -f "$SERVICES_LOCAL_YAML" ]; then
    echo "Error: $SERVICES_LOCAL_YAML not found. Exiting."
    exit 1
fi

if [ ! -f "$ENV_FILE" ] || [ ! -f "$ENV_LOCAL_FILE" ]; then
    echo "Error: .env or .env.local not found in $DEV_FOLDER. Exiting."
    exit 1
fi

# Execute tasks
backup_services
replace_services
copy_env_files
restore_database

echo "Script executed successfully. Ready for future database dump and download integration."
