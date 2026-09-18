# Customer Segmentation Summary (Stage 3 — RFM + K-Means)

## Phương pháp
Tính 3 chỉ số RFM cho mỗi khách hàn dựa trên đơn hàng đầu tiên đã giao thành công:
- **Recency**: số ngày từ đơn hàng gần nhất đến ngày snapshot (ngày cuối
  dataset + 1)
- **Frequency**: tổng số đơn hàng
- **Monetary**: tổng chi tiêu

## Xử lý phân phối
- Recency: phân phối bình thường, không cần biến đổi.
- Frequency: lệch nặng (~97% khách chỉ có 1 đơn) — đặc thù của dataset
  có tỷ lệ mua lại thấp.
- Monetary: lệch phải mạnh, cần biến đổi log trước khi đưa vào clustering.
- Cả 3 chỉ số được chuẩn hóa (standardization) trước K-Means vì khác đơn
  vị đo và khác khoảng giá trị.

## Chọn số cụm (k)
Dùng kết hợp Elbow method và Silhouette score để xác định k tối ưu,
kết quả chọn **k = 4**.

## Kết quả phân cụm

| Segment | % Khách hàng | Đặc điểm chính |
|---|---|---|
| Repeat Buyers | 3.0% | Duy nhất nhóm có Frequency > 1; đã quay lại mua |
| High-Value One-Timers | 34.6% | Mới mua gần đây, chi tiêu cao, nhưng chưa quay lại |
| Low-Value Newcomers | 33.1% | Mới mua gần đây, chi tiêu thấp |
| Lapsed / At-Risk | 29.3% | Không hoạt động đã lâu (gần 14 tháng), coi như đã mất |

**Nhận xét về cấu trúc cụm**: chỉ có 1 nhóm (Repeat Buyers) phân biệt bởi
Frequency; 3 nhóm còn lại đều có Frequency = 1 và được phân tách chủ yếu
dựa trên Recency và Monetary — phản ánh đúng đặc thù dataset có tỷ lệ mua
lại cực thấp (~3%), nơi phần lớn sự khác biệt giữa khách hàng nằm ở "họ
mua gần đây hay không" và "họ chi bao nhiêu" chứ không phải "họ mua bao
nhiêu lần".

## Ý nghĩa 

- **High-Value One-Timers** là nhóm đáng chú ý nhất: chiếm tỷ trọng lớn
  nhất, giá trị chi tiêu cao tương đương nhóm đã quay lại, nhưng chưa
  từng mua lần 2 — đây là mục tiêu ưu tiên hàng đầu cho retention
  marketing vì tiềm năng ROI cao.
- **Lapsed/At-Risk** nên được hạ ưu tiên khỏi các chiến dịch retention
  tốn kém, vì đã không hoạt động quá lâu để kỳ vọng win-back hiệu quả.
- **Repeat Buyers** tuy nhỏ nhưng là nhóm cần giữ chân, tránh để rơi vào
  trạng thái Lapsed.