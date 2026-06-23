# EDA Summary — Olist Customer Retention Project

> Dưới đây là các số liệu được trích xuất từ quá trình chạy notebook 01_eda.ipynb và các data tương ứng. File này đóng vai trò là nguồn để viết phần "Key Findings" trong README và bullet point CV.

## 1. Order Status
- % delivered: **97.02%** (96,478 đơn hàng)
- % canceled/unavailable: **1.24%** (0.63% canceled + 0.61% unavailable)
- Nhận xét: Tỷ lệ giao hàng thành công là rất cao, tỷ lệ đơn bị hủy hoặc không có hàng chiếm tỷ trọng cực kì nhỏ, cho thấy khâu fulfillment của Olist hoạt động khá ổn định ở bề nổi.

## 2. Xu hướng theo thời gian
- Tháng có order volume cao nhất: **Tháng 11/2017** (do sự kiện Black Friday).
- Bất thường cần lưu ý (tháng đầu/cuối thiếu data): Tháng 9/2016 (chỉ có rất ít đơn hàng thử nghiệm) và tháng 9 - 10/2018 bị thiếu hụt dữ liệu đáng kể, cần cẩn thận khi cắt window time để không bị nhiễu.

## 3. Phân phối địa lý
- State chiếm tỷ trọng cao nhất: **SP** (chiếm khoảng 42% tổng lượng khách hàng).
- Nhận xét về rủi ro tập trung địa lý: Dữ liệu phân phối lệch nặng về bang SP. Các chiến lược marketing hoặc mô hình có xu hướng học theo hành vi của khách hàng ở SP. Cần lưu ý nếu muốn mở rộng dự đoán sang các bang khác (vốn có cước phí vận chuyển cao hơn và thời gian giao hàng lâu hơn).

## 4. Phân phối category
- Top 3 category: **bed_bath_table**, **health_beauty**, **sports_leisure**.
- Nhận xét: Các mặt hàng chủ lực mang tính chất mua sắm cá nhân/gia đình. Tuy nhiên, tính chất của những ngành hàng này ở Olist thường không có chu kỳ mua lại ngắn và cố định như ngành tiêu dùng nhanh (FMCG).

## 5. Review Score
- % score 5: **~57%**
- % score 1: **~11.5%**
- Nhận xét về phân phối lệch 2 cực: Đa phần khách hàng rất hài lòng (đánh giá 5 sao), tuy nhiên nhóm cực kỳ thất vọng (đánh giá 1 sao) lại lớn hơn hẳn các nhóm trung vị (2, 3 sao). Khách hàng có xu hướng chỉ để lại review khi trải nghiệm cực kỳ tốt hoặc cực kỳ tệ.

## 6. Hiệu suất giao hàng
- % đơn giao trễ: **~7.52%** (Dựa trên tỷ lệ test set: 1052 đơn giao trễ / 13977 đơn)
- Median delivery days: **~7.0 ngày**.

## 7. Repeat Purchase Rate (INSIGHT CỐT LÕI)
- Tổng số khách hàng (unique): **~96,096** khách hàng.
- Số khách mua lại (>1 lần): Tỷ lệ mua lại đo lường dao động từ **2.8%** (khung 180 ngày tĩnh) đến **3.31%** (cộng dồn 6 tháng lịch).
- Ý nghĩa cho bài toán ở Giai đoạn 5: vì tỷ lệ mua lại quá thấp để định nghĩa "churn" theo nghĩa cổ điển, bài toán được định nghĩa lại thành dự đoán khả năng khách hàng quay lại mua lần thứ 2, dựa trên đặc điểm của lần mua đầu.