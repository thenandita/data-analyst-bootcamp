#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
docker compose up -d
echo "PostgreSQL is starting."
