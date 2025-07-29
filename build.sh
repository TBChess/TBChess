#!/bin/bash
set -e
cd "$(dirname "$0")"

mode="development"
domain="127.0.0.1"
dev_suffix="_dev"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            if [[ "$2" == "production" || "$2" == "development" ]]; then
                mode="$2"
                shift 2
            else
                echo "Invalid mode: $2"
                exit 1
            fi
            ;;
        --domain)
            if [[ -n "$2" ]]; then
                domain="$2"
                shift 2
            else
                echo "Missing value for --domain"
                exit 1
            fi
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ "$mode" == "production" ]]; then
    dev_suffix=""
fi

for prog in flutter cmake make go; do
    if ! command -v "$prog" >/dev/null 2>&1; then
        echo "Error: $prog is not installed or not in PATH."
        exit 1
    fi
done

echo "Mode: $mode"
echo "Building swisser..."
mkdir -p swisser/build
cd swisser/build
cmake ..
make -j4

if [ ! -f ./swisser ]; then
    echo "Error: failed to build swisser."
    exit 1
fi

cd ../../app
echo "Building web app..."
output="../backend/pb_public$dev_suffix/"
flutter build web --output $output --dart-define DOMAIN=$domain --dart-define MODE=$mode

cd ../backend
go build .

if [ ! -f ./tbchess ]; then
    echo "Error: failed to build tbchess backend."
    exit 1
fi

echo "Done! You can now run the app via:"
echo "./run.sh"