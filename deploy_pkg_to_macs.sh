#!/bin/bash

# Path to the .pkg file to be deployed
PKG_PATH="????"

# File containing list of target Macs (one per line)
HOSTS_FILE="????"

# Directory on the remote machine where the package will be copied
REMOTE_PKG_DIR="????"

# SSH credentials
SSH_USER="????"
SSH_PASS=$(security find-generic-password -a "????" -w)

#Summary Report
SUCCESSFUL_HOSTS=()
FAILED_HOSTS=()
SKIPPED_HOSTS=()

# Validate critical input files and credentials
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

# Sanitize and validate the hostname format
sanitize_host() {
    local host="$1"
    if [[ ! "$host" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        printf "Warning: Invalid hostname skipped: %s\n" "$host" >&2
        return 1
    fi
    return 0
}

# Copy the .pkg file to the remote host using rsync over SSH with password
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

# Install the .pkg on the remote host and clean up afterward
install_pkg_on_host() {
    local host="$1"
    local pkg_file
    pkg_file=$(basename "$PKG_PATH")

    sshpass -p "$SSH_PASS" ssh -tt -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "echo \"$SSH_PASS\" | sudo -S installer -pkg '$REMOTE_PKG_DIR/$pkg_file' -target /" || {
        printf "Error: Installation failed on %s\n" "$host" >&2
        return 1
    }

    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "rm -f '$REMOTE_PKG_DIR/$pkg_file'" || {
        printf "Warning: Failed to cleanup package on %s\n" "$host" >&2
    }

    # Kill and relaunch GroundControl Launchpad
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "pkill 'GroundControl Launchpad'; open /Applications/GroundControl\\ Launchpad.app" || {
        printf "Warning: Failed to restart GroundControl Launchpad on %s\n" "$host" >&2
    }
}

# Main loop to deploy package across all hosts in the list
deploy_to_all_hosts() {
    local host
    exec 3< "$HOSTS_FILE"
    while IFS= read -r -u 3 host || [[ -n "$host" ]]; do
        [[ -z "$host" || "$host" =~ ^# ]] && continue
        sanitize_host "$host" || { SKIPPED_HOSTS+=("$host"); continue; }

        printf "\n🚀 Processing host: %s\n" "$host"

        if ! copy_pkg_to_host "$host"; then
            printf "❌ Skipping installation on %s due to copy failure\n" "$host" >&2
            FAILED_HOSTS+=("$host")
            continue
        fi

        if ! install_pkg_on_host "$host"; then
            printf "❌ Installation failed on %s\n" "$host" >&2
            FAILED_HOSTS+=("$host")
            continue
        fi

        printf "✅ Successfully installed package on %s\n" "$host"
        SUCCESSFUL_HOSTS+=("$host")
    done
    exec 3<&-
}

# Entry point
main() {
    if ! validate_inputs; then
        return 1
    fi

    deploy_to_all_hosts
}

main

# Summary Report
echo -e "\n===== 📋 Deployment Summary ====="
echo "✅ Successful installs: ${#SUCCESSFUL_HOSTS[@]}"
for h in "${SUCCESSFUL_HOSTS[@]}"; do echo "   - $h"; done

echo "❌ Failed installs: ${#FAILED_HOSTS[@]}"
for h in "${FAILED_HOSTS[@]}"; do echo "   - $h"; done

echo "⚠️ Skipped hosts: ${#SKIPPED_HOSTS[@]}"
for h in "${SKIPPED_HOSTS[@]}"; do echo "   - $h"; done

echo "=================================="
