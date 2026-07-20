#!/usr/bin/env bash

##############################################################################
#
# Laravel Shared Hosting Deploy
#
# Deployment Health Checker / Verifier
#
##############################################################################

set -Eeuo pipefail

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
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

if [[ $# -lt 1 ]]; then
    error "Missing target deployment URL argument."
    exit 1
fi

TARGET_URL="$1"
MAX_ATTEMPTS=5
DELAY_SECONDS=5

log "Starting health check verification for ${TARGET_URL}..."

ATTEMPT=1
SUCCESS=false

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    log "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Querying target URL..."
    
    # Perform HTTP request and capture status code
    STATUS_CODE=$(curl -s -L -A "$USER_AGENT" -o /dev/null -w "%{http_code}" --connect-timeout 5 "$TARGET_URL" || echo "000")
    
    log "HTTP Status Code: ${STATUS_CODE}"
    
    # 2xx (Success) and 3xx (Redirects) are considered healthy
    if [[ "$STATUS_CODE" =~ ^[23][0-9][0-9]$ ]]; then
        success "Application is healthy! Received status ${STATUS_CODE}."
        SUCCESS=true
        break
    else
        warning "Application returned unhealthy status ${STATUS_CODE}. Retrying in ${DELAY_SECONDS} seconds..."
        sleep $DELAY_SECONDS
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [[ "$SUCCESS" = false ]]; then
    error "Application health check failed after ${MAX_ATTEMPTS} attempts."
    
    # Print diagnostic body details
    log "Diagnostic Details (Response Body Snippet):"
    echo "--------------------------------------------------"
    curl -s -L -A "$USER_AGENT" --connect-timeout 5 -m 10 "$TARGET_URL" | head -n 50 || echo "Failed to fetch response body."
    echo "--------------------------------------------------"
    
    exit 1
fi
