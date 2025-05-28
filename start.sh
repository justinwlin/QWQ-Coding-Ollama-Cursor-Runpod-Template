#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Start nginx service
start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}

# Start Ollama service
start_ollama() {
    echo "🚀 Setting up Ollama with QwQ coding model..."
    
    # Set Ollama environment variables
    export OLLAMA_MODELS=/workspace/ollama-models
    export OLLAMA_HOST=0.0.0.0:11434
    echo "📁 Setting Ollama models directory to: $OLLAMA_MODELS"
    echo "🌐 Setting Ollama to bind to all interfaces: $OLLAMA_HOST"
    
    # Create models directory
    mkdir -p $OLLAMA_MODELS
    
    # Check if Ollama is installed, install if not
    if ! command -v ollama &> /dev/null; then
        echo "📦 Installing Ollama..."
        apt-get update
        apt-get install -y pciutils lshw curl
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    echo "🔄 Starting Ollama server..."
    nohup ollama serve > /ollama.log 2>&1 &
    
    # Wait for Ollama to start up
    echo "⏳ Waiting for Ollama to initialize..."
    until curl -s http://localhost:11434/api/version >/dev/null 2>&1; do
        echo "   Still waiting for Ollama..."
        sleep 2
    done
    echo "✅ Ollama server is running!"
    
    # Make a dummy API call to load the model
    echo "Warming up QwQ-32B model..."
    curl -s -X POST http://localhost:11434/api/generate \
        -d '{"model": "hf.co/unsloth/QwQ-32B-GGUF:Q4_K_M", "prompt": "Hello", "stream": false}' > /dev/null
    
    echo ""
    echo "🎉 Ollama setup complete!"
    echo "   • Local API: http://localhost:11434"
    echo "   • External API: https://[your-pod-id]-11434.proxy.runpod.net"
    echo "   • Logs: /ollama.log"
}

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
        # Generate SSH host keys if not present
        generate_ssh_keys
        service ssh start
        echo "SSH host keys:"
        cat /etc/ssh/*.pub
    fi
}

# Generate SSH host keys
generate_ssh_keys() {
    ssh-keygen -A
}

# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc
}

# Start jupyter lab
start_jupyter() {
    echo "Starting Jupyter Lab..."
    mkdir -p /workspace && \
    cd / && \
    nohup jupyter lab --allow-root --no-browser --port=8888 --ip=* --NotebookApp.token='' --NotebookApp.password='' --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
    echo "Jupyter Lab started without a password"
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

start_nginx
echo "Pod Started"
setup_ssh
start_ollama
start_jupyter

export_env_vars
echo "🎉 Start script(s) finished, pod is ready to use."
echo ""
echo "📋 Services running:"
echo "   • Nginx: ✅"
echo "   • SSH: $([ -n "$PUBLIC_KEY" ] && echo "✅" || echo "❌ (no PUBLIC_KEY)")"
echo "   • Jupyter Lab: ✅ (port 8888)"
echo "   • Ollama: ✅ (port 11434)"
echo ""

sleep infinity