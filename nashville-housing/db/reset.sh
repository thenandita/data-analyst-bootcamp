#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
docker compose down -v
echo "PostgreSQL stopped and data volume removed."
