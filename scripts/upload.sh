#!/usr/bin/env bash

##############################################################################
#
# Laravel Shared Hosting Deploy
#
# Remote FTP Uploader via LFTP (ZIP-Express Engine)
# Author: Chann Labs Creative Studio
#
##############################################################################

set -Eeuo pipefail

# Terminal Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
BLUE="\033[34m"
BOLD="\033[1m"
GRAY="\033[90m"
RESET="\033[0m"

log() {
    printf "${BLUE}[FTP]${RESET} %b\n" "$1"
}

error() {
    printf "${RED}✖ [FTP ERROR]${RESET} %b\n" "$1"
}

success() {
    printf "${GREEN}✔${RESET} %b\n" "$1"
}

divider() {
    printf "${GRAY}──────────────────────────────────────────────────────────${RESET}\n"
}

# Validation
if [[ -z "${FTP_SERVER:-}" || -z "${FTP_USERNAME:-}" || -z "${FTP_PASSWORD:-}" ]]; then
    error "Missing required FTP credentials (FTP_SERVER, FTP_USERNAME, FTP_PASSWORD)."
    exit 1
fi

# Sanitize FTP_DIRECTORY Parameter
FTP_DIRECTORY="${FTP_DIRECTORY:-/}"
FTP_DIRECTORY=$(echo "$FTP_DIRECTORY" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [[ "$FTP_DIRECTORY" == "" || "$FTP_DIRECTORY" == "." || "$FTP_DIRECTORY" == "./" || "$FTP_DIRECTORY" == "/" ]]; then
    FTP_DIRECTORY="/"
else
    if [[ "$FTP_DIRECTORY" != /* ]]; then
        FTP_DIRECTORY="/$FTP_DIRECTORY"
    fi
    FTP_DIRECTORY="${FTP_DIRECTORY%/}"
fi

# Detect Application ZIP Package
APP_PACKAGE="deploy.zip"
if [[ ! -f "$APP_PACKAGE" ]]; then
    APP_PACKAGE=$(ls deploy-*.zip 2>/dev/null | head -n 1 || true)
fi

if [[ -z "$APP_PACKAGE" || ! -f "$APP_PACKAGE" ]]; then
    error "Main application ZIP package (deploy.zip) not found."
    exit 1
fi

divider
log "${BOLD}Transfer Metadata Summary${RESET}"
log "FTP Hostname  : ${CYAN}${FTP_SERVER}${RESET}"
log "Target Path   : ${CYAN}${FTP_DIRECTORY}${RESET}"
log "Package File  : ${CYAN}${APP_PACKAGE}${RESET}"
divider

log "🚀 Uploading ZIP package and remote execution script via LFTP..."

# Execute LFTP Upload Command
if [[ "$FTP_DIRECTORY" != "/" ]]; then
    lftp -c "
      set ftp:passive-mode true;
      set ssl:verify-certificate false;
      set net:timeout 10;
      set net:max-retries 5;
      open -u '${FTP_USERNAME}','${FTP_PASSWORD}' '${FTP_SERVER}';
      mkdir -f -p '${FTP_DIRECTORY}';
      cd '${FTP_DIRECTORY}';
      put '${APP_PACKAGE}' -o 'deploy.zip';
      put deploy.php -o deploy.php;
      put unzip.php -o unzip.php;
      mkdir -f -p public;
      cd public;
      put deploy.php -o deploy.php;
      put unzip.php -o unzip.php;
    "
else
    lftp -c "
      set ftp:passive-mode true;
      set ssl:verify-certificate false;
      set net:timeout 10;
      set net:max-retries 5;
      open -u '${FTP_USERNAME}','${FTP_PASSWORD}' '${FTP_SERVER}';
      cd '/';
      put '${APP_PACKAGE}' -o 'deploy.zip';
      put deploy.php -o deploy.php;
      put unzip.php -o unzip.php;
      mkdir -f -p public;
      cd public;
      put deploy.php -o deploy.php;
      put unzip.php -o unzip.php;
    "
fi

divider
success "All deployment archives uploaded successfully via LFTP!"
divider
