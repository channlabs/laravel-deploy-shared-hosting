#!/usr/bin/env bash

##############################################################################
#
# Laravel Shared Hosting Deploy
#
# Production Deployment Package Builder
#
# Author  : Chann Labs Creative Studio
# Version : 1.0.0
#
##############################################################################

set -Eeuo pipefail

##############################################
# Configuration
##############################################

PACKAGE_NAME="deploy.zip"

DEPLOY_SCRIPT="deploy.php"

MANIFEST_FILE="deploy-manifest.json"

CHECKSUM_FILE="deploy.sha256"

START_TIME=$(date +%s)

BUILD_TIME=$(date +"%Y-%m-%d %H:%M:%S")

##############################################
# Color
##############################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[97m"
GRAY="\033[90m"

BOLD="\033[1m"
RESET="\033[0m"

##############################################
# Logger
##############################################

timestamp() {
    date +"%H:%M:%S"
}

log() {
    printf "${BLUE}[%s]${RESET} %b\n" "$(timestamp)" "$1"
}

info() {
    printf "${CYAN}ℹ${RESET} %b\n" "$1"
}

success() {
    printf "${GREEN}✔${RESET} %b\n" "$1"
}

warning() {
    printf "${YELLOW}⚠${RESET} %b\n" "$1"
}

error() {
    printf "${RED}✖${RESET} %b\n" "$1"
}

##############################################
# Banner
##############################################

banner() {

echo

echo -e "${BOLD}${WHITE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║        Laravel Shared Hosting Deploy v1             ║"
echo "║                                                      ║"
echo "║      Production Deployment Package Builder          ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo

}

##############################################
# Error Handler
##############################################

on_error() {

    EXIT_CODE=$?

    echo

    error "Deployment packaging failed."

    error "Exit Code : ${EXIT_CODE}"

    END_TIME=$(date +%s)

    DURATION=$((END_TIME - START_TIME))

    error "Duration  : ${DURATION}s"

    exit ${EXIT_CODE}

}

trap on_error ERR

##############################################
# Divider
##############################################

divider() {

echo

printf "${GRAY}"

printf '──────────────────────────────────────────────────────────\n'

printf "${RESET}"

}

##############################################
# Requirement Check
##############################################

require() {

    if ! command -v "$1" >/dev/null 2>&1; then

        error "$1 is not installed."

        exit 1

    fi

}

##############################################
# Check Dependency
##############################################

check_dependencies() {

divider

log "Checking system requirements..."

require php
require composer
require git
require zip
require sha256sum
require find

success "PHP"

success "Composer"

success "Git"

success "ZIP"

success "SHA256"

divider

}

##############################################
# Git Information
##############################################

get_git_information() {

log "Collecting repository information..."

if git rev-parse --git-dir >/dev/null 2>&1
then

    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    GIT_COMMIT=$(git rev-parse --short HEAD)

    GIT_AUTHOR=$(git log -1 --pretty=format:'%an')

else

    GIT_BRANCH="unknown"

    GIT_COMMIT="unknown"

    GIT_AUTHOR="unknown"

fi

REPOSITORY="${GITHUB_REPOSITORY:-local}"

RUN_NUMBER="${GITHUB_RUN_NUMBER:-0}"

RUN_ID="${GITHUB_RUN_ID:-0}"

ACTOR="${GITHUB_ACTOR:-local}"

success "Repository metadata collected."

divider

}

##############################################
# Project Validation
##############################################

validate_project() {

log "Validating Laravel project..."

[[ -f artisan ]] || {

    error "artisan not found."

    exit 1

}

[[ -f composer.json ]] || {

    error "composer.json not found."

    exit 1

}

[[ -d app ]] || {

    error "Laravel app directory missing."

    exit 1

}

[[ -d bootstrap ]] || {

    error "bootstrap directory missing."

    exit 1

}

[[ -d public ]] || {

    error "public directory missing."

    exit 1

}

success "Laravel project detected."

divider

}

##############################################
# Deployment Metadata
##############################################

