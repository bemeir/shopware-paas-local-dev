#!/bin/bash

# Exit on errors
set -e

# Define paths
DEV_FOLDER="./shopware-paas-local-dev" # Path to the `dev-bemeir` folder
ROOT_DIR="./" # Root directory relative to the `dev-bemeir` folder
BACKUP_DIR="$DEV_FOLDER/config-backup"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Files to manage
SERVICES_YAML="$ROOT_DIR/config/services.yaml"
SERVICES_LOCAL_YAML="$DEV_FOLDER/services_local.yaml"
ENV_FILE="$DEV_FOLDER/.env"
ENV_LOCAL_FILE="$DEV_FOLDER/.env.local"
SQL_FILE="$DEV_FOLDER/main-$TIMESTAMP.sql"
INSTALL_LOCK_FILE="$ROOT_DIR/install.lock"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to configure and start DDEV
configure_and_start_ddev() {
    echo "Configuring DDEV project..."
    ddev config --project-type=shopware6
    echo "DDEV configuration complete."

    echo "Starting DDEV project..."
    ddev start
    echo "DDEV project started."
}

# Function to generate a new APP_SECRET
generate_app_secret() {
    echo "Generating a new APP_SECRET..."
    NEW_SECRET=$(openssl rand -hex 32)
    echo "New APP_SECRET: $NEW_SECRET"

    # Update the source .env file
    if [ -f "$ENV_FILE" ]; then
        sed -i.bak "/^APP_SECRET=/d" "$ENV_FILE"
        echo "APP_SECRET=$NEW_SECRET" >> "$ENV_FILE"
        echo "APP_SECRET updated in $ENV_FILE."
    else
        echo "Error: $ENV_FILE not found. Cannot update APP_SECRET."
        exit 1
    fi

    # Update the source .env.local file
    if [ -f "$ENV_LOCAL_FILE" ]; then
        sed -i.bak "/^APP_SECRET=/d" "$ENV_LOCAL_FILE"
        echo "APP_SECRET=$NEW_SECRET" >> "$ENV_LOCAL_FILE"
        echo "APP_SECRET updated in $ENV_LOCAL_FILE."
    else
        echo "Warning: $ENV_LOCAL_FILE not found. Skipping update."
    fi
}

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

# Function to dump and download database
dump_and_download_database() {
    PROJECT="6ixmky32aoiwe"
    ENVIRONMENT="development"
    APP="app"
    REMOTE_USER="${PROJECT}-${ENVIRONMENT}-q5nzhaa--${APP}"
    REMOTE_HOST="ssh.us.platform.sh"
    LOCAL_TMP_DIR="./shopware-paas-local-dev/"
    REMOTE_TMP_DIR="../tmp"
    DATE=$(date +"%Y%m%d%H%M%S")
    DUMP_FILE="main-$DATE.sql"
    REMOTE_DUMP_FILE="$REMOTE_TMP_DIR/$DUMP_FILE"

    echo "Dumping database to remote tmp directory..."
    shopware ssh --project "$PROJECT" --environment "$ENVIRONMENT" --app "$APP" \
        "mysqldump -uroot -h database.internal main > $REMOTE_DUMP_FILE"

    echo "Downloading database dump to $LOCAL_TMP_DIR..."
    rsync -avz -e "ssh" "${REMOTE_USER}@${REMOTE_HOST}:$REMOTE_TMP_DIR/$DUMP_FILE" "$LOCAL_TMP_DIR/"

    echo "Cleaning up remote tmp directory..."
    shopware ssh --project "$PROJECT" --environment "$ENVIRONMENT" --app "$APP" \
        "rm $REMOTE_DUMP_FILE"

    # Update SQL_FILE with the downloaded dump path
    SQL_FILE="$LOCAL_TMP_DIR/$DUMP_FILE"
    echo "Database dump downloaded to $SQL_FILE"
}

# Function to restore the database
restore_database() {
    echo "Restoring database from $SQL_FILE..."
    if [ -f "$SQL_FILE" ]; then
        configure_and_start_ddev
        ddev import-db --src="$SQL_FILE"
        echo "Database restored successfully."

        # Wait for database to be fully ready
        echo "Waiting for the database to be ready..."
        while ! ddev mysql -e "SELECT 1" > /dev/null 2>&1; do
            echo "Database not ready yet, retrying in 5 seconds..."
            sleep 5
        done
        echo "Database is ready."
    else
        echo "Error: $SQL_FILE not found. Skipping database restoration."
    fi
}

# Function to run build-js.sh
run_build_js() {
    echo "Running bin/build-js.sh..."
    ddev exec bash -c "bin/build-js.sh"
    echo "JavaScript build completed."
}

# Function to create the install.lock file
create_install_lock_file() {
    echo "Creating the install.lock file..."
    if [ ! -f "$INSTALL_LOCK_FILE" ]; then
        touch "$INSTALL_LOCK_FILE"
        echo "Install lock file created at $INSTALL_LOCK_FILE."
    else
        echo "Install lock file already exists."
    fi
}

# Function to activate plugins one by one
activate_plugins() {
    echo "Activating plugins one by one..."

    # Fetch the list of all plugins and filter inactive/uninstalled ones
    PLUGINS=$(ddev exec php bin/console plugin:list --json | jq -r '.[] | select(.active == false or .installed == false) | .name')

    # Loop through each plugin
    for PLUGIN in $PLUGINS; do
        echo "Processing plugin: $PLUGIN"

        # Install and activate plugin
        ddev exec php bin/console plugin:install "$PLUGIN" || echo "Failed to install $PLUGIN"
        ddev exec php bin/console plugin:activate "$PLUGIN" || echo "Failed to activate $PLUGIN"

        echo "$PLUGIN processed successfully."
    done

    # Clear cache
    ddev exec php bin/console cache:clear
    ddev exec php bin/console cache:warmup

    echo "All plugins activated successfully!"
}

# Function to configure DDEV add-ons
configure_ddev_addons() {
    echo "Installing DDEV add-ons..."

    # Install Redis
    ddev add-on get ddev/ddev-redis
    echo "Redis add-on installed."

    # Install OpenSearch
    ddev add-on get ddev/ddev-opensearch
    echo "OpenSearch add-on installed."

    # Install RabbitMQ
    ddev add-on get b13/ddev-rabbitmq
    echo "RabbitMQ add-on installed."

    # Restart DDEV to apply changes
    ddev restart
    echo "DDEV restarted with new add-ons."
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
dump_and_download_database
restore_database
configure_ddev_addons
run_build_js
create_install_lock_file
activate_plugins

echo "Script executed successfully. All tasks completed."
