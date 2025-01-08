# Shopware PaaS Local Development Setup

This guide provides a step-by-step process for setting up a local development environment for Shopware PaaS using the provided Bash script.

---

## Prerequisites

### 1. Clone the Repositories

Clone the necessary repositories to your local machine:

```bash
git clone git@github.com:bemeir/cds-shopware6.git
cd cds-shopware6
git checkout "Branch of your choice (e.g., 'master', 'staging', 'development')" - we want development here.

git clone git@github.com:bemeir/shopware-paas-local-dev.git
cd shopware-paas-local-dev
```

### 2. Install DDEV

Install and configure DDEV on your machine by following the [official DDEV installation guide](https://ddev.readthedocs.io/en/stable/#installation).

### 3. Ensure Required Tools Are Installed

-   **Git**: For version control and repository management.
-   **Bash Shell**: Required to execute the provided setup script.
-   **jq**: Command-line JSON processor (required for plugin activation).

---

## Script Features

### 1. Backup `services.yaml`

-   Creates a timestamped backup of the root `services.yaml` before replacing it.
-   Backups are stored in the `dev-bemeir/config-backup/` directory.

### 2. Replace `services.yaml`

-   Replaces the root `services.yaml` with the `services_local.yaml` from the `dev-bemeir/` folder.

### 3. Copy `.env` and `.env.local`

-   Copies `.env` and `.env.local` from the `dev-bemeir/` folder to the root of the project.

### 4. Generate `APP_SECRET`

-   Generates a new `APP_SECRET` and updates it in both `.env` and `.env.local` files.

### 5. Dump and Download Database

-   Dumps the current environment database remotely and downloads it locally for restoration.

### 6. Restore Database

-   Imports the downloaded database dump into the local environment using DDEV.

### 7. Configure DDEV Add-ons

-   Installs necessary add-ons such as Redis, OpenSearch, and RabbitMQ.

### 8. Build JavaScript

-   Executes `bin/build-js.sh` to build JavaScript files for the Shopware project.

### 9. Create `install.lock`

-   Ensures the `install.lock` file exists in the project root.

### 10. Activate Plugins

-   Iterates over all plugins in the Shopware project and activates any inactive or uninstalled plugins.

---

## Usage

### Step 1: Run the Script

Navigate to the `shopware-paas-local-dev` folder and execute the setup script:

```bash
cd shopware-paas-local-dev/
chmod +x setup_env.sh
cd ..
./shopware-paas-local-dev/setup_env.sh
```

### Step 2: Actions Performed

-   **Backup `services.yaml`:**
    -   Creates a backup in `config-backup/` with a timestamped filename. - this is important when we push work to branch ignore the config/services.yaml both platform.sh and locals use it.
-   **Replace `services.yaml`:**
    -   Replaces the root `services.yaml` with `services_local.yaml`.
-   **Copy `.env` and `.env.local`:**
    -   Moves these environment files to the project root.
-   **Generate `APP_SECRET`:**
    -   Updates the secret in `.env` and `.env.local` files.
-   **Dump and Download Database:**
    -   Downloads the database dump from the remote environment.
-   **Restore Database:**
    -   Imports the database into DDEV.
-   **Install Add-ons:**
    -   Installs Redis, OpenSearch, and RabbitMQ add-ons using DDEV.
-   **Run JavaScript Build:**
    -   Builds JavaScript using `bin/build-js.sh`.
-   **Create `install.lock`:**
    -   Ensures the `install.lock` file exists in the root.
-   **Activate Plugins:**
    -   Installs and activates all plugins.

---

## Notes

1. Ensure the `dev-bemeir` folder contains the required `services_local.yaml`, `.env`, and `.env.local` files before running the script.
2. The script assumes you have valid credentials for accessing the remote database.
3. Install necessary tools (`jq`, `git`, etc.) before executing the script.

---

## License

This script is provided as-is for development purposes. Handle sensitive data securely. .env and .env.local have APP_SECRET of the current broken stage so we can continue working but we will be removing this and making sure its not defined as part of this repo. Please note that we still have to edit .env and .env.local well only .env.local after this build script finishes if we want to change some things like the said APP_SECRET. 
