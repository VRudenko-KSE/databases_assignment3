# Assignment 3: Repair a Transactional Order Workflow

This individual assignment is worth **15 points**: technical correctness **6** and individual assignment defence **9**.
It opens in **Practice 14 / Week 7**, immediately after Assignment 2's full-credit deadline. Complete it locally
without another assignment's submission. One student can operate both connections for every concurrent case.

## Scenario and Goal

You inherit three short SQL scripts for reserving stock, confirming an order and cancelling a reservation.
They are deliberately defective. Find concrete failures, explain their root causes, repair the scripts and keep
regression cases that establish the required behaviour across the complete workflow.

You receive an existing schema and synthetic data. Your work is SQL and reasoning about its effects: no application,
stored function/procedure, trigger, recovery simulator or custom test runner is required or permitted as a substitute
for the assessed scripts. Plan about **8–10 hours**.
Use the P14 studio for contract reading and a first counterexample, P15 for repair feedback and P16 for replay checks.

## Supplied Local Materials

Use this standalone `assignment-3-package/`, including `compose.yaml`, fixed `sql/` data and the three flawed
`submission/` scripts. `README.md` documents setup, connection, health, reset and offline preparation.
`docs/data-dictionary.md` gives every starting value; `docs/sql-guide.md` teaches the SQL tools;
`docs/regression-guide.md` supports your own cases. Keep an untouched original package copy and edit working copies.

Start Docker, open a terminal in the extracted package and run:

```sh
docker compose up -d --wait db pgadmin
docker compose exec -T db psql -X -U student -d assignment3 -v ON_ERROR_STOP=1 -f /course-sql/health.sql
```

The first start downloads the pinned PostgreSQL/pgAdmin images and creates the bundled fixture; no host Python
or other course runtime is needed. Work in included pgAdmin (`http://127.0.0.1:55052`), DBeaver or PyCharm.
For pgAdmin use `student@course.local` / `assignment-3-pgadmin-password`, select the supplied Assignment 3 server
and use database password `assignment-3-local-password`. Host clients connect to `127.0.0.1:55434`, database
`assignment3`, user `student`, with that database password. These are local teaching credentials.

Use independent A/B connections and an idle observer O, with autocommit outside explicit transaction blocks.
Check different backend PIDs. `sql/observe.sql` inspects labelled sessions and blocking. Ordinary `psql` is optional;
all assessed SQL can run in a GUI.
Select the statements up to the stopping point and return to the holder while another connection waits.

After ending A/B transactions, reset only this assignment's data:

```sh
docker compose exec -T db psql -X -U student -d assignment3 -v ON_ERROR_STOP=1 -f /course-sql/reset.sql
```

Reset keeps saved files and constraints but removes added case data. Save its preparation SQL first.
A lock timeout requires ending the holder, rolling back any failed GUI reset transaction and rerunning the reset.
Use `docker compose stop` to stop without deleting data. For offline use pre-pull and start once while online;
later start with `docker compose up -d --wait --pull never db pgadmin`. No online API or university system is used.

## Data and Business Contract

The three tables are `products(product_id, available)`, `orders(order_id, status)` and
`order_items(order_id, product_id, quantity)`. Primary/foreign keys, nonnegative stock, positive non-null quantity
and valid non-null statuses are supplied. Each order has at most one line per product. Every initial order is draft.
Preserve these constraints; there is no hidden mechanism enforcing the complete workflow.

| Operation | Permitted Transition | Stock Effect |
| --- | --- | --- |
| Reserve | `draft → reserved`, only when every quantity is available. | Deduct all lines once; otherwise no change. |
| Confirm | `reserved → confirmed`. | Keep the reservation deduction; no additional stock change. |
| Cancel | `reserved → cancelled`. | Restore every reserved line exactly once. |

The following requirements apply to all three scripts together:

- Confirmed and cancelled states are final. A repeat makes no further stock or state change.
- A forbidden transition changes nothing and reports rejection or the existing state. Cancelling a draft cannot
  return stock or mark it cancelled; this operation cancels an existing reservation.
- An unknown order changes nothing and is identifiable as missing; an empty order cannot be reserved.
- Concurrent confirm/cancel attempts permit at most one successful terminal transition. The losing operation
  reports an outcome consistent with the winner. An aborted operation leaves no partial stock/state effect.
- Available stock never becomes negative or increases incorrectly through repeats or forbidden operations.
- Relative to an all-draft starting fixture, each product satisfies:
  **available now = initial available − quantities in reserved or confirmed orders**.
  Draft/cancelled orders contribute zero. Check this accounting or equivalent complete case-specific deltas;
  nonnegative stock alone is insufficient. A successful order consumes every requested quantity.

Order lines are immutable once a case begins. Concurrent line editing, restocking, product deletion, payment,
expiry, external writers and operational order creation are outside scope. Before a case, you may create valid
products/draft orders/lines or adjust starting stock in this isolated database; record that preparation and baseline.
No manual stock/status correction may replace an operation's correct behaviour.

## Required Work

### Discover and Explain Defects

