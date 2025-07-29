#!/bin/bash
set -e
cd "$(dirname "$0")"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <ssh_host> <domain>"
    echo "Example: $0 user@myhost myapp.com"
    exit 1
fi

SSH_HOST="$1"
shift
DOMAIN="$1"
shift

APP_DIR="$(basename "$PWD")"

if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: rsync is not installed. Please install rsync and try again."
    exit 1
fi

./build.sh --mode production --domain $DOMAIN
rsync -avz -e ssh --files-from=deploy.txt . $SSH_HOST:~/$APP_DIR