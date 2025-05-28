FROM runpod/pytorch:2.0.1-py3.10-cuda11.8.0-devel-ubuntu22.04

# Environment variables
ENV PYTHONUNBUFFERED=1 

# Install dependencies in a single RUN command
RUN apt-get update --yes --quiet && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    software-properties-common \
    gpg-agent \
    build-essential \
    apt-utils \
    ca-certificates \
    curl && \
    add-apt-repository --yes ppa:deadsnakes/ppa && \
    apt-get update --yes --quiet && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    python3.11 python3.11-venv python3.11-dev

# Create and activate a Python virtual environment
RUN python3.11 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Set python3.11 as default
RUN ln -sf $(which python3.11) /usr/local/bin/python && \
    ln -sf $(which python3.11) /usr/local/bin/python3

# Install system dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget git libcudnn8 libcudnn8-dev lshw curl pciutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip && \
    pip install uv && \
    uv pip install --upgrade -r /requirements.txt --no-cache-dir

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Create required directories
RUN mkdir -p /root/.ollama/models

# Download model during build with better handling
RUN ollama serve > /dev/null 2>&1 & \
    sleep 25 && \
    ollama pull hf.co/unsloth/QwQ-32B-GGUF:Q4_K_M && \
    sleep 10 && \
    pkill ollama

# Add application files
ADD handler.py .
ADD start.sh /start.sh
RUN chmod +x /start.sh

# Startup script
CMD ["/start.sh"]