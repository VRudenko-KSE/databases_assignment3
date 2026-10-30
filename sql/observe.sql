-- Run in observer O with autocommit ON, outside a long-running transaction.
-- Label the working connections a3_A / a3_B before starting transactions.
SELECT pid, application_name, state, wait_event_type, wait_event,
       pg_blocking_pids(pid) AS blocker_pids, query
FROM pg_stat_activity
WHERE datname = current_database()
  AND application_name IN ('a3_A', 'a3_B')
ORDER BY application_name, pid;
