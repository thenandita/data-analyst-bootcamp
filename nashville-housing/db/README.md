# Postgres (Docker)

Local PostgreSQL database run via Docker Compose for this project. Use it for development, testing, or any app that needs a Postgres backend.

## Setup

Copy `.env.example` to `.env` and set values. `POSTGRES_NAME` sets the container name (e.g. in Docker Desktop). To apply a name change, run `./stop.sh` then `./start.sh` so the container is recreated.

## Usage

```bash
./start.sh   # start
./stop.sh    # stop
./reset.sh   # stop + remove data volume (fresh start)
```

## Connection

`postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB}`

## DB manager

[Beekeeper Studio](https://www.beekeeperstudio.io/)
