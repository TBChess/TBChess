#!/bin/bash
set -e
cd "$(dirname "$0")"

mode="development"
domain="127.0.0.1"

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

echo "Running in $mode mode"

if [[ "$mode" == "production" ]]; then
    if [[ -z "${domain:-}" ]]; then
        echo "Error: --domain must be specified in production mode"
        kill $(cat swisser.pid)
        rm -f swisser.pid
        exit 1
    fi
fi

if [ ! -f ./backend/tbchess ] || [ ! -f ./swisser/build/swisser ]; then
    echo "Rebuilding..."
    ./build.sh --mode $mode --domain $domain
fi


if [ -f swisser.pid ]; then
    spid=$(cat swisser.pid)
    if kill -0 "$spid" 2>/dev/null; then
        kill "$spid"
    fi
    rm -f swisser.pid
fi

swisser_bin="swisser"
if [ -f ./swisser/build/swisser_portable ]; then
    swisser_bin="swisser_portable"
fi

./swisser/build/$swisser_bin --host 127.0.0.1 &
echo $! > swisser.pid
trap 'kill $(cat swisser.pid); rm -f swisser.pid; exit' INT


args="--http 0.0.0.0:4090 --dev --publicDir ./backend/pb_public_dev"
if [[ "$mode" == "production" ]]; then
    args="$domain"
fi

./backend/tbchess serve --automigrate $args