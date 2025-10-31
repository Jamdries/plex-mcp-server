# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY plex_mcp_server.py .
COPY watcher.py .
COPY modules/ ./modules/

# Create a non-root user to run the application
RUN useradd -m -u 1000 plexmcp && \
    chown -R plexmcp:plexmcp /app

# Switch to non-root user
USER plexmcp

# Expose port for SSE transport
EXPOSE 3001

# Default command - can be overridden in docker-compose.yml
CMD ["python", "plex_mcp_server.py", "--transport", "sse", "--host", "0.0.0.0", "--port", "3001"]
