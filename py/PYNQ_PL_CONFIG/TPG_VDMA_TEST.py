from pynq import Overlay, allocate, MMIO
import numpy as np
import matplotlib.pyplot as plt
import time

# --- 1. LOAD OVERLAY & DISCOVER BLOCKS ---
print("1. Loading bitstream 'pipeline.bit'...")
ol = Overlay("pipeline.bit")

# print("\n--- DETECTED HARDWARE BLOCKS ---")
# for ip_name in ol.ip_dict.keys():
#     phys_addr = hex(ol.ip_dict[ip_name]['phys_addr'])
#     print(f" -> {ip_name} @ {phys_addr}")
print("--------------------------------\n")

# --- 2. MAP IPs SAFELY (MMIO) ---
# Grabbing the exact addresses from the dictionary so we don't guess
vdma_base = ol.ip_dict['axi_vdma_0']['phys_addr']
tpg_base  = ol.ip_dict['v_tpg_0']['phys_addr']
vdma = MMIO(vdma_base, 0x10000)
tpg  = MMIO(tpg_base, 0x10000)
print("IPs mapped.")

# --- 3. ALLOCATE MEMORY ---
width, height = 1920, 1080
stride = width * 3  # 3 bytes per pixel for RGB888

print(f"2. Allocating {width}x{height} frame buffer...")
frame_buffer = allocate(shape=(height, width, 3), dtype=np.uint8)
print(f" -> Buffer physical address: {hex(frame_buffer.device_address)}\n")

# --- 4. ARM THE VDMA (DESTINATION FIRST) ---
print("3. Initializing VDMA S2MM (Write Channel)...")
vdma.write(0x30, 0x4)        # 1. Soft Reset
time.sleep(0.1)              # Let the reset settle
vdma.write(0x30, 0x3)        # 2. Start S2MM, Circular Mode

# Program ALL possible frame pointers to the same safe address
print("Beginning VDMA reg writes")
vdma.write(0xAC, frame_buffer.device_address) # Frame 1
vdma.write(0xB0, frame_buffer.device_address) # Frame 2 (Protects against 0x0 crash!)
vdma.write(0xB4, frame_buffer.device_address) # Frame 3 (Protects against 0x0 crash!)

vdma.write(0xA8, stride)                      # Stride (Bytes per line)
vdma.write(0xA4, stride)                      # HSize (Horizontal bytes)
vdma.write(0xA0, height)                      # VSize (Vertical lines) - THIS ARMS IT
print(" -> VDMA is Armed and Listening.\n")

# --- 5. THE SAFE TPG "PING" TEST ---
print("4. Testing AXI-Lite connection to TPG...")

try:
    # Attempt to read the TPG's Control Register (Offset 0x00)
    # If the bus is broken, the script will freeze right here.
    tpg_status = tpg.read(0x00)
    print(f" -> SUCCESS: TPG is alive! Control Reg reads: {hex(tpg_status)}")
    
    # Let's also verify the VDMA is sitting in the "Armed" state waiting for pixels
    vdma_status = vdma.read(0x34)
    print(f" -> VDMA Status Reg reads: {hex(vdma_status)}")
    
except Exception as e:
    print(f" -> FAILED: The bus locked up or threw an error: {e}")

print("--------------------------------\n")

# --- 5. START THE TPG (TURN ON THE FAUCET) ---
print("4. Configuring and Starting TPG...")
tpg.write(0x10, height) # Height
tpg.write(0x18, width)  # Width
tpg.write(0x40, 0x0)    # Color Format: RGB (just to be safe)
tpg.write(0x20, 0x9)    # Background Pattern: Color Bars
tpg.write(0x00, 0x81)   # AP_START + Auto-Restart
print(" -> TPG is Generating Pixels.\n")

# --- 6. WAIT AND VERIFY ---
print("5. Waiting for frames to flow...")
time.sleep(0.5)

status = vdma.read(0x34)
print(f" -> VDMA S2MM Status Register: {hex(status)}")

#RENDER

# The corrected proper status check 
# (0x0FF1 checks the Halted bit 0, and actual Error bits 4-11)
if not (status & 0x0FF1):
    print("\nSUCCESS! Data is flowing. Rendering image...")
    
    # CRITICAL: Force the CPU to fetch fresh data from DDR, not its local cache
    frame_buffer.invalidate()
    
    plt.figure(figsize=(12, 7))
    plt.imshow(frame_buffer)
    plt.title("Captured Frame from TPG")
    plt.axis('off')
    plt.show()
else:
    print(f"\n!! PIPELINE STALLED !! Status code: {hex(status)}")
    