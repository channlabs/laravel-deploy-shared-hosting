#!/usr/bin/env bash

##############################################################################
#
# Laravel Shared Hosting Deploy
#
# Deployment Health Checker & System Verifier Engine
# Author: Chann Labs Creative Studio
#
##############################################################################

set -Eeuo pipefail

# Terminal Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
GRAY="\033[90m"
BOLD="\033[1m"
RESET="\033[0m"

log() {
    printf "${CYAN}[Health]${RESET} %b\n" "$1"
}

warning() {
    printf "${YELLOW}⚠ [Health Warning]${RESET} %b\n" "$1"
}

error() {
    printf "${RED}✖ [Health Error]${RESET} %b\n" "$1"
}

success() {
    printf "${GREEN}✔${RESET} %b\n" "$1"
}

divider() {
    printf "${GRAY}──────────────────────────────────────────────────────────${RESET}\n"
}

if [[ $# -lt 1 ]]; then
    error "Missing target deployment URL argument."
    exit 1
fi

TARGET_URL="$1"
MAX_ATTEMPTS=5
DELAY_SECONDS=5

divider
log "${BOLD}Starting System Health Check Verification${RESET}"
log "Target Endpoint : ${CYAN}${TARGET_URL}${RESET}"
divider

ATTEMPT=1
SUCCESS=false

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    log "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Querying target deployment URL..."
    
    # Perform HTTP request and capture status code
    STATUS_CODE=$(curl -s -L -A "$USER_AGENT" -o /dev/null -w "%{http_code}" --connect-timeout 5 "$TARGET_URL" || echo "000")
    
    log "HTTP Response Status Code: ${BOLD}${STATUS_CODE}${RESET}"
    
    # 2xx (Success) and 3xx (Redirects) are considered healthy
    if [[ "$STATUS_CODE" =~ ^[23][0-9][0-9]$ ]]; then
        divider
        success "Application is healthy and serving traffic! Response status: ${BOLD}${STATUS_CODE}${RESET}."
        divider
        SUCCESS=true
        break
    else
        warning "Server returned status code (${STATUS_CODE}). Retrying in ${DELAY_SECONDS} seconds..."
        sleep $DELAY_SECONDS
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [[ "$SUCCESS" = false ]]; then
    divider
    error "Application health check verification failed after ${MAX_ATTEMPTS} attempts."
    
    # Print diagnostic response body snippet
    log "Diagnostic Details (Server Response Body Snippet):"
    echo "--------------------------------------------------"
    curl -s -L -A "$USER_AGENT" --connect-timeout 5 -m 10 "$TARGET_URL" | head -n 50 || echo "Failed to fetch response body from server."
    echo "--------------------------------------------------"
    divider
    
    exit 1
fi