deployment_information() {

log "Deployment Information"

info "Build Time  : ${BUILD_TIME}"

info "Branch      : ${GIT_BRANCH}"

info "Commit      : ${GIT_COMMIT}"

info "Repository  : ${REPOSITORY}"

info "Actor       : ${ACTOR}"

info "Run ID      : ${RUN_ID}"

info "Run Number  : ${RUN_NUMBER}"

divider

}

##############################################
# Startup
##############################################

banner

check_dependencies

validate_project

get_git_information

deployment_information

##############################################
# Build Timer
##############################################

BUILD_START=0

start_build() {

    BUILD_START=$(date +%s)

    divider

    log "Starting production build..."

}

finish_build() {

    local end
    end=$(date +%s)

    local duration
    duration=$((end - BUILD_START))

    success "Build completed in ${duration}s"

    divider

}

##############################################
# Composer Validation
##############################################

composer_validate() {

    log "Validating composer.json..."

    composer validate \
        --no-check-publish \
        --ansi

    success "composer.json is valid."

}

##############################################
# Install Composer Dependencies
##############################################

composer_install() {

    log "Installing production dependencies..."

    composer install \
        --prefer-dist \
        --no-dev \
        --optimize-autoloader \
        --classmap-authoritative \
        --no-interaction \
        --no-progress \
        --ansi

    success "Composer dependencies installed."

}

##############################################
# Prepare Environment
##############################################

prepare_environment() {

    log "Preparing environment..."

    if [[ ! -f ".env" ]]; then

        if [[ -f ".env.example" ]]; then

            cp .env.example .env

            success ".env created from .env.example"

        else

            warning ".env.example not found."

        fi

    else

        info ".env already exists."

    fi

}

##############################################
# Clear Laravel Cache
##############################################