Find at least one real bug-exposing case for each supplied script. For each, identify the violated requirement,
show the relevant initial data and execution order, capture the actual failure, and explain the causal defect.
Do not merely list SQL keywords or describe a hypothetical failure without replaying it.

### Repair the Three Operations

Submit one corrected `reserve.sql`, `confirm.sql` and `cancel.sql`. Keep ordinary multi-step SQL and explicit
transaction handling. Your SQL must enforce acceptance/rejection, including all-line reservation and repeated
requests; it cannot depend on an operator deciding to skip an otherwise unsafe write.

Use **data-modifying CTEs and RETURNING** to connect dependent writes in reserve and cancel. Returned rows must
represent an operation accepted by this execution. A direct guarded `UPDATE ... RETURNING` can suffice for
confirmation; an extra CTE there is unnecessary. Read the comments in each supplied script and the unrelated
SQL-guide example. CTE text order alone is not a sequence guarantee, and a separate read of a changed base table
within the same statement does not necessarily see the modification.

Choose and justify protection for the whole workflow. Read Committed with suitable row locks is sufficient;
other justified choices can earn full credit. A second Serializable implementation is not required. State the
isolation level and explain resource acquisition order, rejected/repeated outcomes and what must be rolled back
or retried after a database failure. Return affected-row information and inspectable current state.
After an unexpected error, roll back the entire operation before continuing; any retry repeats all decisions in
a new transaction. No automatic retry loop or procedural exception machinery is required.

### Write Your Own Regression Cases

Use `tests.sql` for executable setup/assertions and a commented execution map. Choose the data, expected results
and A/B schedules yourself. It need not launch operation files: open their canonical SQL blocks in your client.
Keep one repaired script per operation and change every marked order-ID occurrence consistently for a case.

Your suite must collectively include:

- Original and repaired replays of a bug-exposing case for each script, from equivalent clean starting states.
- Successful complete operations and an order with insufficient stock for only part of its requested products.
  Vary which product is short across partial-shortage cases while another requested product still has enough stock.
  Fixture display order does not define SQL execution order.
- Repeats of all three operations, including a second reserve whose lines still fit in the remaining stock,
  and forbidden terminal-state transitions.
- Genuinely overlapping orders competing for stock and confirm/cancel attempts on one reservation, including both
  confirm/cancel winner orders. Record statement order and the wait or competing write establishing overlap.
- A deliberate rollback after operational writes, with stock and state restored to their prior committed values.
- Executable checks for full affected stock values/accounting, order state and relevant changed-row results.
  Include positive paths: rejecting all requests cannot pass.

Several goals may share a lifecycle case; there is no fixed case count. Record expected outcomes before interpreting
results. Assertions return actual violations or explicit pass/fail values. Do not use sleeps, lucky timing or a run
where A finishes before B starts as evidence of concurrency. A normal ROLLBACK at your selected stopping point is
sufficient for the rollback case; do not crash a server or add a recovery exercise.

### Report the Investigation

Use one concise report: defect/root-cause inventory, repair rationale, case map, predictions, original/repaired
results, interleavings, assertions and failure handling. State your assumptions, isolation and what returned rows
mean. Explain lock ordering and the limits of your observations. Readable text, exports or screenshots may be
included in this report; editable SQL must accompany it. Documentation polish earns no separate marks.

## Individual Work and Collaboration

Your submitted SQL, cases, reasoning and evidence must be your own. Practice may involve pairs, and you may discuss
concepts or ask peers to interpret an error, but do not share completed repairs, finished regression cases,
submission files or captured assessment evidence. A partner's absence cannot block your work.
The course AI-use policy below applies unchanged.

## AI Tools Usage Policy

This policy covers generative AI tools, including chatbots, code generators, and other AI-driven tools. It applies to
all course activities. It supplements the current KSE academic-integrity requirements; where a university rule and
this policy differ, the current KSE rule applies.

### Allowed Uses

Students may use AI tools for:

- brainstorming ideas and approaches;
- preparing for tests or the final exam, for example by generating practice questions or requesting explanations of
  concepts;
- editing the language and structure of student-written documentation without generating its assessed technical
  reasoning, decisions, evidence, or conclusions; and
- syntax and reference questions during practical sessions and practical assignments, for example asking how to
  create an index in PostgreSQL, how to interpret a SQL construct, or how to call a stored procedure.

### Prohibited Uses

Students must not use AI tools to:

- complete a graded assignment, practical task, test, or exam in place of their own work;
- include the full assignment conditions in a prompt or ask for a complete solution;
- submit AI-generated SQL queries, database schemas, analyses, explanations, or code as their own work; or
- use AI tools in an assessment when the assessment instructions do not permit them.

### Conditions for Use

When a submission includes AI-generated content, students must clearly identify the content and provide the original
prompt or prompts used to generate it. Students remain responsible for checking the accuracy of any AI-generated
material and for being able to explain the submitted work. AI-generated content without clear disclosure is treated
as unauthorized use.

