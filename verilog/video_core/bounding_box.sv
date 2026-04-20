///////////////////////////////////////////////////////// 
//
// File name: bounding_box.sv
// 
// Description: Implements a simple bounding box to demonstrate the area used for downscaling.
//              uses AXI4-Stream for I/O.
//
// Created  : 2026-03-01
// Modified : 2026-03-08
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

module bounding_box
#(
    parameter DS_FACTOR = 4,    // DS_FACTOR and DOWNSCALE_SIZE should reflect options chosen in the dowsncale module.
    parameter DOWNSCALE_SIZE = 224,
    parameter LINE_WIDTH = 10, // Thickness of the bounding box lines in pixels
    parameter INPUT_WIDTH = 1920,
    parameter INPUT_HEIGHT = 1080,
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.master axi4s_in,
    axi4s_vid_if.slave axi4s_out

);

    localparam BOUNDING_BOX_SIZE = DOWNSCALE_SIZE * DS_FACTOR; //square size

    //Calcualte bounding box coords
    localparam X1 = (INPUT_WIDTH - BOUNDING_BOX_SIZE)/2;
    localparam Y1 = (INPUT_HEIGHT - BOUNDING_BOX_SIZE)/2;

    localparam X2 = INPUT_WIDTH - X1; 
    localparam Y2 = INPUT_HEIGHT - Y1;

    logic draw_upper, draw_lower, draw_left, draw_right, draw_box;

    logic [15:0] xcnt;
    logic [15:0] ycnt;

    logic stall;

    assign stall = !axi4s_out.tready; // Backpressure from output

    // Horizontal and vertical pixel counters (never trust raw counting... rely on tuser and tlast and hope to whatever gods that be that the signals aren't corrupted)
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            xcnt <= '0;
            ycnt <= '0;
        end 
        else if(axi4s_in.tuser) begin
            xcnt <= '0; // reset counters at start of frame
            ycnt <= '0;
        end
        else if(axi4s_in.tvalid && !stall) begin
            if(axi4s_in.tlast) begin
                xcnt <= '0; // reset at end of line
                ycnt <= ycnt + 1;
            end
            else
                xcnt <= xcnt + 1;
        end
    end

    ////////////////////////
    // BOUNDING BOX LOGIC //
    ////////////////////////

    // Seems like a lot to do during a single stage, but consider that in Vivado, I'm baking in AXI4-Stream register stages around it so really we 
    // have a clock period to do it.

    // Determine if we are within BB region
    assign draw_upper = (ycnt >= Y1) && (ycnt < (Y1 + LINE_WIDTH)) && (xcnt >= X1) && (xcnt < X2); // Top line
    assign draw_lower = (ycnt >= Y2) && (ycnt < (Y2 + LINE_WIDTH)) && (xcnt >= X1) && (xcnt < X2); // Bottom line
    assign draw_left = (xcnt >= X1) && (xcnt < (X1 + LINE_WIDTH)) && (ycnt >= Y1) && (ycnt < Y2); // Left line
    assign draw_right = (xcnt >= X2) && (xcnt < (X2 + LINE_WIDTH)) && (ycnt >= Y1) && (ycnt < Y2); // Right line

    assign draw_box = draw_upper || draw_lower || draw_left || draw_right;



    // assign outputs
    assign axi4s_in.tready = axi4s_out.tready;    //tready flows *UP* the pipeline
    assign axi4s_out.tuser = axi4s_in.tuser;    //tuser flows *DOWN* the pipeline (but we just pass it through flopped)
    assign axi4s_out.tlast = axi4s_in.tlast;
    assign axi4s_out.tdata = draw_box ? 24'h00FF00 : axi4s_in.tdata ;    //Draw green if bounding otherwise pass data through 
    assign axi4s_out.tvalid = axi4s_in.tvalid;

endmodule