clear_laravel_cache() {

    log "Clearing Laravel cache..."

    php artisan optimize:clear || true

    rm -f bootstrap/cache/*.php || true

    success "Laravel cache cleared."

}

##############################################
# Validate Storage
##############################################

prepare_storage() {

    log "Preparing storage directories..."

    REQUIRED_DIRS=(

        storage/framework/cache/data
        storage/framework/sessions
        storage/framework/views
        storage/logs
        bootstrap/cache

    )

    for dir in "${REQUIRED_DIRS[@]}"
    do

        mkdir -p "$dir"

    done

    success "Storage directories are ready."

}

##############################################
# Fix Permissions
##############################################

fix_permissions() {

    log "Applying writable permissions..."

    chmod -R 775 storage || true

    chmod -R 775 bootstrap/cache || true

    success "Permissions updated."

}

##############################################
# Execute Build Preparation
##############################################

start_build

composer_validate

composer_install

prepare_environment

clear_laravel_cache

prepare_storage

fix_permissions

##############################################
# Detect Package Manager
##############################################

PACKAGE_MANAGER=""

detect_package_manager() {

    log "Detecting JavaScript package manager..."

    if [[ -f "pnpm-lock.yaml" ]]; then

        PACKAGE_MANAGER="pnpm"

    elif [[ -f "package-lock.json" ]]; then

        PACKAGE_MANAGER="npm"

    elif [[ -f "yarn.lock" ]]; then

        PACKAGE_MANAGER="yarn"

    else

        error "No supported package manager lockfile found."

        error "Expected one of:"
        error "- pnpm-lock.yaml"
        error "- package-lock.json"
        error "- yarn.lock"

        exit 1

    fi

    success "Using ${PACKAGE_MANAGER}"

}

##############################################
# Install Node Dependencies
##############################################

install_node_dependencies() {

    log "Installing frontend dependencies..."

    case "$PACKAGE_MANAGER" in

        pnpm)

            pnpm install --frozen-lockfile
            ;;

        npm)

            npm ci
            ;;

        yarn)

            yarn install --frozen-lockfile
            ;;

    esac

    success "Frontend dependencies installed."

}

##############################################
# Build Frontend Assets
##############################################

build_frontend() {

    log "Building production assets..."

    case "$PACKAGE_MANAGER" in

        pnpm)

            pnpm run build
            ;;

        npm)

            npm run build
            ;;

        yarn)

            yarn build
            ;;

    esac

    success "Production assets generated."

}

##############################################
# Remove Hot File
##############################################

remove_hot_file() {

    if [[ -f public/hot ]]; then

        log "Removing Vite hot file..."

        rm -f public/hot

        success "public/hot removed."

    fi

}

##############################################
# Validate Assets
##############################################

validate_assets() {

    log "Validating generated assets..."

    if [[ ! -d public/build ]]; then

        error "public/build not found."

        exit 1

    fi

    FILE_COUNT=$(find public/build -type f | wc -l)

    if [[ "$FILE_COUNT" -eq 0 ]]; then

        error "No production assets found."

        exit 1

    fi

    success "${FILE_COUNT} production assets detected."

}

##############################################
# Package Manager Cleanup
##############################################

cleanup_package_manager() {

    log "Cleaning package manager cache..."

    case "$PACKAGE_MANAGER" in

        pnpm)

            pnpm store prune || true
            ;;

        npm)

            npm cache clean --force || true
            ;;

        yarn)

            yarn cache clean || true
            ;;

    esac

    success "Package manager cache cleaned."

}

##############################################
# Asset Information
##############################################

asset_information() {

    divider

    log "Asset Summary"

    BUILD_SIZE=$(du -sh public/build | cut -f1)

    FILE_COUNT=$(find public/build -type f | wc -l)

    info "Directory : public/build"

    info "Files     : ${FILE_COUNT}"

    info "Size      : ${BUILD_SIZE}"

    divider

}

##############################################
# Execute Frontend Build
##############################################

detect_package_manager

install_node_dependencies

build_frontend

remove_hot_file

validate_assets

cleanup_package_manager

asset_information

finish_build

##############################################
# Package Information
##############################################

PACKAGE_NAME="deploy.zip"

# Compute composer.lock hash for vendor caching
COMPOSER_LOCK_HASH=""
if [[ -f "composer.lock" ]]; then
    COMPOSER_LOCK_HASH=$(sha256sum composer.lock | cut -d' ' -f1)
else
    COMPOSER_LOCK_HASH="no-lock"
fi
VENDOR_PACKAGE_NAME="vendor-${COMPOSER_LOCK_HASH}.zip"

##############################################
# Build Manifest
##############################################

generate_manifest() {

    divider

    log "Generating deployment manifest..."

    cat > "${MANIFEST_FILE}" <<EOF
{
  "application": "${REPOSITORY}",
  "branch": "${GIT_BRANCH}",
  "commit": "${GIT_COMMIT}",
  "author": "${GIT_AUTHOR}",
  "actor": "${ACTOR}",
  "run_id": "${RUN_ID}",
  "run_number": "${RUN_NUMBER}",
  "build_time": "${BUILD_TIME}",
  "package": "${PACKAGE_NAME}",
  "vendor_hash": "${COMPOSER_LOCK_HASH}",
  "builder": "Laravel Shared Hosting Deploy v1"
}
EOF

    success "Deployment manifest created."

}

##############################################
# SHA256
##############################################

generate_checksum() {

    log "Generating SHA256 checksum..."

    sha256sum "${MANIFEST_FILE}" > "${CHECKSUM_FILE}"

    success "Checksum generated."

}

##############################################
# Build Information
##############################################

build_summary() {

    divider

    log "Deployment Package Summary"

    info "App Package  : ${PACKAGE_NAME}"
    info "Vendor Pkg   : ${VENDOR_PACKAGE_NAME}"
    info "Manifest     : ${MANIFEST_FILE}"
    info "Checksum     : ${CHECKSUM_FILE}"

    divider

}

##############################################
# Generate Deploy Script
##############################################

generate_deploy_script() {

    log "Generating deploy and unzip scripts..."

    # Read action path or fallback to current action path
    ACTION_PATH="${GITHUB_ACTION_PATH:-$(dirname "$0")/..}"

    if [[ ! -f "${ACTION_PATH}/scripts/deploy.php.template" ]]; then

        error "deploy.php.template not found at ${ACTION_PATH}/scripts/deploy.php.template"

        exit 1

    fi

    cp "${ACTION_PATH}/scripts/deploy.php.template" "${DEPLOY_SCRIPT}"
    cp "${ACTION_PATH}/scripts/deploy.php.template" "unzip.php"

    # Replace variables in the template
    sed -i "s|__DEPLOY_TOKEN__|${DEPLOY_TOKEN:-}|g" "${DEPLOY_SCRIPT}"
    sed -i "s|__DEPLOY_TOKEN__|${DEPLOY_TOKEN:-}|g" "unzip.php"
    sed -i "s|__PACKAGE__|deploy.zip|g" "${DEPLOY_SCRIPT}"
    sed -i "s|__PACKAGE__|deploy.zip|g" "unzip.php"
    sed -i "s|__RUN_MIGRATIONS__|${RUN_MIGRATIONS:-true}|g" "${DEPLOY_SCRIPT}"
    sed -i "s|__RUN_MIGRATIONS__|${RUN_MIGRATIONS:-true}|g" "unzip.php"
    sed -i "s|__OPTIMIZE__|${OPTIMIZE:-true}|g" "${DEPLOY_SCRIPT}"
    sed -i "s|__OPTIMIZE__|${OPTIMIZE:-true}|g" "unzip.php"
    sed -i "s|__MAINTENANCE__|${MAINTENANCE:-true}|g" "${DEPLOY_SCRIPT}"
    sed -i "s|__MAINTENANCE__|${MAINTENANCE:-true}|g" "unzip.php"

    success "deploy.php and unzip.php generated."

}

##############################################
# ZIP Exclusion
##############################################

ZIP_EXCLUDES=(
    ".git/*"
    "*/.git/*"
    ".github/*"
    "*/.github/*"
    "node_modules/*"
    "*/node_modules/*"
    "tests/*"
    "*/tests/*"
    ".env"
    "storage/logs/*"
    "*/storage/logs/*"
    "storage/framework/cache/data/*"
    "*/storage/framework/cache/data/*"
    "storage/framework/views/*"
    "*/storage/framework/views/*"
    "storage/framework/sessions/*"
    "*/storage/framework/sessions/*"
    "bootstrap/cache/*"
    "*/bootstrap/cache/*"
    "_backup_*"
    "deploy*.zip"
    "vendor-*.zip"
    "deploy.php"
    "unzip.php"
)

build_zip_arguments() {

    ZIP_ARGS=()

    for pattern in "${ZIP_EXCLUDES[@]}"
    do

        ZIP_ARGS+=(-x "$pattern")

    done

}

##############################################
# Build Vendor ZIP
##############################################

build_vendor_package() {

    divider

    log "Building vendor package..."

    if [[ ! -d "vendor" ]]; then
        error "vendor directory not found!"
        exit 1
    fi

    # Zip vendor folder
    zip -9 -r "${VENDOR_PACKAGE_NAME}" vendor

    success "Vendor package created: ${VENDOR_PACKAGE_NAME}"

}

##############################################
# Build App ZIP
##############################################

build_package() {

    divider

    log "Building main application package..."

    build_zip_arguments

    zip \
        -9 \
        -r \
        "${PACKAGE_NAME}" \
        . \
        "${ZIP_ARGS[@]}"

    success "Deployment app archive created."

}

##############################################
# Verify Packages
##############################################

verify_package() {

    log "Verifying deployment archive..."

    if [[ ! -f "${PACKAGE_NAME}" ]]; then

        error "App Package (deploy.zip) not found."

        exit 1

    fi

    APP_SIZE=$(du -sh "${PACKAGE_NAME}" | cut -f1)

    info "App Archive Size : ${APP_SIZE}"

    sha256sum "${PACKAGE_NAME}" >> "${CHECKSUM_FILE}"

    success "Package verification completed."

}

##############################################
# Execute Packaging Operations
##############################################

generate_manifest
generate_checksum
generate_deploy_script
build_package
verify_package
build_summary