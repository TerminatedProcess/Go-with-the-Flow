import gradio as gr
import os
from pathlib import Path
import shutil
import subprocess
import numpy as np
import cv2
from PIL import Image
import sys

def ensure_workspace_structure(image_path):
    """Create workspace directory structure for an image"""
    # Get base name of image without extension
    base_name = Path(image_path).stem
    
    # Create workspace directory structure
    workspace_dir = Path("workspace") / base_name
    data_dir = workspace_dir / "data"
    output_dir = workspace_dir / "output"
    
    # If directories exist, remove them and recreate
    if workspace_dir.exists():
        shutil.rmtree(workspace_dir)
    
    # Create fresh directories
    data_dir.mkdir(parents=True)
    output_dir.mkdir(parents=True)
    
    # Copy original image to data directory
    image_ext = Path(image_path).suffix
    shutil.copy2(image_path, data_dir / f"original{image_ext}")
    
    return workspace_dir, data_dir, output_dir

def run_cut_and_drag(image, state):
    if image is None:
        return "Please upload an image first.", None
    
    try:
        # Create workspace structure
        workspace_dir, data_dir, output_dir = ensure_workspace_structure(image)
        
        # Store workspace info in state
        state = {
            "workspace_dir": str(workspace_dir),
            "data_dir": str(data_dir),
            "output_dir": str(output_dir),
            "original_image": image
        }
        
        # Launch the cut_and_drag_gui.py in a separate process
        process = subprocess.Popen([
            sys.executable,
            "cut_and_drag_gui.py",
            image
        ])
        
        steps = [
            f"✓ Created workspace at {workspace_dir}",
            f"✓ Saved original image to {data_dir}",
            "✓ Launched Cut-and-Drag GUI window",
            "Please use the GUI window that opened to:",
            "  1. Select polygon regions",
            "  2. Define motion paths",
            "  3. Close the GUI when finished"
        ]
        
        return "\n".join(steps), state
    except Exception as e:
        return f"Error: {str(e)}", None

def placeholder_text_to_video(prompt, state):
    if not prompt:
        return "Please enter a prompt first."
    
    if not state or "workspace_dir" not in state:
        return "Please complete the Cut-and-Drag process first."
    
    steps = [
        f"Using workspace: {state['workspace_dir']}",
        f"Using original image: {state['original_image']}",
        f"Would process prompt: {prompt}"
    ]
    
    return "\n".join(steps)

# Create Gradio interface
with gr.Blocks(title="Go-with-the-Flow") as demo:
    # Shared state between tabs
    state = gr.State(None)
    
    gr.Markdown("# Go-with-the-Flow")
    gr.Markdown("Create videos with controlled motion patterns")
    
    with gr.Tab("1. Cut-and-Drag Video"):
        with gr.Row():
            with gr.Column():
                gr.Markdown("### 1. Upload Image")
                image_input = gr.Image(type="filepath", label="Input Image")
                
                gr.Markdown("### 2. Process")
                btn1 = gr.Button("Launch Cut-and-Drag GUI")
                
                gr.Markdown("### 3. Status")
                output_text1 = gr.Textbox(label="Progress", lines=8)
        
        gr.Markdown("---")
        gr.Markdown("""
        ### Process Steps:
        1. Upload an image
        2. Click 'Launch Cut-and-Drag GUI'
        3. Use the GUI window that opens to:
           - Select regions by drawing polygons
           - Define motion paths
           - Adjust scale and rotation
        4. Close the GUI when finished
        """)
    
    with gr.Tab("2. Text-to-Video"):
        with gr.Row():
            with gr.Column():
                gr.Markdown("### 1. Enter Prompt")
                prompt_input = gr.Textbox(
                    label="Prompt",
                    placeholder="Enter a detailed description of the video you want to create..."
                )
                
                gr.Markdown("### 2. Generate")
                btn2 = gr.Button("Generate Video")
                
                gr.Markdown("### 3. Status")
                output_text2 = gr.Textbox(label="Progress", lines=3)
                
        gr.Markdown("---")
        gr.Markdown("""
        Note: Complete the Cut-and-Drag process in Tab 1 before using this tab.
        This will use the processed animation as input for text-guided video generation.
        """)
    
    # Connect buttons to functions
    btn1.click(
        fn=run_cut_and_drag,
        inputs=[image_input, state],
        outputs=[output_text1, state]
    )
    btn2.click(
        fn=placeholder_text_to_video,
        inputs=[prompt_input, state],
        outputs=output_text2
    )

if __name__ == "__main__":
    # Ensure workspace directory exists
    Path("workspace").mkdir(exist_ok=True)
    
    # Launch the interface
    # This will start a local server and automatically open the interface in your default web browser
    print("Starting Gradio server...")
    print("The interface will be available at: http://127.0.0.1:7860")
    demo.launch(
        server_name="127.0.0.1",  # Only bind to localhost
        server_port=7860,         # Default Gradio port
        share=False,              # Disable public URL creation
        inbrowser=True           # Open in default browser
    )
