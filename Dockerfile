FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a non-root user
RUN adduser --disabled-password myuser

WORKDIR /app

COPY requirements.txt /app/

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libc-dev && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get purge -y --auto-remove gcc libc-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . /app/

# Change ownership to the non-root user
RUN chown -R myuser:myuser /app

# Switch to the non-root user
USER myuser

# Command to run the application
CMD ["sh", "-c", "python manage.py runserver 0.0.0.0:8000"]
