///////////////////////////////////////////////////////// 
//
// File name: axi4s_splitter.sv
// 
// Description: Splitter for AXI4-Stream interfaces - when a single interface is used for multiple data sources, 
//              this module combines their tready signals. Used at the head of a pipeline to allow multiple modules to read from the same input.
//
// Created  : 2026-03-09
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [X]
//
////////////////////////////////////////////////////////

module axi4s_splitter #(
    parameter COLOR_BITS = 8
)(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_in,
    axi4s_vid_if.sub axi4s_out1,
    axi4s_vid_if.sub axi4s_out2

);

    assign axi4s_out1.tdata = axi4s_in.tdata;
    assign axi4s_out1.tvalid = axi4s_in.tvalid;
    assign axi4s_out1.tlast = axi4s_in.tlast;
    assign axi4s_out1.tuser = axi4s_in.tuser;

    assign axi4s_out2.tdata = axi4s_in.tdata;
    assign axi4s_out2.tvalid = axi4s_in.tvalid;
    assign axi4s_out2.tlast = axi4s_in.tlast;
    assign axi4s_out2.tuser = axi4s_in.tuser;

    // Combine tready signals - only ready when both outputs are ready
    assign axi4s_in.tready = axi4s_out1.tready && axi4s_out2.tready;
endmodule