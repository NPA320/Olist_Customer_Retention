# Olist Customer Retention & Repeat-Purchase Analysis — Final Summary

## 1. Business Question

Olist (nền tảng marketplace lớn tại Brazil) có tỷ lệ khách hàng mua lại
(repeat purchase) rất thấp. Câu hỏi kinh doanh đặt ra:

- Khách hàng nào có khả năng quay lại mua tiếp, và nhóm nào nên được
  ưu tiên đầu tư retention marketing?
- Đặc điểm nào của lần mua đầu tiên (nếu có) giúp dự đoán khả năng quay lại?
- Ngân sách retention hạn chế nên phân bổ ra sao để tối ưu ROI?

## 2. Approach

1. **Data Engineering**: Load 9 bảng raw (~100K đơn hàng, ~99K khách hàng)
   vào PostgreSQL, xử lý cleaning (dedup review, gộp multi-payment, xử lý
   category thiếu) và join thành 1 bảng phẳng `orders_flat` ở grain
   "1 dòng = 1 đơn hàng", phân biệt đúng `customer_id` (theo đơn) và
   `customer_unique_id` (theo khách hàng thật).
2. **EDA**: phân tích phân phối order status, vùng địa lý, category,
   review score, hiệu suất giao hàng — xác nhận insight trung tâm: tỷ lệ
   mua lại cực thấp (~3%).
3. **Customer Segmentation**: tính RFM theo `customer_unique_id`, áp
   K-Means (k=4), gán tên segment theo ý nghĩa kinh doanh.
4. **Predictive Modeling**: định nghĩa lại bài toán "churn" thành **dự
   đoán khả năng mua lại trong 180 ngày** dựa trên đặc điểm đơn hàng đầu
   tiên — kiểm soát chặt data leakage (chỉ dùng feature từ đơn đầu) và
   right-censoring (loại khách chưa đủ thời gian quan sát). Train Random
   Forest và XGBoost, đánh giá bằng ROC-AUC/PR-AUC/lift do data mất cân
   bằng nặng (~2.8% positive), xác nhận qua tuning rằng giới hạn nằm ở
   feature set, không phải do model chưa tối ưu.
5. **Cohort Retention Analysis**: dựng heatmap retention theo tháng,
   xử lý đúng censoring và hiện tượng "same-month repeat", đối chiếu chéo
   kết quả với model ở bước 4.
6. **Dashboard (Power BI)**: đang triển khai (Giai đoạn 7).

## 3. Key Findings

**3.1 — Tỷ lệ mua lại cực thấp, được xác nhận độc lập bằng 2 phương pháp**
Model-based (window 180 ngày chính xác): ~2.8%. Cohort-based (lưới
tháng, đã hiệu chỉnh same-month repeat): ~3.31%. Hai số liệu nhất quán
trong khoảng dung sai hợp lý — đây là đặc điểm cấu trúc thật của hành vi
khách hàng trên Olist, không phải lỗi dữ liệu.

**3.2 — 4 segment khách hàng rõ rệt (RFM + K-Means)**

| Segment | % khách hàng | Số lượng | Recency (ngày) | Frequency | Monetary (R$) |
|---|---|---|---|---|---|
| Repeat Buyers | 3.0% | 2,801 | 219.8 | 2.1 | 260.1 |
| High-Value One-Timers | 34.6% | 32,340 | 160.9 | 1.0 | 251.5 |
| Low-Value Newcomers | 33.1% | 30,895 | 153.4 | 1.0 | 44.5 |
| Lapsed / At-Risk | 29.3% | 27,322 | 425.0 | 1.0 | 109.3 |

Segment **High-Value One-Timers** đáng chú ý nhất: lớn nhất, giá trị đơn
cao tương đương nhóm Repeat Buyers, mới mua gần đây, nhưng chưa từng quay
lại — đây là nhóm có ROI tiềm năng cao nhất cho retention marketing.

**3.3 — Model dự đoán repeat-purchase có sức phân biệt yếu nhưng vẫn tạo
lift có ứng dụng thực tế**
ROC-AUC ~0.58, PR-AUC ~0.04 (cả Random Forest và XGBoost, kể cả sau khi
tuning hyperparameter bằng RandomizedSearchCV — xác nhận giới hạn nằm ở
feature set, không phải do tuning chưa đủ). Tuy nhiên, top 20% khách
theo xác suất dự đoán có tỷ lệ mua lại thật cao hơn baseline ~1.44x,
trong khi bottom 10% thấp hơn baseline ~44% — đủ để áp dụng target
marketing chọn lọc dù không đủ mạnh để phân loại chi tiết toàn bộ tập.

**3.4 — Feature importance khá đồng đều, không có yếu tố áp đảo**
Top feature (category sản phẩm, số lượng item, độ đa dạng sản phẩm) có
importance gần nhau (0.03-0.045) — gợi ý rằng đặc điểm giao dịch tĩnh
không phải yếu tố quyết định chính; trải nghiệm hậu mua hàng và các
touchpoint marketing (không có trong dataset) nhiều khả năng ảnh hưởng
lớn hơn.

**3.5**
- % đơn delivered / canceled: 97.02% / 0.63%
- State chiếm tỷ trọng cao nhất và mức độ tập trung địa lý: SP (42.0%)
- Top 3 category: bed_bath_table, health_beauty, sports_leisure
- % review score 5 / 1 (phân phối lệch 2 cực): ~57% / ~11.5%
- % đơn giao trễ, median delivery days: 8.11%, 7 ngày

## 4. Recommendations

1. **Ưu tiên ngân sách retention cho segment "High-Value One-Timers"**
   (34.6% khách hàng, giá trị đơn cao, mới mua gần đây) — đây là nhóm có
   ROI cao nhất để chuyển đổi thành khách hàng quay lại.
2. **Dùng model dưới dạng ranking, không dùng threshold cố định**: áp
   dụng chiến lược target top 20% theo xác suất dự đoán trong nội bộ
   segment High-Value One-Timers, thay vì coi model là bộ phân loại
   nhị phân.
3. **Hạ ưu tiên segment "Lapsed/At-Risk"** (đã ~14 tháng không hoạt động)
   khỏi các campaign retention tốn kém — chỉ nên dùng kênh chi phí thấp
   (email) nếu vẫn muốn thử win-back.
4. **Đầu tư thu thập thêm dữ liệu hành vi hậu mua hàng** (customer
   service, engagement với email/app) cho các vòng phân tích tiếp theo,
   vì đặc điểm giao dịch tĩnh hiện tại không đủ mạnh để dự đoán chính xác.

## 5. Limitations

- Dataset chỉ phản ánh thị trường Brazil giai đoạn 2016-2018, có thể
  không đại diện cho thị trường/giai đoạn khác.
- Model repeat-purchase chỉ dùng feature tĩnh từ đơn hàng đầu, chưa có
  dữ liệu hành vi/marketing touchpoint.
- Cohort analysis theo lưới tháng có sai số biên do ranh giới tháng lịch
  không khớp chính xác 180 ngày (đã đối chiếu và ghi nhận ở Giai đoạn 6).
- Tỷ lệ mất cân bằng class (~97:3) giới hạn precision đạt được của mọi
  classifier trên feature set hiện có.

## 6. Tech Stack

PostgreSQL (SQL: window functions, CTE, aggregation) · Python (Pandas,
Scikit-learn, XGBoost, Matplotlib/Seaborn) · Power BI (đang triển khai)
