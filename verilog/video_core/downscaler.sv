`default_nettype none

///////////////////////////////////////////////////////// 
//
// File name: downscaler.sv
// 
// Description: Downsizes the image to 128 dimensions.
//
// Created  : 2026-03-18
// Modified : 2026-03-19
// Author   : Wysong
//
// Team     : Dunce Works
//
// AI Disclosure: This code was initially written without AI assistance (not including small auto-completions - think small instantiations).
//                During debugging, Copilot was used to point out potential issues but not used to write any code. 
//                Comments written by the author.
//
// Written?     [X]
// SW Tested?   [ ]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////


module downscaler #(
    parameter IMG_WIDTH = 1920,
    parameter IMG_HEIGHT = 1080
) 
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out
);

    localparam SQUARE_SIZE = 1024;
    
    localparam LEFT_CROP_STOP = (IMG_WIDTH - SQUARE_SIZE) / 2; // Hard to name these things but this is where we STOP cropping
    localparam RIGHT_CROP_START = LEFT_CROP_STOP + SQUARE_SIZE; //And this is where we START back up cropping
    localparam TOP_CROP_STOP = (IMG_HEIGHT - SQUARE_SIZE) / 2;
    localparam BOTTOM_CROP_START = TOP_CROP_STOP + SQUARE_SIZE;


    logic [$clog2(IMG_WIDTH)-1:0] x_count; // H pixel counter
    logic [$clog2(IMG_HEIGHT)-1:0] y_count; // V pixel counter
    logic x_valid, y_valid, not_cropping, interpolate;

    logic stall;
    assign stall = !axi4s_out.tready; // Backpressure from output

    logic [23:0] pix_mat [0:7][0:7]; // 8x8 matrix for downscaler
    logic [23:0] lbo [0:8]; // Outputs from row buffers
    logic [23:0] avg_pixel; // Output pixel

    logic [25:0] sum_r, sum_g, sum_b; // Sums for averaging

    assign lbo[0] = axi4s_in.tdata;

    // Instantiate the rowbuffers for later
    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_1 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[0]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[1]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_2 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[1]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[2]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_3 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[2]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[3]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_4 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[3]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[4]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_5 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[4]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[5]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_6 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[5]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[6]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_7 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[6]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[7]), 
        .pixel_out_valid() 
    );

    line_buffer #(
        .D_WIDTH(24), // RGB888
        .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
    ) row_buffer_8 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lbo[7]),
        .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
        .pixel_out(lbo[8]), // Output from the 8th buffer
        .pixel_out_valid() 
    );


    // Counters for cropping tracking
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            x_count <= '0;
            y_count <= '0;
        end
        else if (!stall) begin
            if (axi4s_in.tvalid) begin
                if (x_count == IMG_WIDTH - 1) begin
                    x_count <= '0; // Reset at end of line
                    
                    if (y_count == IMG_HEIGHT - 1) 
                        y_count <= '0; // Reset at end of frame
                    else 
                        y_count <= y_count + 1; // Increment for each valid line
                    
                end else
                    x_count <= x_count + 1; // Increment for each valid pixel
                
            end
        end
    end

    // Determine if current pixel is within the crop region (the actual cropping)
    assign x_valid = (x_count >= LEFT_CROP_STOP) && (x_count < RIGHT_CROP_START);
    assign y_valid = (y_count >= TOP_CROP_STOP) && (y_count < BOTTOM_CROP_START);
    assign not_cropping = x_valid && y_valid && axi4s_in.tvalid; // If either is valid, we're not cropping (oh and the data is valid duh)

    assign interpolate = (x_count - LEFT_CROP_STOP) % 8 == 0 && (y_count - TOP_CROP_STOP) % 8 == 0 && not_cropping; // Only interpolate every 8 pixels in both directions within the crop region

    // Stuff the pixel matrix (and shift it)
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            // Clear pixel matrix on reset
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    pix_mat[i][j] <= '0;
                end
            end
        end
        else if(not_cropping) begin
            for(int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    if (j == 0)
                        pix_mat[i][j] <= lbo[i]; // Shift previous row down
                    else
                        pix_mat[i][j] <= pix_mat[i][j-1]; // Shift right
                end
            end
        end
    end

    always_comb begin
        // Interpolate the 8x8 pixel block down to 1 pixel
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                sum_r += pix_mat[i][j][23:16]; // Red channel
                sum_g += pix_mat[i][j][15:8];  // Green channel
                sum_b += pix_mat[i][j][7:0];   // Blue channel
            end
        end

        avg_pixel[23:16] = sum_r >> 6; // Divide by 64 (8x8) using bit shift
        avg_pixel[15:8]  = sum_g >> 6;
        avg_pixel[7:0]   = sum_b >> 6;
    end


    // Output pixel data only if within crop region, otherwise output black
    assign axi4s_in.tready = !stall; // Backpressure from output

    assign axi4s_out.tdata = not_cropping ? avg_pixel : '0; // Output black for pixels outside crop region
    assign axi4s_out.tvalid = not_cropping && axi4s_in.tvalid && interpolate; // Only valid when within crop region and interpolation is enabled
    assign axi4s_out.tlast = (x_count == RIGHT_CROP_START) && (y_count == BOTTOM_CROP_START);    // Only assert tlast for last pixel in crop region
    assign axi4s_out.tuser = (x_count == LEFT_CROP_STOP) && (y_count == TOP_CROP_STOP);     // Only assert tuser for first pixel in crop region

endmodule