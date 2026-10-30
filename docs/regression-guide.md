# Regression Guide

Your cases are part of the assessed work. Choose their data, expected outcomes and execution schedules yourself.
The brief supplies the coverage contract, not a completed bug checklist or answer set.

## Build a Replayable Case

1. Give the case a name and state the business rule it checks.
2. Reset and execute your preparation SQL; record the initial stock, order states and fixed lines.
3. Write the expected complete outcome before interpreting the run.
4. In the SQL client run the named operation file using the case's order ID. Change every marked occurrence
   consistently. For concurrent work specify A/B blocks, stopping points and commit/rollback order.
5. Run your assertion queries and retain their observed result. Check all affected products and order state.
6. For a discovered defect, repeat against the repaired operation from an equivalent clean starting state.
   Explain why the original fails and how the repair prevents that failure.

Use `tests.sql` for executable preparation/assertions plus comments mapping each case to canonical operation files.
The file does not need to launch those files. Run them manually in the client. Keep one canonical repair per operation;
do not paste separate versions into every case. You may mark a stopping point and select the statements up to it.
Several business requirements can share a lifecycle case. There is no prescribed number of cases.

## Assertions and Coverage

Return actual violating rows or an explicit Boolean result; a comment saying “passed” is not an assertion.
Compare exact expected quantities, complete stock accounting and the permitted state. A check that only tests
nonnegative stock can miss incorrect increases. Include successful positive paths: rejecting every request fails.

A repeated reserve shows that a second call is safe only when every requested line still fits in the stock
left by the first successful call. Repeating an order that is already short after the first call does not
show that. Across partial-shortage cases, vary which product is short while another requested product remains
feasible. These are checks over a set of order lines; fixture display order does not define SQL execution order.
A defective script may commit successfully; an SQL error is not required for a case to count as a failure.

In addition to a counterexample for each original script, cover partial stock shortage, repeats of all operations,
forbidden final-state transitions, competing stock requests, both confirm/cancel winner orders and rollback after
writes. The fixture and exact interleavings remain your choices. Document observer evidence or the relevant
competing statements that establish real overlap; fixed waits and sequential replay cannot establish it.

The optional coverage table in `submission/report.md` can map requirements to your own cases and results.
One case may cover several requirements. The table is a planning aid, not another assessed deliverable.

## Case Preparation Boundaries

Use only the dedicated assignment database. You may add valid products/draft orders/lines and change starting stock
before a case, recording its baseline. Keep constraints and immutable lines during operations. No manual stock/status
correction can stand in for a repaired operation. A normal `ROLLBACK` at your chosen stopping point is enough for
the rollback case; no injected error, server crash, stored routine or custom test framework is needed.

When reset waits or fails, end A/B transactions and roll back the reset connection before rerunning it.
Do not repair an old case's damaged state by guessing quantities and then call it a clean replay.
