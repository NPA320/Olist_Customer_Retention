-- ============================================================
-- 04_repeat_purchase_features.sql
-- Mục đích: Xây bảng feature ở grain "1 dòng = 1 khách hàng, dựa trên
-- ĐƠN HÀNG ĐẦU TIÊN của họ", gán label = có mua lại trong 180 ngày không.
--
-- Chạy: psql -U postgres -h localhost -d olist_db -f sql/04_repeat_purchase_features.sql
-- Yêu cầu: đã có bảng orders_flat từ Giai đoạn 2.
--
-- 2 QUYẾT ĐỊNH QUAN TRỌNG (đọc kỹ trước khi dùng bảng này cho model):
--
-- 1) CHỈ dùng feature từ ĐƠN HÀNG ĐẦU TIÊN (first_order), không dùng
--    bất kỳ thông tin nào tổng hợp từ toàn bộ lịch sử mua của khách
--    -> tránh data leakage (lộ luôn câu trả lời cho model).
--
-- 2) CHỈ giữ khách có ĐỦ 180 NGÀY quan sát kể từ lần mua đầu tới ngày
--    cuối cùng có data trong dataset -> tránh right-censoring (khách
--    mua gần cuối dataset chưa có đủ thời gian để "được tính" là repeat,
--    nếu không loại sẽ làm model học sai - tưởng họ "không bao giờ
--    mua lại" trong khi thực ra chỉ là chưa đủ thời gian).
-- ============================================================

-- ============================================================
-- 04_repeat_purchase_features.sql
-- ============================================================

-- BƯỚC 1: Tạo Index trước để tối ưu hóa truy vấn phía dưới
CREATE INDEX IF NOT EXISTS idx_orders_flat_cust_date 
ON orders_flat(customer_unique_id, order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_flat_status 
ON orders_flat(order_status);

-- BƯỚC 2: Xóa bảng cũ nếu tồn tại
DROP TABLE IF EXISTS repeat_purchase_features;

-- BƯỚC 3: Tạo bảng mới và tính toán Features
CREATE TABLE repeat_purchase_features AS
WITH delivered AS (
    SELECT * FROM orders_flat WHERE order_status = 'delivered'
),

-- Xác định đơn hàng đầu tiên (delivered) của mỗi khách
first_orders AS (
    SELECT
        customer_unique_id,
        order_id AS first_order_id,
        order_purchase_timestamp AS first_purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp ASC
        ) AS order_rank
    FROM delivered
),
first_order_only AS (
    SELECT customer_unique_id, first_order_id, first_purchase_date
    FROM first_orders
    WHERE order_rank = 1
),

-- Ngày cuối cùng có data, dùng để loại các khách chưa đủ thời gian quan sát
bounds AS (
    SELECT MAX(order_purchase_timestamp) AS max_date FROM delivered
),

-- Gán label: có đơn delivered thứ 2 trong vòng 180 ngày sau đơn đầu không
labeled AS (
    SELECT
        fo.customer_unique_id,
        fo.first_order_id,
        fo.first_purchase_date,
        CASE WHEN EXISTS (
            SELECT 1
            FROM delivered d2
            WHERE d2.customer_unique_id = fo.customer_unique_id
              AND d2.order_purchase_timestamp > fo.first_purchase_date
              AND d2.order_purchase_timestamp <= fo.first_purchase_date + INTERVAL '180 days'
        ) THEN 1 ELSE 0 END AS repeat_within_180d
    FROM first_order_only fo
    CROSS JOIN bounds b
    -- Điều kiện chống censoring: chỉ giữ khách mua lần đầu đủ sớm
    -- để có trọn 180 ngày quan sát trước khi dataset kết thúc
    WHERE fo.first_purchase_date <= b.max_date - INTERVAL '180 days'
)

SELECT
    l.customer_unique_id,
    l.first_order_id,
    l.first_purchase_date,
    EXTRACT(MONTH FROM l.first_purchase_date) AS purchase_month,
    EXTRACT(DOW FROM l.first_purchase_date) AS purchase_dow,   -- 0=Sunday
    o.customer_state,
    o.item_count,
    o.distinct_product_count,
    o.total_price,
    o.total_freight,
    o.primary_category,
    o.primary_payment_type,
    o.total_installments,
    o.delivery_days,
    o.is_late_delivery,
    o.review_score,                -- NULL nếu khách không review đơn đầu - xử lý ở Python
    l.repeat_within_180d           -- TARGET
FROM labeled l
JOIN orders_flat o ON l.first_order_id = o.order_id;

-- BƯỚC 4: Kiểm tra tỷ lệ class
SELECT
    repeat_within_180d,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM repeat_purchase_features
GROUP BY repeat_within_180d;