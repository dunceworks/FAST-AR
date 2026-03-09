///////////////////////////////////////////////////////// 
//
// File name: axi4s_delay.sv
// 
// Description: Delay module for AXI4-Stream video data by a parameterizable number of cycles. 
//              Useful for aligning data streams in the pipeline. DO NOT use for 0 cycle delay.
//
// Created  : 2026-03-09
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [ ]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////


module axi4s_delay #(
    parameter COLOR_BITS = 8,
    parameter DELAY_CYCLES = 1
)(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out

);

    logic stall;
    assign stall = !axi4s_out.tready; // Backpressure from output

    // Internal registers for delays
    logic [(COLOR_BITS*3)-1:0] tdata_delay;
    logic [(COLOR_BITS*3)-1:0] tdata_delay_single;
    logic [DELAY_CYCLES-1:0] tvalid_delay;
    logic [DELAY_CYCLES-1:0] tlast_delay;
    logic [DELAY_CYCLES-1:0] tuser_delay;

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            tvalid_delay <= '0;
            tlast_delay <= '0;
            tuser_delay <= '0;
            tdata_delay_single <= '0;
        end else if(!stall) begin
            tvalid_delay <= {tvalid_delay[DELAY_CYCLES-2:0], axi4s_in.tvalid};
            tlast_delay <= {tlast_delay[DELAY_CYCLES-2:0], axi4s_in.tlast};
            tuser_delay <= {tuser_delay[DELAY_CYCLES-2:0], axi4s_in.tuser};
            tdata_delay_single <= axi4s_in.tdata;
        end
    end

    // For tdata we use a linebuffer
    line_buffer #(
        .D_WIDTH(COLOR_BITS * 3),
        .LINE_LENGTH(DELAY_CYCLES) // Just a single pixel delay
    ) line_buffer_inst (
        .clk(aclk),
        .rst_n(areset_n),
        .pixel_in(axi4s_in.tdata),
        .pixel_valid(axi4s_in.tvalid),
        .pixel_out(tdata_delay),
        .pixel_out_valid() // We will use tvalid for validity, so ignore this
    );

assign axi4s_out.tdata = DELAY_CYCLES > 1 ? tdata_delay : tdata_delay_single;
assign axi4s_in.tready = axi4s_out.tready; // Apply backpressure from output to input
assign axi4s_out.tvalid = tvalid_delay[DELAY_CYCLES-1];
assign axi4s_out.tlast = tlast_delay[DELAY_CYCLES-1];
assign axi4s_out.tuser = tuser_delay[DELAY_CYCLES-1];

endmodule