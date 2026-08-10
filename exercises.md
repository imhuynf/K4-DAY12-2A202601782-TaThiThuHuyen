# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng giữ chỗ bên dưới mỗi câu hỏi bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Tạ Thị Thu Huyền  Mã học viên: 2A202601782

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi deploy lên Railway, nếu quên đặt `API_TOKEN` thì app cần dừng ngay để log báo rõ cấu hình còn thiếu. Nếu dùng mặc định `"changeme"`, service vẫn lên healthy và có thể bị người khác đoán được token để gọi `/chat`. Fail fast giúp tôi phát hiện lỗi ngay trong Deploy Logs thay vì chỉ phát hiện sau khi API đã bị mở với một secret yếu.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Một dòng log tôi thu được là: `{"event":"chat_completed","severity":"INFO","ts":"2026-08-10T16:37:05.307568+00:00","client_id":"exercise-check","prompt_tokens":4,"completion_tokens":42,"usd_cost":2.58e-05}`. Với log này tôi có thể lọc hoặc đếm request theo `client_id` và thời gian; đồng thời có thể tổng hợp token, chi phí để theo dõi ngân sách. Một câu `print` tự do không cung cấp các trường ổn định để hệ thống log tìm kiếm và tính toán tự động.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | Không còn image để đo lại |
| Multi-stage | 273 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Image multi-stage hiện tại đo bằng `docker images` là 273 MB. Tôi không còn giữ image của Dockerfile một stage nên không ghi một con số giả cho bản đó. Về nguyên tắc, phần chênh lệch là công cụ build, file tạm và các dependency chỉ cần khi cài đặt; stage runtime chỉ nhận các package đã cài cùng source cần chạy. `pip --no-cache-dir` cũng loại cache tải package khỏi image cuối.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi chỉ sửa `app/main.py`, các layer base image, `WORKDIR`, `COPY requirements.txt` và `RUN pip install` vẫn dùng cache. Layer `COPY app/ app/` và các layer sau nó phải tạo lại. Nếu đặt `COPY . .` trước `RUN pip install`, mọi thay đổi source sẽ làm mất cache của layer copy, khiến bước cài toàn bộ dependency chạy lại dù `requirements.txt` không đổi; build vì vậy chậm hơn nhiều.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Một lỗ hổng Python có thể cho phép thực thi lệnh trong container. Nếu tiến trình chạy root, kẻ tấn công có ngay quyền root trong container, có thể sửa file hệ thống hoặc khai thác tiếp runtime/container escape để tác động host. `USER appuser` cắt chuỗi ở bước sau khi chiếm tiến trình: mã độc chỉ có UID 10001 với quyền hạn chế, không còn quyền root để thực hiện các thao tác đặc quyền. Nó không loại bỏ lỗ hổng nhưng giảm đáng kể phạm vi thiệt hại.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

> `WWW-Authenticate: Bearer` cho client biết cơ chế xác thực mà tài nguyên yêu cầu theo chuẩn HTTP/RFC 6750, nhờ đó client có thể chọn cách gửi credential đúng. Cùng một thông báo cho thiếu header, sai scheme và sai token giúp tránh tiết lộ chi tiết kiểm tra cho kẻ tấn công; nếu trả lời quá cụ thể, họ có thể dùng API như một oracle để biết phần nào của credential đã đúng.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Client gửi được tối đa 10 request liên tiếp rồi request kế tiếp nhận 429, vì bucket không bao giờ chứa quá `capacity=10`, dù đã im lặng 10 phút. Nếu bỏ `min(capacity, ...)`, 10 phút sẽ nạp thêm 100 token, nên tùy cách tính từ trạng thái ban đầu bucket có thể tích lũy tới khoảng 110 token và cho phép một đợt bùng nổ vượt xa giới hạn thiết kế. `min` chính là phần chặn lượng token tích lũy ở sức chứa tối đa.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> Với hạn mức 30 USD/tháng, một client lỗi từ 2 giờ sáng có thể tiêu hết tối đa 30 USD ngay trong ngày và chỉ tự dùng lại được khi sang kỳ tháng mới. Với hạn mức 1 USD/ngày, thiệt hại của ngày đó bị chặn ở 1 USD và ngân sách tự tạo khóa mới khi sang ngày UTC tiếp theo. Giới hạn ngày giảm blast radius và thời gian chờ phục hồi, dù tổng giới hạn danh nghĩa theo 30 ngày là tương đương.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp endpoint và bắt nó ping Redis, khi Redis mất kết nối thì cả ba container đều trả healthcheck 503. Bộ điều phối đánh dấu cả ba unhealthy, rút chúng khỏi cân bằng tải rồi restart chúng. Các container mới vẫn không kết nối được Redis nên tiếp tục 503 và bị restart lặp lại, biến sự cố Redis 30 giây thành vòng lặp restart của toàn bộ app. Tách `/healthz` giúp process còn sống không bị restart, còn `/readyz` chỉ tạm ngừng nhận traffic cho đến khi Redis hồi phục.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lỗi thực tế của tôi là Railway báo `Error: Invalid value for '--port': '$PORT' is not a valid integer`, sau đó healthcheck `/healthz` hết 30 giây. Tôi mở Deploy Logs và thấy Uvicorn nhận nguyên chuỗi `$PORT`, chứng tỏ Custom Start Command của Docker image chạy dạng exec nên không mở rộng biến shell. Tôi sửa lệnh chạy qua `/bin/sh -c`, đồng thời dùng `${PORT:-8000}`; phương án chắc chắn trên dashboard là đặt `PORT=8000` và chạy Uvicorn với `--port 8000`.
