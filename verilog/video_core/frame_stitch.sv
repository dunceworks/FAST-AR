///////////////////////////////////////////////////////// 
//
// File name: frame_stitch.sv
// 
// Description: Stitches two frames together to create a wider image.
//              Used for AR display to combine the left and right views.
//
// Created  : 2026-03-09
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// AI Disclosure: This code was initially written without AI assistance (not including small auto-completions - think small instantiations).
//                During debugging, Copilot was used to point out potential issues but not used to write any code. 
//                Specifically in this file, copilot corrected misunderstanding of frame buffer timing.
//                Comments written by the author.
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

module frame_stitch #(
    parameter COLOR_BITS = 8,
    parameter IMG_WIDTH = 960,
    parameter IMG_HEIGHT = 1080
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,  //only one input since we're stitching in the pipeline and the second frame will be delayed to match the first
    axi4s_vid_if.sub axi4s_out
);

localparam OUT_WIDTH = IMG_WIDTH * 2; // Stitch two frames side by side


logic stall;
assign stall = !axi4s_out.tready;

logic [COLOR_BITS * 3 - 1:0] line_buffer_out;
logic [15:0] x_count; // Horizontal pixel counter

// Tlast logic and x_count management for stitching
always_ff @(posedge aclk or negedge areset_n) begin
    if (!areset_n) begin
        x_count <= 0;
    end else if (!stall) begin 
        if (axi4s_in.tvalid || (x_count != 0)) begin  // use tvalid for first line, then rely on x_count to keep going until we finish the stitched line
            if (x_count == OUT_WIDTH - 1) begin
                x_count <= 0; // Reset at end of line
                axi4s_out.tlast <= 1; // Assert tlast at end of stitched line
            end else begin
                x_count <= x_count + 1; // Increment for each valid pixel
            end
        end
    end
end

// Row buffer since we only have one camera input, we need to store one full line of pixels to stitch the second frame
// Data should become valid after the first 960 pixels.
line_buffer #(
    .D_WIDTH(COLOR_BITS * 3),
    .LINE_LENGTH(IMG_WIDTH)
) line_buffer_inst (
    .clk(aclk),
    .rst_n(areset_n),
    .pixel_in(axi4s_in.tdata),
    .pixel_valid(!stall),           // Free running as long as we're not stalled
    .pixel_out(line_buffer_out),    // Output the delayed line for stitching
    .pixel_out_valid()              // Unused.... tbh don't remember why this is here
);

// Should be perfectly timed such that we can stitch two frames together. 
// First 1/2 frame arrives, we store it as we write it out, write out the 2nd 1/2 frame from the buffer.
// By the time a new frame arrives, we should have finished writing out the stitched frame and be ready to accept the next line of pixels.
// Basically each frame (from the previous logic) still takes the original (full size) time to get to us.

// AXI4-Stream assigns
assign axi4s_in.tready = !stall;// && (x_count < IMG_WIDTH ) ; // Stall the input if we're still flushing the buffer.
                                // The above && onward can be removed (I think) in the final implementation. Just needed for testing.
// Data valid when we have valid input or we're still flushing out the stitched line, and not stalled
assign axi4s_out.tvalid = (axi4s_in.tvalid || x_count != 0) && !stall; 

assign axi4s_out.tdata = x_count < IMG_WIDTH ? axi4s_in.tdata : line_buffer_out;
assign axi4s_out.tuser = x_count == 0 && axi4s_in.tuser; // Assert tuser at start of stitched line

// tlast is asserted in the always_ff block above when we hit the end of the stitched line

endmodule