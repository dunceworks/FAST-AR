///////////////////////////////////////////////////////// 
//
// File name: grayscale.sv
// 
// Description: Converts the input RGB frame to grayscale using a simple weighted average method and flops it once.
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

// !!!! Adds ONE cycle delay.

module grayscale
#(
    parameter COLOR_BITS = 8
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.master axi4s_in,
    axi4s_vid_if.slave axi4s_out

);
    logic [COLOR_BITS-1:0] r;
    logic [COLOR_BITS-1:0] g;
    logic [COLOR_BITS-1:0] b;
    logic [COLOR_BITS-1:0] data_out;   // 8-bit grayscale output

    logic tvalid_flopped;
    logic tlast_flopped;
    logic tready_flopped;
    logic tuser_flopped;

    // Add a single flop stage
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            tvalid_flopped <= 1'b0;
            tlast_flopped <= 1'b0;
            tready_flopped <= 1'b0;
            tuser_flopped <= 1'b0;
        end else begin
            tvalid_flopped <= axi4s_in.tvalid;
            tlast_flopped <= axi4s_in.tlast;
            tready_flopped <= axi4s_out.tready;
            tuser_flopped <= axi4s_in.tuser;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end 
        else if (axi4s_in.tvalid && axi4s_out.tready) begin
            r <= axi4s_in.tdata[COLOR_BITS*3-1:COLOR_BITS*2 + 2];   // 1/4
            g <= axi4s_in.tdata[COLOR_BITS*2-1:COLOR_BITS + 1];     // 1/2
            b <= axi4s_in.tdata[COLOR_BITS-1:2];                    // 1/4
        end
    end


    assign data_out = {r+ b + g};    // gray = r/4 + b/4 + g/2  (bit shifts done earlier)


    // assign outputs
    assign axi4s_in.tready = axi4s_out.tready;    //tready flows *UP* the pipeline
    assign axi4s_out.tuser = tuser_flopped;    //tuser flows *DOWN* the pipeline (but we just pass it through flopped)
    assign axi4s_out.tlast = tlast_flopped;
    assign axi4s_out.tdata = {3{data_out}};    // replicate the grayscale value across R, G, B
    assign axi4s_out.tvalid = tvalid_flopped;

endmodule