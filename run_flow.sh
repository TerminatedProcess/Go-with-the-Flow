#!/bin/bash

# Exit on error
set -e

# Check for required dependencies
if ! command -v kdialog &> /dev/null; then
    echo "Error: kdialog is not installed. Please install it with your package manager."
    exit 1
fi

if ! command -v vivaldi &> /dev/null; then
    echo "Error: vivaldi is not installed. Please install it or modify this script to use a different browser."
    exit 1
fi

# Check for virtual environment
if [ ! -d ".venv" ]; then
    echo "Error: Virtual environment not found. Please run install.sh first."
    exit 1
fi

# Activate virtual environment if not already activated
if [[ -z "${VIRTUAL_ENV}" ]]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
else
    echo "Using active virtual environment: ${VIRTUAL_ENV}"
fi

# Check CUDA availability
echo "Checking CUDA availability..."
if ! python -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'"; then
    echo "Error: CUDA is not available. This script requires a CUDA-capable GPU."
    exit 1
fi
echo "CUDA is available. Using GPU: $(python -c "import torch; print(torch.cuda.get_device_name(0))")"

# Launch file selection dialog
echo "Please select an image file..."
IMAGE_PATH=$(kdialog --getopenfilename . "Image files (*.png *.jpg *.jpeg *.gif)")

# Check if image was selected
if [ -z "$IMAGE_PATH" ]; then
    echo "No image selected. Exiting."
    exit 1
fik


# Extract base name without extension for folder naming
BASE_NAME=$(basename "$IMAGE_PATH" | sed 's/\.[^.]*$//')
echo "Using base name: $BASE_NAME"

# Create output directories
TEMPLATE_DIR="${BASE_NAME}"
WARP_DIR="${BASE_NAME}_warp"
mkdir -p "$TEMPLATE_DIR" "$WARP_DIR"

# Step 1: Run GUI to create template
echo "Running animation template GUI..."
echo "Please create your animation in the GUI window."
echo "The template will be saved as ${TEMPLATE_DIR}/${BASE_NAME}.mp4"
python cut_and_drag_gui.py "$IMAGE_PATH"

# Wait for the template file to exist
while [ ! -f "${TEMPLATE_DIR}/${BASE_NAME}.mp4" ]; do
    echo "Waiting for template animation to be saved..."
    sleep 5
done

# Step 2: Generate warped noise
echo "Generating warped noise..."
python make_warped_noise.py "${TEMPLATE_DIR}/${BASE_NAME}.mp4" --output_folder "$WARP_DIR"

# Step 3: Run inference
echo "Please enter a prompt for the video generation (press Enter for no prompt):"
read -r PROMPT
PROMPT=${PROMPT:-"A realistic scene"}

echo "Running inference with prompt: $PROMPT"
FINAL_OUTPUT="${BASE_NAME}_final.mp4"
python cut_and_drag_inference.py "$WARP_DIR" \
    --prompt "$PROMPT" \
    --output_mp4_path "$FINAL_OUTPUT" \
    --device "cuda" \
    --num_inference_steps 30

# Open the final video in Vivaldi
if [ -f "$FINAL_OUTPUT" ]; then
    echo "Opening final video in Vivaldi..."
    vivaldi "$FINAL_OUTPUT"
else
    echo "Error: Final video was not generated."
    exit 1
fi

echo "Process complete!"
echo "Files are preserved in:"
echo "- Template: $TEMPLATE_DIR"
echo "- Warped noise: $WARP_DIR"
echo "- Final video: $FINAL_OUTPUT"
