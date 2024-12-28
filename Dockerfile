# Stage 1: Python base (shared by all subsequent stages)
FROM python:3.10-slim AS python-base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install common dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Builder base (for installing and exporting dependencies)
FROM python-base AS builder-base

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=1.8.2
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

# Set work directory
WORKDIR /app

# Copy Poetry files
COPY pyproject.toml poetry.lock ./

# Install dependencies and export to requirements.txt
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# Stage 3: Development (final stage for running the app in development mode)
FROM python-base AS development

# Set work directory
WORKDIR /app

# Copy dependencies from the builder-base stage
COPY --from=builder-base /app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . src/

# Collect static files
RUN python src/manage.py collectstatic --noinput || true  # Allow failures in dev mode

# Expose the development server port
EXPOSE 8000

# Set the default entrypoint for Django development
CMD ["python", "src/manage.py", "runserver", "0.0.0.0:8000"]