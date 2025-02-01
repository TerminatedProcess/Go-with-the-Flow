#!/bin/bash
clear

# Exit on error
set -e

# Required Python version
REQUIRED_PYTHON="3.11.10"

# Check if pyenv is available
if command -v pyenv >/dev/null 2>&1; then
    echo "Setting Python version with pyenv..."
    pyenv local $REQUIRED_PYTHON
else
    echo "pyenv not found, checking system Python version..."
fi

# Verify Python version
CURRENT_PYTHON=$(python -c "import platform; print(platform.python_version())")

if [ "$CURRENT_PYTHON" != "$REQUIRED_PYTHON" ]; then
    echo "Error: This project requires Python $REQUIRED_PYTHON"
    echo "Current Python version: $CURRENT_PYTHON"
    if ! command -v pyenv >/dev/null 2>&1; then
        echo "Please install pyenv or set up Python $REQUIRED_PYTHON manually"
    else
        echo "Please install Python $REQUIRED_PYTHON with:"
        echo "pyenv install $REQUIRED_PYTHON"
    fi
    exit 1
fi

echo "Using Python $CURRENT_PYTHON"

# Check for active virtual environment or existing directories
if [[ "$VIRTUAL_ENV" != "" ]] || [[ -d ".venv" ]] || [[ -d "venv" ]]; then
    echo "Virtual environment detected (active or directories exist)..."
    # Clean up directories if they exist
    if [[ -d ".venv" ]] || [[ -d "venv" ]]; then
        rm -rf .venv venv
        echo "Removed existing virtual environment directories."
    fi
    echo "Please start a new terminal session and run this script again."
    exit 0
fi

echo "Creating virtual environment..."
# Create new venv
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing GitPython..."
pip install GitPython

echo "Installing einops..."
pip install einops

echo "Installing PyTorch with CUDA support..."
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
exit

echo "Installing remaining local requirements..."
# Exclude torch and torchvision since we just installed them
grep -v "torch\|torchvision" requirements_local.txt | pip install -r /dev/stdin

echo "Installing additional requirements..."
pip install diffusers transformers accelerate peft sentencepiece

# ffmpeg-python
pip install ffmpeg-python

# GPU Requirements
echo '-----------------------------------------------------------'
echo "Installing GPU requirements"
pip install -r requirements.txt

echo "Installation complete! Virtual environment is activated."
echo "You can now run:"
echo "python cut_and_drag_gui.py  # For the animation template GUI"
echo "python make_warped_noise.py <video_path> --output_folder noise_warp_output_folder  # For warping noise"
echo "python cut_and_drag_inference.py noise_warp_output_folder --prompt \"Your prompt\" --output_mp4_path output.mp4 --device cuda  # For inference"
