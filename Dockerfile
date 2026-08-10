# ---- Stage 1: Builder ----
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---- Stage 2: Production ----
FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app/ app/
COPY utils/ utils/

# Chạy service bằng user thường thay vì root.
RUN useradd --system --uid 10001 --create-home appuser
USER appuser

EXPOSE 8000

# Image slim không có curl; dùng Python và đọc cổng động từ PORT.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import os, urllib.request; port = os.getenv('PORT', '8000'); urllib.request.urlopen(f'http://127.0.0.1:{port}/healthz', timeout=3)"

# Qua shell để biến PORT do nền tảng cloud cung cấp được mở rộng lúc chạy.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
