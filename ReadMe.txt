Prerequisites
# Path to the .pkg file to be deployed
PKG_PATH="????"

# File containing list of target Macs (one per line)
HOSTS_FILE="????"

# Directory on the remote machine where the package will be copied
REMOTE_PKG_DIR="????"

SSH Prerequisites
Referenc: https://developer.apple.com/forums/thread/116579

# SSH credentials
SSH_USER="????"
SSH_PASS=$(security find-generic-password -a "????" -w)


This script also relies on "sshpass"

1. If needed install Homebrew by running the following command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
2. To install sshpass on macOS, run the following command using Homebrew:'brew install hudochenkov/sshpass/sshpass'


