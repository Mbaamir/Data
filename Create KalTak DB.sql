CREATE TABLE
    country (
        country_code SMALLINT PRIMARY KEY,
        name VARCHAR(255) UNIQUE
    );

CREATE TABLE
    state (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        country_name VARCHAR(255) REFERENCES country (name)
    );

CREATE TABLE
    city (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        state_id INT REFERENCES state (id)
    );

CREATE TABLE
    postal_code (
        postal_code INT PRIMARY KEY,
        name VARCHAR(255) NOT NULL
    );

CREATE EXTENSION IF NOT EXISTS citext;

DROP DOMAIN IF EXISTS EMAIL;
CREATE DOMAIN EMAIL AS citext  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );
CREATE TABLE
    customer (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        email EMAIL NOT NULL,
        auth TEXT NOT NULL
    );

-- WE ARE NOT USING A COMPOSITE PRIMARY KEY AS IT REQUIRES MORE STORAGE TO REFERENCE
CREATE TABLE
    customer_phone_number (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        country_code SMALLINT  REFERENCES country (country_code),
        phone_number BIGINT NOT NULL,
        UNIQUE (country_code, phone_number),
        customer_id BIGINT REFERENCES customer (id) NOT NULL,
        is_primary BOOLEAN NOT NULL
    );

CREATE UNIQUE INDEX one_primary_phone_c ON customer_phone_number (customer_id)
WHERE
    is_primary = TRUE;

CREATE TABLE
    address (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        address_line_one VARCHAR(255) NOT NULL,
        address_line_two VARCHAR(255) NOT NULL,
        city_id INT REFERENCES city (id) NOT NULL,
        postal_code INT REFERENCES postal_code (postal_code)
    );

-- HOME/OFFICE/OTHER
CREATE TABLE
    address_type (name VARCHAR(255) PRIMARY KEY);

CREATE TABLE
    customer_address (
        customer_id BIGINT REFERENCES customer (id),
        address_id BIGINT REFERENCES address (id),
        is_default BOOLEAN NOT NULL,
        is_archived BOOLEAN NOT NULL DEFAULT FALSE,
        address_type VARCHAR(255) REFERENCES address_type (name) NOT NULL,
        PRIMARY KEY (customer_id, address_id)
    );

CREATE UNIQUE INDEX one_default_address on customer_address (customer_id)
WHERE
    is_default = TRUE;

CREATE TABLE
    supplier (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        email EMAIL UNIQUE NOT NULL,
        city_id INT REFERENCES city (id) NOT NULL 
    );

-- WE ARE NOT USING A COMPOSITE PRIMARY KEY AS IT REQUIRES MORE STORAGE TO REFERENCE
CREATE TABLE
    supplier_phone_number (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        country_code SMALLINT  REFERENCES country (country_code),
        phone_number BIGINT NOT NULL,
        UNIQUE (country_code, phone_number),
        supplier_id BIGINT REFERENCES supplier (id) NOT NULL,
        is_primary BOOLEAN NOT NULL
    );

CREATE UNIQUE INDEX one_primary_phone_s ON supplier_phone_number (supplier_id)
WHERE
    is_primary = TRUE;

-- Placeholder for category table
CREATE TABLE
    category (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL
        -- Additional columns can be added here as needed
    );

CREATE TABLE
    product (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        supplier_id BIGINT REFERENCES supplier (id) NOT NULL,
        category_id INT REFERENCES category (id) NOT NULL
    );

-- MONEY IS IN PAISAS REPRESENTED BY BIGINT
CREATE TABLE
    variation (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        product_id BIGINT REFERENCES product (id) NOT NULL,
        cost BIGINT NOT NULL check (cost > 0)
    );

CREATE TABLE
    variation_image (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        uri TEXT NOT NULL,
        position NUMERIC(1, 0) NOT NULL CHECK (position BETWEEN 1 AND 6),
        variation_id BIGINT REFERENCES variation (id),
        UNIQUE (variation_id, position)
    );

CREATE TABLE
    cart (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        customer_id BIGINT REFERENCES customer (id)
    );

CREATE TABLE
    cart_item (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        qty INT NOT NULL CHECK (qty > 0),
        cart_id BIGINT REFERENCES cart (id),
        product_id BIGINT REFERENCES product (id)
    );

-- Placeholder for payment table
CREATE TABLE
    payment (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        details TEXT NOT NULL -- Placeholder details column
        -- Additional columns can be added here as needed
    );

CREATE TABLE
    discount (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        code VARCHAR(255) UNIQUE NOT NULL,
        percentage NUMERIC(4, 2),
        flat BIGINT CHECK (flat > 0),
        CHECK (
            (
                percentage is NULL
                OR flat is NULL
            )
            AND NOT (
                percentage is NULL
                AND flat is NULL
            )
        )
    );

-- STATUS SUCH AS PENDING, COMPLETED, ETC
CREATE TABLE
    order_status (
        id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        status VARCHAR(255) NOT NULL
        -- Additional columns can be added here as needed
    );

CREATE TABLE
    placed_order (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        customer_id BIGINT REFERENCES customer (id) NOT NULL,
        payment_id BIGINT REFERENCES payment (id),
        date_placed TIMESTAMPTZ NOT NULL,
        date_completed TIMESTAMPTZ,
        shipping_address_id BIGINT REFERENCES address (id) NOT NULL,
        billing_address_id BIGINT REFERENCES address (id) NOT NULL,
        order_status_id SMALLINT REFERENCES order_status (id) NOT NULL,
        discount_id BIGINT REFERENCES discount (id)
    );

CREATE TABLE
    order_item (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        order_id BIGINT REFERENCES placed_order (id),
        variation_id BIGINT REFERENCES variation (id),
        qty INT NOT NULL CHECK (qty > 0)
    );

CREATE TABLE
    review (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        order_item_id BIGINT REFERENCES order_item (id),
        stars NUMERIC(1, 0) NOT NULL CHECK (stars BETWEEN 1 AND 5),
        text TEXT NOT NULL
    );

CREATE TABLE
    review_image (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        uri TEXT NOT NULL,
        position NUMERIC(1, 0) NOT NULL CHECK (position BETWEEN 1 AND 6),
        review_id BIGINT REFERENCES review (id),
        UNIQUE (review_id, position)
    );

CREATE TABLE
    consultation_status (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        status VARCHAR(255) NOT NULL -- Placeholder status column
        -- Additional columns can be added here as needed
    );

CREATE TABLE
    consultation (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        customer_id BIGINT REFERENCES customer (id),
        supplier_id BIGINT REFERENCES supplier (id),
        consultation_date_time TIMESTAMPTZ NOT NULL,
        consultation_status_id BIGINT REFERENCES consultation_status (id) NOT NULL,
        order_id INT REFERENCES placed_order (id)
    );

-- Placeholder for consultation_item table
CREATE TABLE
    consultation_item (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        consultation_id BIGINT REFERENCES consultation (id) NOT NULL,
        variation_id BIGINT REFERENCES variation (id) NOT NULL
        -- Additional columns can be added here as needed
    );

-- Placeholder for delivery table
CREATE TABLE
    delivery (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        order_item_id BIGINT REFERENCES order_item (id) NOT NULL,
        delivery_details TEXT NOT NULL
        -- Additional columns can be added here as needed
    );