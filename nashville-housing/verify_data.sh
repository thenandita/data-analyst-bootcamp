#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
python scripts/verify_data.py "$@"
