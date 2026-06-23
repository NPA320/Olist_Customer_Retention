-- ============================================================
-- 03_rfm_features.sql
-- Mục đích: Tính Recency, Frequency, Monetary cho từng khách hàng
-- (customer_unique_id), làm input cho K-Means segmentation.
--
-- Chạy: psql -U postgres -h localhost -d olist_db -f sql/03_rfm_features.sql
-- Yêu cầu: đã có bảng orders_flat từ Giai đoạn 2.
--
-- QUYẾT ĐỊNH QUAN TRỌNG: chỉ tính trên order_status = 'delivered'.
-- Lý do: Frequency/Monetary phải phản ánh hành vi mua THÀNH CÔNG thật,
-- không nên tính các đơn bị cancel/unavailable vào đây (sẽ làm méo insight
-- - vd: 1 khách spam đặt rồi hủy 5 lần không nên tính là "Frequency = 5").
-- ============================================================

DROP TABLE IF EXISTS customer_rfm;

CREATE TABLE customer_rfm AS
WITH snapshot AS (
    -- snapshot_date = ngày cuối cùng có dữ liệu + 1 ngày
    -- (+1 để tránh khách mua đúng ngày cuối có recency = 0, gây lệch log-scale sau này)
    SELECT MAX(order_purchase_timestamp)::date + INTERVAL '1 day' AS snapshot_date
    FROM orders_flat
    WHERE order_status = 'delivered'
),
delivered_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        total_price
    FROM orders_flat
    WHERE order_status = 'delivered'
)
SELECT
    d.customer_unique_id,
    EXTRACT(DAY FROM (s.snapshot_date - MAX(d.order_purchase_timestamp))) AS recency_days,
    COUNT(DISTINCT d.order_id) AS frequency,
    SUM(d.total_price) AS monetary
FROM delivered_orders d
CROSS JOIN snapshot s
GROUP BY d.customer_unique_id, s.snapshot_date;

-- Sanity check: số khách hàng unique trong customer_rfm phải khớp với
-- số khách hàng unique có ít nhất 1 đơn delivered trong orders_flat
SELECT COUNT(*) AS total_customers_in_rfm FROM customer_rfm;
