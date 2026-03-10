///////////////////////////////////////////////////////// 
//
// File name: crop_image.sv
// 
// Description: Center crops the image to half width. For use in AR mode where we only need the center portion of the image.
//              Later in the pipeline we'll side-by-side the filtered image to give us 1920*1080 output again.
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

module crop_image #(
    parameter IMG_WIDTH = 1920,
    parameter IMG_HEIGHT = 1080
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out

);
    localparam OUT_WIDTH = IMG_WIDTH / 2; // Crop to half width
    localparam OUT_HEIGHT = IMG_HEIGHT;   // Same height
    
    localparam LEFT_CROP_STOP = (IMG_WIDTH - OUT_WIDTH) / 2; // Number of pixels to crop from the left
    localparam RIGHT_CROP_START = LEFT_CROP_STOP + OUT_WIDTH; // Number of pixels to crop from the right

    logic stall;
    assign stall = !axi4s_out.tready; // Backpressure from output

    logic [15:0] x_count; // Horizontal pixel counter

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            x_count <= 0;
        end else if (!stall) begin 
            if (axi4s_in.tvalid) begin
                if (x_count == IMG_WIDTH - 1) begin
                    x_count <= 0; // Reset at end of line
                end else begin
                    x_count <= x_count + 1; // Increment for each valid pixel
                end
            end
        end
    end

    // Determine if current pixel is within the crop region
    logic in_crop_region;
    assign in_crop_region = (x_count >= LEFT_CROP_STOP) && (x_count < RIGHT_CROP_START);

    // Output pixel data only if within crop region, otherwise output black
    assign axi4s_in.tready = !stall; // Backpressure from output

    assign axi4s_out.tdata = in_crop_region ? axi4s_in.tdata : '0; // Output black for pixels outside crop region
    assign axi4s_out.tvalid = axi4s_in.tvalid && in_crop_region; // Only valid when within crop region
    assign axi4s_out.tlast = x_count < RIGHT_CROP_START;   // Only assert tlast for last pixel in crop region
    assign axi4s_out.tuser = x_count >= LEFT_CROP_STOP;   // Only assert tuser for first pixel in crop region

endmodule