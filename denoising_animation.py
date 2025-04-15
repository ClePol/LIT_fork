import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from matplotlib.animation import FuncAnimation
import matplotlib.animation as animation
from pathlib import Path
from tqdm import tqdm
# Load the intermediate volumes


#intermediate_path = '/home/cp1163/Repositories/LIT_fork/test_outputs/debug_upsampling/inpainting_images/inpainting_intermediates.npy'
intermediate_path = '/home/cp1163/Repositories/LIT_fork/intermediates'
center_slice = 80
slice_direction = 'coronal'

# Function to get the correct slice based on direction
def get_slice(volume, direction, slice_idx):
    # Remove channel dimension if present
    if len(volume.shape) == 4:  # If shape is (C, H, W, D)
        volume = volume[0]  # Take first channel
    if direction == 'coronal':
        return volume[:, slice_idx, :]
    elif direction == 'sagittal':
        return volume[slice_idx, :, :]
    elif direction == 'axial':
        return volume[:, :, slice_idx]
    else:
        raise ValueError(f"Invalid slice direction: {direction}. Must be 'coronal', 'sagittal', or 'axial'")

# Extract the slice we're interested in from all intermediates


if Path(intermediate_path).is_file():
    intermediates = np.load(intermediate_path)
    sliced_intermediates = np.array([get_slice(vol, slice_direction, center_slice) for vol in intermediates])
elif Path(intermediate_path).is_dir():
    intermediate_files = list(Path(intermediate_path).glob('*.npy'))
    # file format inpainting_intermediates_0.npy, inpainting_intermediates_1.npy, etc.
    # so we need to sort the files by the number in the filename
    intermediate_files = sorted(intermediate_files, key=lambda x: int(x.stem.split('_')[-1]), reverse=True)
    #intermediate_files = intermediate_files[:100]
    first_intermediate = np.load(intermediate_files[0])
    if len(first_intermediate.shape) == 4:
        first_intermediate = first_intermediate[0]
    intermediates = np.zeros((len(intermediate_files), 1, first_intermediate.shape[0], first_intermediate.shape[1]))
    for i, file in enumerate(tqdm(intermediate_files)):
        intermediate = np.load(file)
        if intermediate.size == 0:
            print(f"Warning: Intermediate {file} is empty")
            intermediate = np.zeros((1, first_intermediate.shape[0], first_intermediate.shape[1]))
        if len(intermediate.shape) == 4:
            intermediate = intermediate[0]
        
        intermediates[i] = np.array([get_slice(intermediate, slice_direction, center_slice)])
        del intermediate
    sliced_intermediates = intermediates[:, 0, :, :]

else:
    raise FileNotFoundError(f"File or directory not found: {intermediate_path}")


# Create interactive figure
fig_interactive = plt.figure(figsize=(10, 10))
ax_interactive = plt.subplot(111)
plt.subplots_adjust(bottom=0.2)  # Make room for the slider

# Initialize the interactive image plot
img_interactive = ax_interactive.imshow(sliced_intermediates[0], 
                                       cmap='gray', vmin=0, vmax=1)
ax_interactive.axis('off')
title_interactive = ax_interactive.set_title(f'Denoising - {slice_direction} slice {center_slice} - Step 0/{len(sliced_intermediates)-1}')

# Create slider axis
ax_slider = plt.axes([0.2, 0.1, 0.65, 0.03])
slider = Slider(
    ax=ax_slider,
    label='Step',
    valmin=0,
    valmax=len(sliced_intermediates)-1,
    valinit=0,
    valstep=1
)

# Update function for slider
def update_interactive(val):
    step = int(slider.val)
    img_interactive.set_array(sliced_intermediates[step])
    title_interactive.set_text(f'Denoising - {slice_direction} slice {center_slice} - Step {step}/{len(sliced_intermediates)-1}')
    fig_interactive.canvas.draw_idle()

# Register the update function with the slider
slider.on_changed(update_interactive)

# Add keyboard navigation
def on_key(event):
    if event.key == 'right':
        new_val = min(slider.val + 1, slider.valmax)
        slider.set_val(new_val)
    elif event.key == 'left':
        new_val = max(slider.val - 1, slider.valmin)
        slider.set_val(new_val)

fig_interactive.canvas.mpl_connect('key_press_event', on_key)

# Create animation figure
fig_animation = plt.figure(figsize=(10, 10))
ax_animation = plt.subplot(111)
ax_animation.axis('off')

# Initialize the animation image plot
img_animation = ax_animation.imshow(sliced_intermediates[0], 
                                   cmap='gray', vmin=0, vmax=1)
title_animation = ax_animation.set_title(f'Denoising - {slice_direction} slice {center_slice} - Step 0/{len(sliced_intermediates)-1}')

# Update function for animation
def update_animation(frame):
    img_animation.set_array(sliced_intermediates[frame])
    title_animation.set_text(f'Denoising - {slice_direction} slice {center_slice} - Step {frame}/{len(sliced_intermediates)-1}')
    return [img_animation, title_animation]

# Create and save the animation
print("Creating animation...")
fps = 30
ani = FuncAnimation(fig_animation, update_animation, frames=len(sliced_intermediates),
                   interval=1000/fps, blit=True)

writer = animation.FFMpegWriter(fps=fps)
ani.save('denoising_animation.mp4', writer=writer)
print("Animation saved as 'denoising_animation.mp4'")

# close animation figure
plt.close(fig_animation)

# Show the interactive plot
plt.show()


