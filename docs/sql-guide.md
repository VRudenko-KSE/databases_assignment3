# SQL Guide

## Connections and Statement Boundaries

Enable autocommit for statements outside explicit `BEGIN`/`COMMIT` blocks. Disable client options that silently
roll back only a failed statement or automatically retry it: those can change the transaction you intended to test.
Select the statements up to the stopping point, not every open script together.
Keep A/B open across manual stopping points.

In A, before a transaction:

```sql
SET application_name = 'a3_A';
SET timezone = 'UTC';
SELECT current_database(), pg_backend_pid();
SHOW transaction_isolation;
```

In B use `a3_B`. Verify different PIDs. Open O independently with autocommit ON and execute `sql/observe.sql` there.
In pgAdmin, create separate Query Tool connections for A/B/O; in DBeaver or PyCharm explicitly use separate sessions
and verify the PIDs. Do not rely on editor-tab appearance. While B waits, switch to A to finish its transaction.
Select only the intended block; some clients execute a whole file when no selection is active.

## Conditional Writes and RETURNING

An `UPDATE` affecting zero rows is normally successful SQL. It may mean a predicate rejected the operation, the
target is missing or the intended change already happened. Interpret the returned rows together with current state.
`RETURNING` reports rows actually changed by that invocation; a previous successful state is a different fact.

Use meaningful data-modifying CTEs and `RETURNING` in your reserve/cancel repair when writes depend on another
accepted write. A direct guarded `UPDATE ... RETURNING` can suffice for a state-only operation. Do not create
stored functions, procedures or triggers.

## From a Manual Decision to a Guarded Write

Practice 13 asked you to inspect a fresh count and omit a prohibited write. In this assignment, the SQL itself
must enforce acceptance or rejection. Use this short, unrelated rehearsal during P14 launch support if that
step is unfamiliar. It adds no submission or evidence requirement.

An editorial article may be published only if it has been reviewed and is not already published. Replace `TRUE`
in all three marked predicates with the same eligibility condition. Execute every UPDATE, including the rejected
attempts; do not skip a statement based on an earlier SELECT. Predict the returned rows before running it.

Run the whole example in an idle connection. Its temporary tables are private to that connection.

<!-- runnable-bridge -->

```sql
BEGIN;
CREATE TEMP TABLE a3_guide_articles (
    article_id integer PRIMARY KEY,
    reviewed boolean NOT NULL,
    published boolean NOT NULL
);
INSERT INTO a3_guide_articles VALUES (7, true, false), (8, false, false);

-- Attempt to publish a reviewed article.
UPDATE a3_guide_articles SET published = true
WHERE article_id = 7 AND /* TODO: SQL eligibility condition */ TRUE
RETURNING article_id, published;

-- Attempt to publish an unreviewed article.
UPDATE a3_guide_articles SET published = true
WHERE article_id = 8 AND /* TODO: SQL eligibility condition */ TRUE
RETURNING article_id, published;

-- Repeat the first request.
UPDATE a3_guide_articles SET published = true
WHERE article_id = 7 AND /* TODO: SQL eligibility condition */ TRUE
RETURNING article_id, published;

SELECT article_id, reviewed, published FROM a3_guide_articles ORDER BY article_id;
ROLLBACK;
```

After your repair, only the first UPDATE returns a row: `7, true`. The other two return zero rows.
Before rollback, article 7 is reviewed/published and article 8 is unreviewed/unpublished. Explain which predicate
rejects each unsuccessful attempt and why zero returned rows are a normal outcome. The supplied `TRUE` does not
enforce either rule. This is a predicate exercise; shared-data decisions still need justified concurrency protection.

## A Data-Modifying CTE Example

This unrelated editorial-note example is independent of the assignment tables. Run it as one example in an idle
connection. It publishes pending note IDs to a second table. The second invocation adds nothing.

<!-- runnable-example -->

```sql
BEGIN;
CREATE TEMP TABLE a3_guide_notes (
    note_id integer PRIMARY KEY,
    published boolean NOT NULL
);
CREATE TEMP TABLE a3_guide_publications (note_id integer PRIMARY KEY);
INSERT INTO a3_guide_notes VALUES (7, false), (8, false);

WITH newly_published AS (
    UPDATE a3_guide_notes
    SET published = true
    WHERE NOT published
    RETURNING note_id
), copied AS (
    INSERT INTO a3_guide_publications (note_id)
    SELECT note_id FROM newly_published
    RETURNING note_id
)
SELECT COUNT(*) AS added_now FROM copied;

WITH newly_published AS (
    UPDATE a3_guide_notes
    SET published = true
    WHERE NOT published
    RETURNING note_id
), copied AS (
    INSERT INTO a3_guide_publications (note_id)
    SELECT note_id FROM newly_published
    RETURNING note_id
)
SELECT COUNT(*) AS added_now FROM copied;

SELECT COUNT(*) AS total_publications FROM a3_guide_publications;
ROLLBACK;
```

Expected results are `2`, `0`, `2`. Rollback removes the temporary example's changes and objects.

```sql
-- RETURNING exposes rows actually changed by this statement.
-- Use that output to connect the accepted operation to dependent writes.
-- CTE text order does not establish a procedural execution sequence.
-- Communicate changes through RETURNING rather than re-reading a changed
-- base table in the same statement and assuming its new state is visible.
```

Data-modifying CTEs share a statement snapshot. A CTE that writes can still run even when its output is not used.
Check every write and its dependencies; merely placing several writes in `WITH` is not a correctness guarantee.
The example teaches syntax and returned-row relationships; you must design the order workflow's predicates,
protection and regression cases yourself.

## Locks, Snapshots and Failure

`SELECT ... FOR UPDATE` locks returned rows until transaction end. Ordinary reads alone do not reserve a resource.
At Read Committed, a subsequent statement gets a fresh view of data committed before that statement starts.
A lock and an earlier observation are different things: explain when your decision is made relative to waiting.
When locking several resources, justify one consistent acquisition order across operations.

In a waiting experiment, observe the waiter/blocker from O before releasing the holder. Keep the observation
outside a long observer transaction. A deliberate pause between SQL statements is a test barrier, not a production
design. Do not use sleeps or a run where A finishes before B begins as evidence of overlap.

After an unexpected SQL error, issue `ROLLBACK;` in the affected connection before continuing. After a deadlock
(`40P01`) or serialization failure (`40001`), any retry repeats the complete operation in a new transaction.
Do not retry a forbidden business transition blindly. An expected no-change result need not be an SQL error.

## Saving Evidence

Save edited SQL as text. In pgAdmin copy the relevant Data Output and Messages; export a grid through its save
action if useful. In DBeaver/PyCharm use the result export and console/error output. Include readable snippets or
screenshots in the report with case/session labels. Preserve changed-row results, final stock/status and waits.
Successful `RETURNING` output is provisional until commit; rollback can cancel the displayed write.

See PostgreSQL 18 documentation for [RETURNING](https://www.postgresql.org/docs/18/dml-returning.html),
[data-modifying CTEs](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-MODIFYING),
[isolation](https://www.postgresql.org/docs/18/transaction-iso.html) and
[locks](https://www.postgresql.org/docs/18/explicit-locking.html).