For practical assignments, disclosure is made in `AI_DISCLOSURE.md` and names the tool, date, original prompt,
affected files or passages, and how the student checked and revised the output. Asking for a syntax example, an error
explanation, or feedback on a student-written fragment can be allowed. Asking for a complete schema, query set,
analysis, decision record, or assignment is prohibited. Language editing does not permit replacement of the student's
technical reasoning with generated reasoning.

### Non-Compliance

Work completed by AI without the required disclosure will not be evaluated. Unauthorized AI use may result in a
formal warning, a grade reduction, or other consequences under the current KSE academic-integrity requirements.

## Required Submission

Submit one ZIP to the Moodle Assignment 3 activity named in the course announcement. Its root must be:

```text
assignment-3/
├── reserve.sql
├── confirm.sql
├── cancel.sql
├── tests.sql
└── report.<accepted format>
```

Google Docs, Word, Markdown and PDF reports are suitable; export Google Docs to PDF for Moodle.
`submission/report.md` is an optional outline. Include `AI_DISCLOSURE.md` when required by the policy and optional
`assets/` for included images. No separate README, evidence directory, recovery file, runtime copies or database
dumps are required. Your report's execution map must identify operation files, inputs and test blocks clearly.

Moodle's recorded timestamp is authoritative. A replacement before the applicable cutoff supersedes the earlier ZIP.
Ordinary replacement closes after the cutoff unless an approved institutional exception applies. The course
announcement supplies the exact activity, archive-size limit, technical-support route and feedback location.

## Assessment

Technical correctness is **6 points**:

| Criterion | Points | What Is Assessed |
| --- | ---: | --- |
| Reserve repair | 1.5 | Complete-order decision, stock/state coupling, repeat safety and concurrent behaviour. |
| Confirm repair | 0.5 | Guarded transitions, repeats/forbidden states and interaction with cancellation. |
| Cancel repair | 1.5 | Exactly-once restoration for accepted cancellations, preserving stock/state under overlap. |
| Student regression cases | 1.5 | Original cases; replay, positive/repeated paths, concurrency, rollback and checks. |
| Diagnosis and justification | 1 | Causal explanations and justified protection, tied to evidence. |
| **Total** | **6** | |

Meaningful CTE/RETURNING dependencies are assessed within reserve/cancel. Evidence supports these criteria; no
separate syntax, screenshot count, report layout or performance points are added. Partial credit follows independent
guarantees and root causes without repeated penalties for one defect. Staff may replay additional valid inputs
within this published contract. A supplied environment failure is recorded separately from an incorrect solution.

The **individual assignment defence is 9 points**:

- Two distinct questions selected by the TA from the bank below: **4 points**, 2 each, comprising 1 for technical
  accuracy and 1 for an explanation with a relevant example/application.
- Questions about your submitted work: **5 points** — solution understanding 2, evidence interpretation 2,
  trade-offs or a small changed condition 1.

Defend during a scheduled practical in front of a TA. You may consult your submitted files but must answer
independently without live assistance. Prepare all ten questions. Technical understanding, rather than presentation
polish, determines marks; written explanations do not replace oral answers. The TA records selected question numbers
and reasons for awarded points. No separate pass threshold applies to either component.

Pending defence, the technical score is provisional. Staff publish slots, permitted materials and make-up/missed-
defence arrangements under current university requirements. After these arrangements are exhausted, unanswered
components earn zero. A staff-scheduled defence after the deadline does not make an on-time submission late.
The late cap applies to the combined technical/defence score.

### Defence Question Bank

Questions 1–2 cover Lecture 6; 3–6 cover Lecture 7; 7–10 cover Lecture 8. Question 10 uses the lecture’s
simplified recovery model. These are oral theory questions; no LSM implementation, recovery simulation or
additional submission files are required.

1. How does an LSM tree accept an update without rewriting an existing sorted file, and what work does it
   defer?
2. How does compaction preserve current values while improving reads, and what does it cost?
3. A reservation fails after updating stock for only some of an order’s items. What must rollback undo, and
   why?
4. Two transactions both see one unit available and try to reserve it. Why can both checks pass, and how would
   you prevent overselling?
5. A reads a row twice in one transaction; between those reads B changes it and commits. How can the result
   differ between Read Committed and Repeatable Read?
6. How does a deadlock differ from an ordinary lock wait?
7. What must write-ahead logging make durable before a changed data page reaches disk, and why?
8. A client receives a successful durable `COMMIT`, then the server loses power. What should survive, and how?
9. Why are checkpoints useful when a database already has WAL, and how can they reduce recovery work?
10. In the lecture’s simplified recovery model, how do you decide whether to redo, ignore or undo a logged
    change after a crash?

## Deadlines

The assignment opens in **Practice 14 / Week 7**. Full credit is available until the published timestamp immediately
before **Practice 18 / Week 9**, retaining at least seven calendar days after Practice 16. The late cutoff is exactly
seven calendar days later in **Week 10**. On-time work can earn 15 points; late work through that cutoff can earn
at most **7.5/15**, regardless of raw score. This single cap does not halve repeatedly. After the cutoff the mark is
zero unless an approved institutional exception applies.
