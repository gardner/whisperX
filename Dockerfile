# Use NVIDIA CUDA base image for GPU support
# Note: README recommends CUDA 12.8, but we use 12.6 as a widely available recent version.
# You may need to adjust the tag if 12.8 becomes available or specific 12.8 features are required.
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive \
    # UV_SYSTEM_PYTHON=1 allows uv to install into system python if we wanted,
    # but using a venv is standard.
    UV_PROJECT_ENVIRONMENT="/app/.venv"

# Install system dependencies
# ffmpeg is critical for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    git \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
# RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /app

# Copy project definition files
COPY pyproject.toml uv.lock README.md ./

# Sync dependencies using uv
# --frozen ensures we use the exact versions from uv.lock
# This creates a virtual environment at /app/.venv
RUN uv sync --frozen --no-dev

# Copy the rest of the application source code
COPY . .

# Re-run sync to install the project itself (if strictly needed, or just install)
# uv sync usually installs the current project too.
RUN uv sync --frozen --no-dev

# Add the virtual environment to PATH
ENV PATH="/app/.venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT ["whisperx"]
CMD ["--help"]
