# Troubleshooting

## Ports and Independent Copies

Stop a conflicting service or create a local `.env` beside `compose.yaml` with different ports, for example:

```text
POSTGRES_PORT=55534
PGADMIN_PORT=55152
```

Use those host ports in the client/browser. Inside Docker pgAdmin still uses `db:5432`.
For two separate extracted copies also use a distinct Compose project name, such as
`docker compose -p assignment3-second up -d --wait`; keep `-p assignment3-second` on every later command for that copy.
Do not mix volumes/commands between projects. Defaults bind services to loopback.

## Passwords and Initialization

PostgreSQL initializes an empty volume only once. Changing `POSTGRES_PASSWORD` in `.env` does not change the
password of an existing database user. Keep the default teaching passwords unless you also update the database
and client configuration deliberately. These credentials are for a disposable local teaching database.

If initialization was interrupted, inspect `docker compose logs db`. Save local work first. For a deliberate
complete rebuild of **this package only**, stop its containers, then run `docker compose down --volumes` and the
README start command. That deletes this project's database and pgAdmin settings. Do not use a global Docker prune
or delete another course project's volume. Ordinary case reset uses `sql/reset.sql` and keeps the services.

## Waiting, Errors and Stale Transactions

Two tabs can share one connection. Check `pg_backend_pid()` in both. Set labels before BEGIN and run
`sql/observe.sql` from an independent idle O connection. If B is waiting, A often needs commit or rollback.
Do not launch reset while A/B retain locks. Reset uses a three-second lock timeout and rolls back as one operation
on failure; issue ROLLBACK in a GUI reset connection, end the holder and rerun the whole reset.

If a query was accidentally left waiting, use that client's cancel-query action, then issue ROLLBACK in that
connection. A client cancellation, statement timeout and detected deadlock are different observations.
After “current transaction is aborted,” finish it with ROLLBACK rather than submitting more business writes.

## Images and Platform Limits

The first startup needs the two pinned images. Download them before offline work; later `--pull never` refuses
missing images instead of trying a download. Keep the entire package, including SQL and pgAdmin configuration.
Docker Compose is the documented route; Podman Compose compatibility is not yet independently validated.
Use the course support route for unsupported engines or platform-specific failures, preserving the error message.
