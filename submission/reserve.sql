-- Repair this operation against the published business requirements.
-- Use data-modifying CTEs (INSERT/UPDATE/DELETE inside WITH) and RETURNING
-- when a later write must depend on a write accepted by this execution.
-- Base dependent changes on returned rows, not an earlier SELECT alone.
-- A zero-row UPDATE can be a valid rejection or repeat; inspect its result.
-- A simple state-only transition may use UPDATE ... WHERE ... RETURNING
-- directly; do not add a CTE unless it serves a purpose.
-- Use ordinary SQL transactions. Do not create stored functions/procedures.
-- Find the defects and design your own before/after regression cases.
-- Input order: 101. Change every occurrence consistently for another order.
-- Supplied implementation is intentionally defective; retain an original copy.

BEGIN;

UPDATE products AS p
SET available = p.available - i.quantity
FROM order_items AS i
WHERE i.order_id = 101
  AND i.product_id = p.product_id
  AND p.available >= i.quantity;

UPDATE orders
SET status = 'reserved'
WHERE order_id = 101;

COMMIT;
