BEGIN;
CREATE TABLE products (
    product_id integer PRIMARY KEY,
    available integer NOT NULL CONSTRAINT available_nonnegative CHECK (available >= 0)
);
CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    status text NOT NULL CONSTRAINT valid_order_status
        CHECK (status IN ('draft', 'reserved', 'confirmed', 'cancelled'))
);
CREATE TABLE order_items (
    order_id integer NOT NULL REFERENCES orders (order_id),
    product_id integer NOT NULL REFERENCES products (product_id),
    quantity integer NOT NULL CONSTRAINT quantity_positive CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);
COMMIT;
