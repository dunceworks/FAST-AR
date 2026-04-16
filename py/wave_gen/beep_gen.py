import math

NUM_SAMPLES = 256
AMPLITUDE = 16000

with open("beep.mem", "w") as f:
    for i in range(NUM_SAMPLES):
        # Calculate sine wave value
        sine_val = math.sin(2 * math.pi * i / NUM_SAMPLES)
        
        # Scale to our desired amplitude
        scaled_val = int(sine_val * AMPLITUDE)
        
        # Convert to 16-bit two's complement hex
        if scaled_val < 0:
            scaled_val = (1 << 16) + scaled_val
            
        # Write to file (formatted to 4 hex digits)
        f.write(f"{scaled_val:04X}\n")

print("beep.mem generated successfully!")