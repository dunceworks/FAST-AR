///////////////////////////////////////////////////////// 
//
// File name: edge_sobel.sv
// 
// Description: Performs edge detection on a blurred grayscale using Sobel operators.
//              Uses AXI4-Stream for I/O. Outputs a "neon" green edge map where edges are detected. black otherwise
//
// Created  : 2026-03-01
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
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

`default_nettype none

module edge_sobel #(
    parameter COLOR_BITS = 8,
    parameter IMG_WIDTH = 1920,
    parameter IMG_HEIGHT = 1080
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out

);

    parameter IMG_SIZE = IMG_WIDTH * IMG_HEIGHT;

    // Internal signals
    logic [COLOR_BITS-1:0] gray_in;

    logic [COLOR_BITS-1:0] lb1_out;
    logic [COLOR_BITS-1:0] lb2_out;

    logic [4:0] tvalid_flopped;
    logic [4:0] tlast_flopped;
    logic [4:0] tready_flopped;
    logic [4:0] tuser_flopped;

    logic signed [11:0] gx_i[0:1]; 
    logic signed [11:0] gy_i[0:1];
    logic signed [11:0] gx; 
    logic signed [11:0] gy;
    logic [11:0] gx_u; // Unsigned versions for output
    logic [11:0] gy_u; // Unsigned versions for output
    logic [11:0] edge_strength; // Final edge strength for output (8-bit)

    reg signed [8:0] pix_mat [0:2][0:2]; // Current 9 pixels for edge detection (3x3 matrix)

    logic stall;    
    assign stall = !axi4s_out.tready;

    assign gray_in = axi4s_in.tdata[COLOR_BITS-1:0]; // Assuming input is already grayscale (R=G=B), just take one channel
    
    // Add a penta-flop stage
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            tvalid_flopped <= '0;
            tlast_flopped <= '0;
            tuser_flopped <= '0;
        end else if (!stall) begin
            tvalid_flopped  <= {tvalid_flopped[3:0], axi4s_in.tvalid};    
            tlast_flopped   <= {tlast_flopped[3:0], axi4s_in.tlast};
            tuser_flopped   <= {tuser_flopped[3:0], axi4s_in.tuser};
        end
    end

    // Instantiate line buffers
    line_buffer #(
        .D_WIDTH(COLOR_BITS),   // Grayscale
        .LINE_LENGTH(IMG_WIDTH) // IMG_WIDTH px for testing (IMG_WIDTH x IMG_HEIGHT image)
    ) 
        iLB1 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(gray_in),
        .pixel_valid(axi4s_in.tvalid),
        .pixel_out(lb1_out)
    );

    line_buffer #(
        .D_WIDTH(COLOR_BITS),   // Grayscale
        .LINE_LENGTH(IMG_WIDTH) // IMG_WIDTH px for testing (IMG_WIDTH x IMG_HEIGHT image)
    ) 
        iLB2 (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(lb1_out),
        .pixel_valid(axi4s_in.tvalid),
        .pixel_out(lb2_out)
    );


    // Shift current window when valid
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            // Clear pixel matrix on reset
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    pix_mat[i][j] <= '0;
                end
            end
        end
        else if(!stall && axi4s_in.tvalid) begin
            pix_mat[2][0] <= gray_in; // Current pixel
            pix_mat[2][1] <= pix_mat[2][0]; // Shift right
            pix_mat[2][2] <= pix_mat[2][1]; // Shift right

            pix_mat[1][0] <= lb1_out; // Previous row pixel
            pix_mat[1][1] <= pix_mat[1][0]; // Shift right
            pix_mat[1][2] <= pix_mat[1][1]; // Shift right

            pix_mat[0][0] <= lb2_out; // Previous previous row pixel
            pix_mat[0][1] <= pix_mat[0][0]; // Shift right
            pix_mat[0][2] <= pix_mat[0][1]; // Shift right
        end
    end


    // Actual Sobel edge detection logic below
    always_ff @(posedge aclk) begin
        if(!stall) begin
            // Stage one of pipeline
            gx_i[0] <= pix_mat[0][0] + (pix_mat[0][1] << 1) + pix_mat[0][2]; // Sobel horizontal
            gy_i[0] <= pix_mat[0][0] + (pix_mat[1][0] << 1) + pix_mat[2][0]; // Sobel vertical
            
            gx_i[1] <= pix_mat[2][0] + (pix_mat[2][1] << 1) + pix_mat[2][2]; // Sobel horizontal
            gy_i[1] <= pix_mat[0][2] + (pix_mat[1][2] << 1) + pix_mat[2][2]; // Sobel vertical
            

            // Stage two of pipeline
            gx      <= gx_i[0] - gx_i[1];   // Combine horizontal and vertical for final edge strength
            gy      <= gy_i[0] - gy_i[1];


            // Stage three of pipeline
            gx_u    <= gx[11] ? -gx : gx;
            gy_u    <= gy[11] ? -gy : gy;


            // Stage four of pipeline (final)
            edge_strength <= gx_u[11:1] + gy_u[11:1]; // Average the two gradients
        end
    end





    // AXI4-S outputs
    assign axi4s_in.tready = !stall;                                     //tready flows *UP* the pipeline
    assign axi4s_out.tuser = tuser_flopped[4];                          // frame starts when we are just getting pixel IMG_WIDTH + 2 (second pixel of second line)
    assign axi4s_out.tlast = tlast_flopped[4];      
    assign axi4s_out.tdata = !axi4s_out.tvalid ? '0 : (
            edge_strength > 200 ? {8'h00, 8'hFF, 8'h00} : (
            edge_strength < 80 ? {24'h000000} : {8'h00, edge_strength[7:0], 8'h00}
            )
    );    
    assign axi4s_out.tvalid = tvalid_flopped[4];                              // valid once we have at least 3 lines of pixels (enough for the 3x3 window)

endmodule