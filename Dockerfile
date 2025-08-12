# syntax=docker/dockerfile:1
#
# MCP Server container
# - Works on Smithery.ai or any Docker runtime
# - Installs system deps needed by langchain/chromadb/lxml/etc.
# - Lets you override the start command with START_CMD env (Smithery sets $PORT)

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System dependencies often required by the stack in requirements.txt
# (chromadb -> hnswlib, lxml; google/genai/grpc; sqlite for aiosqlite/langgraph checkpoints)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    libffi-dev \
    libssl-dev \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    sqlite3 \ && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first to leverage Docker build cache
# Ensure your repo contains requirements.txt with the contents you shared.
COPY requirements.txt /app/requirements.txt

# Upgrade pip & install deps
RUN python -m pip install --upgrade pip setuptools wheel && \    pip install --no-cache-dir -r /app/requirements.txt

# Copy the rest of your server code (e.g., crawl_server.py, README.md, etc.)
COPY . /app

# Create unprivileged user
RUN useradd -u 10001 -ms /bin/bash appuser
USER appuser

# Smithery typically injects PORT; default to 8000 if not set
ENV PORT=8000

# Expose the PORT for local/docker runs (no effect on some PaaS)
EXPOSE 8000

# Start command:
# By default we run your Python entrypoint.
# If your server exposes a FastAPI/Starlette app as `app`, you can override at runtime with:
#   -e START_CMD='uvicorn crawl_server:app --host 0.0.0.0 --port ${PORT:-8000}'
CMD bash -lc "${START_CMD:-python /app/crawl_server.py}"
