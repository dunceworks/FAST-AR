from PIL import Image
import math

# Config (Must match the TB!)
WIDTH = 128  # Must match input width
HEIGHT = 128 # Must match input height

# 1. Read the Hex Output (RGB888 - 24-bit color)
pixels = []
with open("py\\test_img_gen\\sv_hex_out\\downscaler_output.hex", "r") as f:
    for line in f:
        # Strip whitespace and convert hex to int
        if line.strip():
            pixel_val = int(line.strip(), 16)  # 24-bit RGB888 value
            # Extract R, G, B components
            r = (pixel_val >> 16) & 0xFF
            g = (pixel_val >> 8) & 0xFF
            b = pixel_val & 0xFF
            pixels.append((r, g, b))

# 2. Reconstruct Image
# Note: Output might be smaller than input due to the border effect!
# If your logic output 0 for borders, the count is the same.
# If your logic just didn't output valid for borders, the image is smaller.
actual_len = len(pixels)
print(f"Read {actual_len} pixels.")

# Create output image (RGB mode for 24-bit color)
img_out = Image.new("RGB", (WIDTH, HEIGHT))
img_out.putdata(pixels)
img_out.save("py\\test_img_gen\\output_img\\downscaler.png")