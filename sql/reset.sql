-- End transactions in working connections before running this file.
-- Restore only the Assignment 3 fixture; keep saved files and all constraints.
BEGIN;
SET LOCAL lock_timeout = '3s';
TRUNCATE order_items, orders, products;
INSERT INTO products (product_id, available) VALUES
    (1, 5), (2, 1), (3, 8), (4, 0), (5, 12), (6, 4);
INSERT INTO orders (order_id, status) VALUES
    (101, 'draft'), (102, 'draft'), (103, 'draft'), (104, 'draft'),
    (105, 'draft'), (106, 'draft'), (107, 'draft'), (108, 'draft');
INSERT INTO order_items (order_id, product_id, quantity) VALUES
    (101, 1, 3), (101, 2, 2), (102, 1, 3), (102, 2, 2),
    (103, 3, 2), (104, 4, 1),
    (105, 1, 1), (105, 3, 1), (105, 5, 2),
    (106, 5, 4), (106, 6, 1), (107, 6, 2),
    (108, 3, 1), (108, 6, 1);
COMMIT;
SELECT 'reset complete' AS operation,
       (SELECT COUNT(*) FROM products) AS products,
       (SELECT COUNT(*) FROM orders) AS orders,
       (SELECT COUNT(*) FROM order_items) AS order_items;
