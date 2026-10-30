-- Read-only connection/schema check. Operational changes can alter values/counts.
SELECT current_database() AS database_name, current_user AS connected_user,
       current_setting('server_version') AS postgres_version;
SELECT (SELECT COUNT(*) FROM products) AS products,
       (SELECT COUNT(*) FROM orders) AS orders,
       (SELECT COUNT(*) FROM order_items) AS order_items;
SELECT product_id, available FROM products ORDER BY product_id;
SELECT order_id, status FROM orders ORDER BY order_id;
