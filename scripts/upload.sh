#!/usr/bin/env bash

##############################################################################
#
# Laravel Shared Hosting Deploy
#
# Remote FTP Uploader (with Vendor Caching)
#
##############################################################################

set -Eeuo pipefail

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
BLUE="\033[34m"
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

# Validation
if [[ -z "${FTP_SERVER:-}" || -z "${FTP_USERNAME:-}" || -z "${FTP_PASSWORD:-}" ]]; then
    error "Missing required FTP credentials (FTP_SERVER, FTP_USERNAME, FTP_PASSWORD)."
    exit 1
fi

# Sanitize FTP_DIRECTORY
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

# Detect application package name
APP_PACKAGE=$(ls deploy-*.zip 2>/dev/null | head -n 1 || true)
if [[ -z "$APP_PACKAGE" ]]; then
    error "Main application zip package not found. Run package.sh first."
    exit 1
fi

# Compute composer.lock hash
COMPOSER_LOCK_HASH=""
if [[ -f "composer.lock" ]]; then
    COMPOSER_LOCK_HASH=$(sha256sum composer.lock | cut -d' ' -f1)
else
    COMPOSER_LOCK_HASH="no-lock"
fi
VENDOR_PACKAGE_NAME="vendor-${COMPOSER_LOCK_HASH}.zip"

log "FTP Server       : ${FTP_SERVER}"
log "FTP Directory    : ${FTP_DIRECTORY}"
log "App Package      : ${APP_PACKAGE}"
log "Vendor Package   : ${VENDOR_PACKAGE_NAME}"

# Step 1: Ensure directory structure and check if vendor zip is cached
log "Checking if vendor package is already cached on remote FTP server..."

CHECK_SCRIPT=$(mktemp)
cat <<EOF > "$CHECK_SCRIPT"
set ftp:passive-mode true
set ssl:verify-certificate false
set net:timeout 10
set net:max-retries 3
EOF

if [[ "$FTP_DIRECTORY" != "/" ]]; then
    cat <<EOF >> "$CHECK_SCRIPT"
mkdir -p "${FTP_DIRECTORY}"
cd "${FTP_DIRECTORY}"
EOF
else
    cat <<EOF >> "$CHECK_SCRIPT"
cd "/"
EOF
fi

cat <<EOF >> "$CHECK_SCRIPT"
mkdir -p _vendor_cache
cd _vendor_cache
nlist "${VENDOR_PACKAGE_NAME}"
quit
EOF

VENDOR_EXISTS=$(lftp -u "${FTP_USERNAME},${FTP_PASSWORD}" "${FTP_SERVER}" -f "$CHECK_SCRIPT" 2>/dev/null || echo "cache_miss")
rm -f "$CHECK_SCRIPT"

UPLOAD_VENDOR=true
if echo "$VENDOR_EXISTS" | grep -Fq "${VENDOR_PACKAGE_NAME}"; then
    log "${GREEN}Vendor cache hit!${RESET} ${VENDOR_PACKAGE_NAME} is already cached on remote server."
    UPLOAD_VENDOR=false
else
    log "${YELLOW}Vendor cache miss.${RESET} ${VENDOR_PACKAGE_NAME} will be uploaded."
fi

# Step 2: Upload Files (app zip, deploy.php, and optionally vendor zip)
log "Starting upload operations..."

LFTP_SCRIPT=$(mktemp)

cat <<EOF > "$LFTP_SCRIPT"
set ftp:passive-mode true
set ssl:verify-certificate false
set net:timeout 10
set net:max-retries 5
set net:reconnect-interval-base 5
set net:reconnect-interval-multiplier 2
set cmd:fail-exit true
EOF

if [[ "$FTP_DIRECTORY" != "/" ]]; then
    cat <<EOF >> "$LFTP_SCRIPT"
mkdir -p "${FTP_DIRECTORY}"
cd "${FTP_DIRECTORY}"
EOF
else
    cat <<EOF >> "$LFTP_SCRIPT"
cd "/"
EOF
fi

cat <<EOF >> "$LFTP_SCRIPT"
# Ensure public directory exists
mkdir -p public

# Upload main app package and deploy.php
echo "Uploading application package..."
put "${APP_PACKAGE}" -o "${APP_PACKAGE}"
echo "Uploading deployment execution script..."
put "deploy.php" -o "public/deploy.php"
EOF

if [[ "$UPLOAD_VENDOR" == "true" ]]; then
    if [[ ! -f "${VENDOR_PACKAGE_NAME}" ]]; then
        error "Vendor package ${VENDOR_PACKAGE_NAME} not found locally."
        rm -f "$LFTP_SCRIPT"
        exit 1
    fi
    cat <<EOF >> "$LFTP_SCRIPT"
echo "Uploading vendor package to cache..."
mkdir -p _vendor_cache
put "${VENDOR_PACKAGE_NAME}" -o "_vendor_cache/${VENDOR_PACKAGE_NAME}"
EOF
fi

echo "quit" >> "$LFTP_SCRIPT"

# Execute LFTP upload
if lftp -u "${FTP_USERNAME},${FTP_PASSWORD}" "${FTP_SERVER}" -f "$LFTP_SCRIPT"; then
    success "All files uploaded successfully!"
    rm -f "$LFTP_SCRIPT"
else
    error "LFTP upload operation failed."
    rm -f "$LFTP_SCRIPT"
    exit 1
fi
