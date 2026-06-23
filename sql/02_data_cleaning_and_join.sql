-- ============================================================
-- 02_data_cleaning_and_join.sql
-- Mục đích: Chuẩn hóa order_items/order_payments/order_reviews về
-- grain "1 dòng = 1 order_id", sau đó join tất cả thành 1 bảng phẳng
-- orders_flat để phục vụ EDA, RFM, và model ở các giai đoạn sau.
--
-- Chạy: psql -U postgres -h localhost -d olist_db -f sql/02_data_cleaning_and_join.sql
-- Yêu cầu: đã load đủ 9 bảng raw ở Giai đoạn 1.
-- ============================================================


-- ------------------------------------------------------------
-- VIEW 1: order_items_enriched
-- Gắn category (đã dịch tiếng Anh) cho từng order_item, và xếp hạng
-- theo giá trong order để xác định "category chính" của đơn hàng
-- (đơn có nhiều sản phẩm khác category nhau -> lấy category của
-- sản phẩm có giá cao nhất làm đại diện)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW order_items_enriched AS
SELECT
    oi.order_id,
    oi.product_id,
    oi.price,
    oi.freight_value,
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category_english,
    ROW_NUMBER() OVER (PARTITION BY oi.order_id ORDER BY oi.price DESC) AS price_rank
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name;


-- ------------------------------------------------------------
-- VIEW 2: order_items_agg
-- Gộp order_items về grain order_id: tổng giá trị, số lượng item,
-- số sản phẩm khác nhau, và category chính của đơn
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW order_items_agg AS
SELECT
    order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT product_id) AS distinct_product_count,
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight,
    MAX(CASE WHEN price_rank = 1 THEN category_english END) AS primary_category
FROM order_items_enriched
GROUP BY order_id;


-- ------------------------------------------------------------
-- VIEW 3: order_payments_agg
-- Gộp order_payments về grain order_id: tổng tiền đã trả (1 đơn có
-- thể trả nhiều lần/nhiều phương thức), và phương thức thanh toán
-- có giá trị cao nhất (đại diện cho đơn)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW order_payments_agg AS
SELECT
    order_id,
    SUM(payment_value) AS total_payment_value,
    SUM(payment_installments) AS total_installments,
    (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1] AS primary_payment_type
FROM order_payments
GROUP BY order_id;


-- ------------------------------------------------------------
-- VIEW 4: order_reviews_dedup
-- Xử lý các order_id có nhiều hơn 1 review: giữ lại review MỚI NHẤT
-- theo review_creation_date (DISTINCT ON là cú pháp đặc trưng của
-- Postgres - giữ 1 dòng đầu tiên sau khi ORDER BY cho mỗi order_id)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW order_reviews_dedup AS
SELECT DISTINCT ON (order_id)
    order_id,
    review_score,
    review_creation_date
FROM order_reviews
ORDER BY order_id, review_creation_date DESC;


-- ------------------------------------------------------------
-- BẢNG CHÍNH: orders_flat
-- Grain: 1 dòng = 1 order_id. Đây là bảng nền cho mọi phân tích
-- ở các giai đoạn sau (EDA, RFM, model).
--
-- Dùng LEFT JOIN cho order_items_agg/order_payments_agg/order_reviews_dedup
-- vì KHÔNG phải đơn nào cũng có review (khách không review),
-- và để không vô tình làm mất các order hợp lệ nếu có thiếu dữ liệu phụ.
-- JOIN (không LEFT) với customers vì mọi order PHẢI có customer_id hợp lệ
-- (đã ràng buộc bởi FK lúc tạo schema).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS orders_flat;

CREATE TABLE orders_flat AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Số ngày giao hàng thực tế (NULL nếu chưa giao xong)
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
        ELSE NULL
    END AS delivery_days,

    -- Giao trễ so với ngày ước tính hay không (NULL nếu chưa giao)
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        ELSE NULL
    END AS is_late_delivery,

    oi.item_count,
    oi.distinct_product_count,
    oi.total_price,
    oi.total_freight,
    oi.primary_category,

    op.total_payment_value,
    op.primary_payment_type,
    op.total_installments,

    r.review_score

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
LEFT JOIN order_payments_agg op ON o.order_id = op.order_id
LEFT JOIN order_reviews_dedup r ON o.order_id = r.order_id;


-- ------------------------------------------------------------
-- Index để các query ở giai đoạn sau (group theo khách hàng) chạy nhanh hơn
-- ------------------------------------------------------------
CREATE INDEX idx_orders_flat_customer ON orders_flat(customer_unique_id);
CREATE INDEX idx_orders_flat_purchase_date ON orders_flat(order_purchase_timestamp);
