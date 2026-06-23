-- ============================================================
-- 01_create_tables.sql
-- Mục đích: Khởi tạo schema cho 9 bảng của Olist E-Commerce Dataset
-- Chạy file này TRƯỚC khi load data (xem scripts/load_data.py)
-- ============================================================

-- Bảng customers: 1 dòng = 1 lượt đặt hàng của khách (KHÔNG phải 1 khách hàng duy nhất)
-- customer_unique_id mới là định danh thật của khách hàng -> dùng cột này cho RFM/segmentation
CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- Bảng products: thông tin sản phẩm (kích thước, cân nặng phục vụ tính phí ship)
CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Bảng sellers: thông tin người bán
CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- Bảng dịch tên category sang tiếng Anh (tên gốc tiếng Portuguese)
CREATE TABLE category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- Bảng geolocation: tọa độ theo zip code prefix (KHÔNG có khóa chính duy nhất,
-- 1 zip code prefix có thể có nhiều dòng lat/lng do dữ liệu thô từ nhiều nguồn)
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat NUMERIC(10,6),
    geolocation_lng NUMERIC(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- Bảng orders: 1 dòng = 1 đơn hàng. Đây là bảng trung tâm, mọi bảng order_* đều join về đây
CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) REFERENCES customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Bảng order_items: 1 đơn hàng có thể có nhiều sản phẩm (nhiều dòng)
-- Không khai báo FK tới products/sellers để tránh lỗi load do thứ tự,
-- nhưng product_id và seller_id vẫn dùng để join logic ở các bước sau
CREATE TABLE order_items (
    order_id VARCHAR(32) REFERENCES orders(order_id),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- Bảng order_payments: 1 đơn hàng có thể trả nhiều lần (payment_sequential)
CREATE TABLE order_payments (
    order_id VARCHAR(32) REFERENCES orders(order_id),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- Bảng order_reviews: đánh giá của khách cho đơn hàng (review_score: 1-5)
CREATE TABLE order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32) REFERENCES orders(order_id),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);
