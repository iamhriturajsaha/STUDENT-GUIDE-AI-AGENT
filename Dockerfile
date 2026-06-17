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

# Copy application source code
COPY . .

# Cloud Run sets PORT env variable; ADK's `adk web` uses 8080 by default
ENV PORT=8080

# Expose the port
EXPOSE 8080

# Run the ADK web server, binding to all interfaces on $PORT
CMD ["sh", "-c", "adk web --host 0.0.0.0 --port ${PORT}"]
