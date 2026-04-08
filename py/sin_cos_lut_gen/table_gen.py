import math

with open("sin_table.mem", "w") as f:
    for i in range(256):
        val = int(math.sin(2*math.pi*i/256) * 32767)
        f.write(f"{val & 0xFFFF:04x}\n")