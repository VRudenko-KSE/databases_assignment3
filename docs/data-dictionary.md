# Data Dictionary

All records are synthetic. Every initial order is `draft`; no stock has been consumed at reset.
Tables live in the dedicated `assignment3` database's default `public` schema.

## Tables and Constraints

| Table | Columns | Rules |
| --- | --- | --- |
| `products` | `product_id`, `available` | Integer primary key; non-null integer stock at least zero. |
| `orders` | `order_id`, `status` | Integer primary key; non-null `draft`, `reserved`, `confirmed` or `cancelled`. |
| `order_items` | `order_id`, `product_id`, `quantity` | Composite key; foreign keys; non-null quantity > 0. |

Each order has at most one line per product. During operations its lines are immutable. Stock means **available
to reserve**: reservation deducts it; confirmation keeps the deduction; cancellation restores it once.
No payment, expiry, restocking, product deletion or concurrent line editing occurs in the assessed workload.
The constraints do not enforce the complete business workflow for you.

## Starting Stock

| Product | Initial Available |
| --- | ---: |
| 1 | 5 |
| 2 | 1 |
| 3 | 8 |
| 4 | 0 |
| 5 | 12 |
| 6 | 4 |

## Starting Order Lines

All eight orders exist and are draft. Every listed quantity is requested, not an already completed deduction.

| Order | Product | Quantity |
| --- | --- | ---: |
| 101 | 1 | 3 |
| 101 | 2 | 2 |
| 102 | 1 | 3 |
| 102 | 2 | 2 |
| 103 | 3 | 2 |
| 104 | 4 | 1 |
| 105 | 1 | 1 |
| 105 | 3 | 1 |
| 105 | 5 | 2 |
| 106 | 5 | 4 |
| 106 | 6 | 1 |
| 107 | 6 | 2 |
| 108 | 3 | 1 |
| 108 | 6 | 1 |

## Case Preparation and Accounting

Before a case, you may add valid products, draft orders and lines, or change starting stock, in this isolated database.
Record the preparation SQL and initial quantities. Once the case begins, operations act on fixed order lines.
Preserve constraints and perform no manual stock/status correction between operation steps.

For every product, after completed operations:

> available now = available at the all-draft starting state − quantities in reserved or confirmed orders.

Count each order line once. Draft/cancelled orders contribute zero. A nonnegative stock check alone cannot detect
stock created by an incorrect operation. If a case begins with a valid existing reservation, record its stock/status
snapshot and check the complete expected deltas instead. Reset before comparing original and repaired operations.
