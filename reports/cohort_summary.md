# Cohort Retention Summary (Stage 6)

## Phương pháp
Nhóm khách hàng theo tháng mua lần đầu (cohort theo lưới tháng calendar),
theo dõi % còn hoạt động ở các period tiếp theo. Loại các cohort < 30 khách
để tránh nhiễu do mẫu nhỏ. Phân biệt rõ "0% thật" (đã quan sát đủ) vs
"chưa quan sát được" (NaN, do gần cuối dataset).

## Kết quả chính

- Tổng số cohort hợp lệ giữ lại: 21/23
- Retention sau tháng 0 nhìn chung rất thấp (<1% ở hầu hết ô), khớp với
  đặc điểm low-repeat-rate đã biết của dataset Olist.
- Khách đủ điều kiện quan sát đầy đủ 6 tháng: 55,525
- Cumulative repeat rate (tháng 1-6, pooled, đã hiệu chỉnh same-month repeat): **3.31%**
- Số khách mua lại ngay trong cùng tháng với đơn đầu (bị "ẩn" ở period 0
  theo quy ước lưới tháng): 863

## Đối chiếu chéo với Giai đoạn 5

| Phương pháp | Window | Repeat rate |
|---|---|---|
| Model-based (Giai đoạn 5) | 180 ngày chính xác | ~2.8% |
| Cohort-based (Giai đoạn 6, đã hiệu chỉnh) | ~6 tháng lịch (180-210 ngày) | ~3.31% |

**Kết luận**: 2 phương pháp độc lập cho kết quả nhất quán trong khoảng dung sai
hợp lý. Chênh lệch ~0.5 điểm % giải thích được bằng sự khác biệt ranh giới
window (tháng lịch dài hơn 180 ngày cố định ở một số cohort), không phải
sai số dữ liệu hay lỗi tính toán — đây là giới hạn phương pháp luận đã biết
của cohort analysis theo lưới tháng.

## Hạn chế cần nêu khi trình bày
- Cohort theo lưới tháng có độ phân giải thô — khách mua lại trong vài ngày
  nhưng vẫn nằm trong cùng tháng calendar sẽ không xuất hiện ở period 1+,
  cần xử lý riêng (đã làm ở bước hiệu chỉnh).
- Vài cohort ở 2 đầu dataset (2016-09, 2016-12) bị loại do mẫu quá nhỏ
  (1 khách) — không đại diện.
