#!/bin/bash
clear

# Exit on error
set -e

# Required Python version
REQUIRED_PYTHON="3.11.10"

# Set and verify Python version
echo "Setting Python version with pyenv..."
pyenv local $REQUIRED_PYTHON

CURRENT_PYTHON=$(python -c "import platform; print(platform.python_version())")
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

echo "Installing all requirements..."
pip install -r requirements_mryan.txt


echo "Installation complete! Virtual environment is activated."
echo "You can now run:"
echo "python cut_and_drag_gui.py  # For the animation template GUI"
echo "python make_warped_noise.py <video_path> --output_folder noise_warp_output_folder  # For warping noise"
echo "python cut_and_drag_inference.py noise_warp_output_folder --prompt \"Your prompt\" --output_mp4_path output.mp4 --device cuda  # For inference"
