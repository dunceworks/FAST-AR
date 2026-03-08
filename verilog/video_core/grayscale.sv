///////////////////////////////////////////////////////// 
//
// File name: grayscale.sv
// 
// Description: Converts the input RGB frame to grayscale using a simple weighted average method and flops it once.
//              uses AXI4-Stream for I/O.
//
// Created  : 2026-03-01
// Modified : 2026-03-02
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [ ]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

`default_nettype none

// Adds one cycle delay.

module grayscale
#(
    parameter COLOR_BITS = 8
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out

);
    logic [COLOR_BITS-1:0] r;
    logic [COLOR_BITS-1:0] g;
    logic [COLOR_BITS-1:0] b;

    logic tvalid_flopped;

    // Always ready to receive data
    assign axi4s_in.tready = 1'b1;

    // Add a single flop stage
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n)
            tvalid_flopped <= 1'b0;
        else
            tvalid_flopped <= axi4s_in.tvalid;
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end 
        else if (axi4s_in.tvalid && axi4s_out.tready) begin
            r <= axi4s_in.tdata[COLOR_BITS*3-1:COLOR_BITS*2];
            g <= axi4s_in.tdata[COLOR_BITS*2-1:COLOR_BITS];
            b <= axi4s_in.tdata[COLOR_BITS-1:0];
        end
    end



    // assign outputs
    assign axi4s_out.tdata = {r[COLOR_BITS-1:2], b[COLOR_BITS-1:2], g[COLOR_BITS-1:1]};    // gray = r/4 + b/4 + g/2    also no need to check for tready
    assign axi4s_out.tvalid = tvalid_flopped;

endmodule