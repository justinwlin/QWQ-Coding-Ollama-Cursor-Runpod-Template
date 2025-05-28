"""RunPod handler for Ollama API."""

import runpod
import requests
import json

def query_ollama(prompt, model="hf.co/unsloth/QwQ-32B-GGUF:Q4_K_M"):
    """Query the Ollama API with a prompt."""
    try:
        url = "http://localhost:11434/api/generate"
        data = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        
        response = requests.post(url, json=data)
        response.raise_for_status()
        
        result = response.json()
        return result.get("response", "No response generated")
        
    except Exception as e:
        return f"Error querying Ollama: {str(e)}"

def handler(job):
    """Handler function that will be used to process jobs."""
    job_input = job["input"]
    
    # Extract the prompt from job input
    prompt = job_input.get("prompt", "Hello, how are you?")
    model = job_input.get("model", "hf.co/unsloth/QwQ-32B-GGUF:Q4_K_M")
    
    try:
        # Query Ollama directly
        response = query_ollama(prompt, model)
        
        # Return successful response
        return {
            "status": "success",
            "response": response,
            "model": model
        }
    except Exception as e:
        # Return error response if something goes wrong
        return {
            "status": "error",
            "message": str(e)
        }

runpod.serverless.start({"handler": handler})
