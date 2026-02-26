# FAST-AR: Framework for Accelerated Spatial awareness in Augmented Reality

## FAST-AR is an FPGA-based augmented reality pipeline designed to explore hardware acceleration for low-latency spatial awareness. By moving video processing and UI rendering directly into custom RTL, this project aims to reduce the latency and memory-bandwidth bottlenecks typically associated with software-bound AR solutions. This is a capstone project for UW-Madison's ECE554.

Key Features:

- Direct Hardware Video Path: Real-time MIPI camera to mini-DisplayPort (mDP) passthrough.

- Stream Processing: Hardware-accelerated image filtering (e.g., edge detection, sharpening) utilizing custom 2D convolution engines and line buffers.

- Zero-Latency Overlays: A custom Sprite Engine for rendering real-time navigation cues directly over the video stream.

- Heterogeneous Architecture: Xilinx MPSoC design utilizing the FPGA fabric (PL) for AXI4-Stream video processing, and the ARM core (PS) for Bluetooth navigation data parsing and AXI4-Lite control logic.
