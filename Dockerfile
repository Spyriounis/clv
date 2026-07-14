FROM python:3.12-slim

# Bring in the uv binary from its official distroless image.
COPY --from=ghcr.io/astral-sh/uv:0.11.28 /uv /uvx /bin/

# Compile bytecode for faster startup and copy packages into the image layers
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Install dependencies first, in their own cached layer.
# README.md is copied because pyproject.toml declares it as the project readme.
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-install-project

# Copy the source and unit tests, then install the project itself
COPY src /app/src/
COPY tests /app/tests/
RUN uv sync --frozen

# Make the project's virtualenv the default environment
ENV PATH="/app/.venv/bin:${PATH}"
