# Model Summary — Repeat Purchase Prediction (Stage 5)

## Bài toán
Dự đoán khả năng khách hàng quay lại mua lần 2 trong vòng 180 ngày,
dựa trên đặc điểm của đơn hàng đầu tiên.

## Kết quả model

| Metric | Random Forest | XGBoost |
|---|---|---|
| ROC-AUC | 0.5784 | 0.5761 |
| PR-AUC (Average Precision) | 0.0399 | 0.0390 |
| Recall (class 1) | 0.33 | 0.37 |
| Precision (class 1) | 0.04 | 0.04 |

Baseline repeat rate trong test set: 2.8% (392/13,977) — khớp với tỷ lệ
đã đo ở Giai đoạn 3-4, xác nhận pipeline không bị data leakage.

## Lift Analysis (góc nhìn ứng dụng thực tế)

| Nhóm | Lift vs baseline |
|---|---|
| Top 20% (decile 8-9) | ~1.44x |
| Bottom 10% (decile 0) | ~0.56-0.59x |
| Decile giữa (1-7) | dao động trong nhiễu thống kê (mẫu nhỏ, ~39 positive/decile) |

## Hyperparameter Tuning (RandomizedSearchCV, 30 candidates, 5-fold CV, scoring='average_precision')

| Metric | Trước tune | Sau tune |
|---|---|---|
| ROC-AUC | 0.5761-0.5784 | 0.5794 |
| PR-AUC (test) | 0.0390-0.0399 | 0.0391 |
| Lift top 20% | 1.44x | 1.44x |

**Kết luận tuning**: không cải thiện đáng kể trên các metric không phụ thuộc threshold
(ROC-AUC, PR-AUC, lift) — xác nhận nguyên nhân hiệu suất model nằm ở trần thông tin
của feature set, không phải do hyperparameter chưa tối ưu. Lưu ý: classification_report
sau tune cho thấy recall tăng mạnh (0.37 -> 0.84) nhưng đây chỉ là hệ quả của
scale_pos_weight cao (52) đẩy threshold mặc định 0.5 lệch, không phản ánh model
học tốt hơn — minh chứng là AUC/PR-AUC/lift giữ nguyên.

## Feature Importance (Top 5)
1. category_grouped_furniture_decor
2. category_grouped_sports_leisure
3. item_count
4. category_grouped_cool_stuff
5. distinct_product_count

Nhận xét: importance khá đồng đều giữa các feature (0.03-0.045) — không có
1 đặc điểm nào áp đảo, gợi ý rằng đặc điểm tĩnh của đơn hàng đầu mang tín hiệu
dự đoán yếu nói chung.

## Kết luận & Khuyến nghị kinh doanh

Đặc điểm giao dịch của đơn hàng đầu tiên KHÔNG đủ mạnh để dự đoán chi tiết
khả năng quay lại của khách (AUC thấp). Tuy nhiên model vẫn tạo ra lift có
ý nghĩa ở 2 đầu phân phối: nhóm top 20% xác suất dự đoán có tỷ lệ mua lại
thật cao hơn ~1.44x baseline.

**Ứng dụng thực tế**: dùng model để target marketing CHỌN LỌC — ưu tiên
budget cho top 20% (khả năng quay lại tự nhiên cao hơn), loại bottom 10%
khỏi campaign retention (ROI thấp), thay vì gửi campaign tràn lan cho
100% khách hàng.

**Hạn chế cần nêu rõ**: việc khách quay lại có thể phụ thuộc nhiều hơn vào
trải nghiệm hậu mua hàng và hoạt động marketing (không có trong dataset)
hơn là đặc điểm giao dịch ban đầu — đây là hướng mở rộng tốt nếu có thêm
dữ liệu (email engagement, customer service tickets, app usage...).
