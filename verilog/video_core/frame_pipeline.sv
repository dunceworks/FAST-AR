///////////////////////////////////////////////////////// 
//
// File name: frame_pipeline.sv
// 
// Description: Wholistic frame processing pipeline that takes in raw RGB video data, applies edge detection, overlays it over RGB, 
//              applies barrel distortion filter, stitches two frames together into a single frame, and outputs the final processed video stream.
//
// Created  : 2026-03-09
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

module frame_pipeline #(
    parameter COLOR_BITS = 8,
    parameter IMG_WIDTH = 1920,
    parameter IMG_HEIGHT = 1080
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_RGB_in,
    axi4s_vid_if.sub axi4s_out

);

    // Edge detection AXI4-Stream interfaces
    axi4s_vid_if axi4s_gray_intf ();
    axi4s_vid_if axi4s_edge_intf ();
    axi4s_vid_if axi4s_RGB_DELAYED_IN_intf ();
    axi4s_vid_if axi4s_RGB_DELAYED_OUT_intf ();
    axi4s_vid_if axi4s_RGB_for_GRAYSCALE_intf ();


    // Add a splitter at the input to allow both edge detection and RGB delay to read the same input stream
    axi4s_splitter #(
        .COLOR_BITS(COLOR_BITS)
    ) splitter_inst (
        .aclk(aclk),
        .areset_n(areset_n),
        .axi4s_in(axi4s_RGB_in),
        .axi4s_out1(axi4s_RGB_DELAYED_IN_intf), // Delayed RGB for combine module
        .axi4s_out2(axi4s_RGB_for_GRAYSCALE_intf) // Input for edge detection
    );

    // Delay RGB input to align with edge detection output
    axi4s_delay #(
        .COLOR_BITS(COLOR_BITS),
        .DELAY_CYCLES(6) // Adjust this based on the latency of pipeline (1 + 5) gray + sobel
    ) delay_inst (
        .aclk(aclk),
        .areset_n(areset_n),
        .axi4s_in(axi4s_RGB_DELAYED_IN_intf),
        .axi4s_out(axi4s_RGB_DELAYED_OUT_intf) // Not connected since we only need the delayed RGB for the combine module
    );

    // Grayscale
    grayscale #(
        .COLOR_BITS(COLOR_BITS)
    ) grayscale_inst (
        .aclk(aclk),
        .areset_n(areset_n),
        .axi4s_in(axi4s_RGB_for_GRAYSCALE_intf),
        .axi4s_out(axi4s_gray_intf)
    );

    // Instantiate edge detection module
    edge_sobel #(
        .COLOR_BITS(COLOR_BITS),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) edge_detect_inst (
        .aclk(aclk),
        .areset_n(areset_n),
        .axi4s_in(axi4s_gray_intf),
        .axi4s_out(axi4s_edge_intf)
    );


    // Instantiate combine module to overlay edges on RGB
    combine #(
        .COLOR_BITS(COLOR_BITS)
        ) combine_inst (
        .aclk(aclk),
        .areset_n(areset_n),
        .axi4s_RGB_in(axi4s_RGB_DELAYED_OUT_intf), // Delayed RGB input
        .axi4s_edge_in(axi4s_edge_intf),
        .axi4s_out(axi4s_out)
    );








endmodule