# Use official Python slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy agent package into a named subfolder (adk web scans subdirectories)
RUN mkdir -p /app/student_guide
COPY agent.py /app/student_guide/agent.py
COPY __init__.py /app/student_guide/__init__.py

# Copy .env if present (for local runs; Render uses env vars directly)
COPY .env* /app/

# ADK's adk web uses 8080 by default
ENV PORT=8080

# Expose the port
EXPOSE 8080

# Run ADK web from /app — it will discover /app/student_guide as an agent package
CMD ["sh", "-c", "adk web --host 0.0.0.0 --port ${PORT}"]
