# Assignment 3: Repair a Transactional Order Workflow

Read [the assignment](assignment.md), then use this package to investigate and repair its three SQL operations.
Work in pgAdmin, DBeaver or PyCharm. Write SQL and your report locally; [submission/](submission/README.md)
contains the deliberately flawed operations and optional starters. Keep an untouched original copy for comparison.

## First Start

Install Docker Desktop on Windows/macOS or Docker Engine with Compose v2 on Linux. Use Linux containers.
Download or clone the assignment materials from GitHub, as for Assignment 2. If you use GitHub's **Download ZIP**,
extract it into a writable folder. Open a terminal in the folder containing `compose.yaml`.
With Docker running and internet available for the first image download:

```sh
docker compose up -d --wait db pgadmin
docker compose exec -T db psql -X -U student -d assignment3 -v ON_ERROR_STOP=1 -f /course-sql/health.sql
```

The first start creates the three tables and loads six products, eight draft orders and fourteen order lines.
Subsequent starts preserve your database. Setup uses bundled SQL; no host Python, build tool or other assignment
is needed. Use the [troubleshooting guide](docs/troubleshooting.md) for ports, older data or interrupted initialization.

## Connect and Work

Open pgAdmin at `http://127.0.0.1:55052`:

- Email: `student@course.local`
- Password: `assignment-3-pgadmin-password`
- Supplied server: **Assignment 3 PostgreSQL**; database password: `assignment-3-local-password`.

Inside Docker the server uses host `db`, port `5432`, database `assignment3`, user `student`.
For DBeaver/PyCharm use host `127.0.0.1`, port `55434`, database `assignment3`, user `student`,
password `assignment-3-local-password`.

Enable autocommit outside explicit transaction blocks. Open independent working connections A/B and an observer O.
Check different backend PIDs; separate editor tabs can otherwise share one connection. Follow the
[SQL guide](docs/sql-guide.md) for connection setup, data-modifying CTEs, `RETURNING`, waiting and error recovery.
The [data dictionary](docs/data-dictionary.md) publishes all starting data. The
[regression guide](docs/regression-guide.md) explains how to organize your own cases without a custom runner.

## Reset, Stop and Offline Use

Finish or roll back open transactions in A and B before reset. Reset replaces only this assignment's table data,
including any extra case data you added; save case preparation SQL first. It keeps your SQL/report files.

```sh
docker compose exec -T db psql -X -U student -d assignment3 -v ON_ERROR_STOP=1 -f /course-sql/reset.sql
```

You can instead open and execute `sql/reset.sql` in O. On a lock timeout, roll back the failed reset connection,
end the blocking transaction and rerun the whole reset. A failed reset does not partly reload the fixture.

Stop while preserving data:

```sh
docker compose stop
```

For offline preparation, while online first run `docker compose pull` and complete a successful first start.
Keep your local repository copy and cached images. Later startup can use:

```sh
docker compose up -d --wait --pull never db pgadmin
```

SQL and data are bundled. No online API is used during the assignment. If images are absent, obtain them online
or through the course's image-distribution route before working offline. Docker/OS installation is separate preparation.
The dataset is tiny; plan approximately 2 GB available RAM for Docker and 3 GB free disk for images/volumes.
These are planning allowances, not measured minimum hardware requirements. Common x86-64/ARM64 images are pinned;
consult the course announcement for the supported-platform validation status.
