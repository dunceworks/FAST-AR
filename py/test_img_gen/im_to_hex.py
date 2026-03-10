from PIL import Image

# 1. Load image as RGB

img_base_path = "py\\test_img_gen\\input_img\\"
img_name = "camel_1080p" # Image name without extension
img_ext = ".png"
output_name = img_base_path + "..\\output_hex\\" + img_name + ".hex"

img = Image.open(img_base_path + img_name + img_ext).convert("RGB")
width, height = img.size

bits_per_channel = 8    # 8 bits per channel (R, G, B) - RGB888

# 2. Write to Hex file compatible with $readmemh (36-bit color: 12-bit per channel)
with open(output_name, "w") as f:
    # Write pixel data row by row
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            """"
            # Scale 8-bit values (0-255) to 12-bit (0-4095)
            r12 = (r << 4) | (r >> 4)  # Expand to 12-bit
            g12 = (g << 4) | (g >> 4)
            b12 = (b << 4) | (b >> 4)
            # Combine into n-bit value
            pixel_36bit = (r12 << 24) | (g12 << 12) | b12
            """
            # For 8-bit per channel, just combine directly (RGB888)
            pixel_comb = (r << (bits_per_channel * 2)) | (g << bits_per_channel) | b
            f.write(f"{pixel_comb:06x}\n") # Write as 6-digit hex

print(f"Generated {output_name}: {width}x{height} pixels")