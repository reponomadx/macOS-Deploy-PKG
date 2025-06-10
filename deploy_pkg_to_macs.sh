#!/bin/bash

# --------------------------------
# CONFIGURATION
# --------------------------------
PKG_PATH="????"              # Path to the .pkg file to be deployed
HOSTS_FILE="????"            # File containing list of target Macs (one per line)
REMOTE_PKG_DIR="????"        # Directory on the remote machine where the package will be copied
SSH_USER="????"              # SSH user
SSH_PASS=$(security find-generic-password -a "????" -w)  # SSH password from keychain

# Summary arrays
SUCCESSFUL_HOSTS=()
FAILED_HOSTS=()
SKIPPED_HOSTS=()

# --------------------------------
# INPUT VALIDATION
# --------------------------------
validate_inputs() {
    if [[ ! -f "$PKG_PATH" ]]; then
        printf "Error: Package file not found: %s\n" "$PKG_PATH" >&2
        return 1
    fi

    if [[ ! -f "$HOSTS_FILE" ]]; then
        printf "Error: Hosts file not found: %s\n" "$HOSTS_FILE" >&2
        return 1
    fi

    if [[ -z "$SSH_PASS" ]]; then
        printf "Error: SSH password is not set\n" >&2
        return 1
    fi

    if ! command -v sshpass >/dev/null 2>&1; then
        printf "Error: sshpass command is required but not installed\n" >&2
        return 1
    fi
}

# --------------------------------
# HOST SANITIZATION
# --------------------------------
sanitize_host() {
    local host="$1"
    if [[ ! "$host" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        printf "Warning: Invalid hostname skipped: %s\n" "$host" >&2
        return 1
    fi
    return 0
}

# --------------------------------
# PACKAGE COPY
# --------------------------------
copy_pkg_to_host() {
    local host="$1"

    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" "mkdir -p '$REMOTE_PKG_DIR'" || {
        printf "Error: Failed to create remote directory on %s\n" "$host" >&2
        return 1
    }

    sshpass -p "$SSH_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -avz "$PKG_PATH" "$SSH_USER@$host:$REMOTE_PKG_DIR/" || {
        printf "Error: Failed to copy package to %s\n" "$host" >&2
        return 1
    }
}

# --------------------------------
# DEPLOY LOOP
# --------------------------------
deploy_to_all_hosts() {
    local host
    exec 3< "$HOSTS_FILE"
    while IFS= read -r -u 3 host || [[ -n "$host" ]]; do
        [[ -z "$host" || "$host" =~ ^# ]] && continue
        sanitize_host "$host" || { SKIPPED_HOSTS+=("$host"); continue; }

        printf "\n🚀 Copying to host: %s\n" "$host"

        if ! copy_pkg_to_host "$host"; then
            FAILED_HOSTS+=("$host")
            continue
        fi

        SUCCESSFUL_HOSTS+=("$host")
    done
    exec 3<&-
}

# --------------------------------
# MAIN
# --------------------------------
main() {
    if ! validate_inputs; then
        return 1
    fi

    deploy_to_all_hosts
}

main

# --------------------------------
# SUMMARY
# --------------------------------
echo -e "\n===== 📋 Deployment Summary ====="
echo "✅ Successful copies: ${#SUCCESSFUL_HOSTS[@]}"
for h in "${SUCCESSFUL_HOSTS[@]}"; do echo "   - $h"; done

echo "❌ Failed copies: ${#FAILED_HOSTS[@]}"
for h in "${FAILED_HOSTS[@]}"; do echo "   - $h"; done

echo "⚠️ Skipped hosts: ${#SKIPPED_HOSTS[@]}"
for h in "${SKIPPED_HOSTS[@]}"; do echo "   - $h"; done
echo "=================================="
