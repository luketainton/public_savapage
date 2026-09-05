# SavaPage with Docker Compose

This repository builds and runs SavaPage with CUPS and PostgreSQL using Docker Compose.

The published image is built in CI from the official SavaPage x86_64 installer. SavaPage does not provide an official Docker image. This follows the [official SavaPage Docker guide](https://wiki.savapage.org/doku.php?id=howto%3Adocker).

## Requirements

- Docker Engine with the Compose plugin
- An amd64/x86_64 host, or Docker emulation for amd64

## Configure

```bash
cp .env.example .env
chmod 600 .env
```

Edit `.env` and set the database name, username, and a strong `POSTGRES_PASSWORD` if the defaults are not suitable. The same `POSTGRES_DB` and `POSTGRES_USER` values are used by PostgreSQL and SavaPage. Do not commit `.env`.

## Build and start

```bash
docker compose pull
docker compose config
docker compose up -d
docker compose ps
docker compose logs -f app
```

The Compose deployment always pulls the published `latest` image. The SavaPage version is selected by the repository release process and is not a runtime setting.

## First login

Open `https://localhost:8632/admin`. The initial credentials are `admin` / `admin`; change the password immediately and complete the setup in the Admin Web App.

CUPS is available at `http://localhost:631/printers/`. Add and test printer queues in CUPS before configuring them as SavaPage proxy printers.

## Persistence and backups

Bind-mounted directories persist application data, CUPS configuration, logs, and PostgreSQL data:

```text
./savapage/custom
./savapage/data
./savapage/ext
./savapage/logs
./savapage/cups
./db
```

Back up these directories, especially the SavaPage data directory containing:

```text
/opt/savapage/server/data/encryption.properties
```

That file contains keys required to decrypt database secrets and verify document signatures. CUPS is configured with `--remote-any` inside the container, so restrict or firewall the published CUPS port in production.

## Stop and upgrade

```bash
docker compose down
```

To upgrade, pull the new published image:

```bash
docker compose pull
docker compose up -d
```

Back up the bind-mounted directories first and consult the SavaPage release notes for database migrations. Tagged releases download and verify the installer automatically in CI.

Do not use `docker compose down -v` unless you intentionally want to remove the persistent application and database volumes.
