# Written with Gemini
# Don't trust it to work.... but hopefully a good reference

from pynq import Overlay, allocate
import numpy as np

# 1. Load the Overlay
# Ensure your .bit and .hwh files have the same name in the same folder
overlay = Overlay("fast_ar_v1.bit")

# 2. Setup the TPG (Test Pattern Generator)
# We set it to 1080p (1920x1080) and Color Bars (pattern ID 9)
tpg = overlay.v_tpg_0
tpg.write(0x10, 1080)   # height
tpg.write(0x18, 1920)   # width
tpg.write(0x20, 9)      # background_pattern_id (9 = color bars)
tpg.write(0x00, 0x81)   # Control: Start (bit 0) and Auto-Restart (bit 7)

# 3. Allocate Physically Contiguous Memory
# This is the "Shared PL/PS" memory you put in your Arch diagram.
# We'll allocate 3 frame buffers to avoid tearing.
frame_shape = (1080, 1920, 3) # Height, Width, RGB
frames = [allocate(shape=frame_shape, dtype=np.uint8) for _ in range(3)]

# 4. Configure the VDMA (Write Channel)
vdma = overlay.axi_vdma_0

# VDMA Register Offsets (S2MM = Stream to Memory Mapped / Write)
# 0x30 = S2MM_VDMACR (Control Register)
# 0xAC = S2MM_START_ADDR1
# 0xA8 = S2MM_STRIDE
# 0xA4 = S2MM_HSIZE
# 0xA0 = S2MM_VSIZE

vdma.write(0x30, 0x4) # Reset the VDMA
vdma.write(0x30, 0x8) # Clear reset

# Tell VDMA where the "parking spots" are in physical RAM
vdma.write(0xAC, frames[0].device_address)
vdma.write(0x30, 0x00010003) # Start S2MM, Circular Mode, Genlock

# Stride is Width * Bytes per pixel (3 for RGB)
vdma.write(0xA8, 1920 * 3) 
vdma.write(0xA4, 1920 * 3) # Horizontal size
vdma.write(0xA0, 1080)     # Vertical size (This triggers the transfer!)

print("Pipeline is live! Checking for data...")

# 5. The Verification
# If the VDMA is working, the sum of pixels in the buffer will be > 0
if np.sum(frames[0]) > 0:
    print(f"Success! Captured data sum: {np.sum(frames[0])}")
    print(f"Sample Pixel (middle of screen): {frames[0][540, 960]}")
else:
    print("Zero data detected. Check your AXI-Stream TREADY/TVALID lines in ILA.")