///////////////////////////////////////////////////////// 
//
// File name: AXI4-Stream_Combine_wrapper.sv
// 
// Description: Wrapper for the AXI4-Stream Combine module
//
// Created  : 2026-04-11
// Modified : 2026-04-11
// Author   : Wysong
//
// Team     : Dunce Works
//
// AI Disclosure: This is a wrapper. Hopefully that says enough :P
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////


module AXI4_Stream_Combine_wrapper #(
    parameter COLOR_BITS = 8
    )
    (
    input wire aclk,
    input wire aresetn,

    // Input 0 (RGB)
    input  wire               s_axis_tvalid0,
    input  wire        [23:0] s_axis_tdata0,
    input  wire               s_axis_tlast0,
    input  wire               s_axis_tuser0,
    output wire               s_axis_tready0,

    // Input 1 (Edge)
    input  wire               s_axis_tvalid1,
    input  wire        [23:0] s_axis_tdata1,
    input  wire               s_axis_tlast1,
    input  wire               s_axis_tuser1,
    output wire               s_axis_tready1,
    
    // Standard Xilinx Naming for Master (Output)
    output wire               m_axis_tvalid,
    output wire        [23:0] m_axis_tdata,
    output wire               m_axis_tlast,
    output wire               m_axis_tuser,
    input  wire               m_axis_tready
);

    axi4s_vid_if axi4s_in0();
    axi4s_vid_if axi4s_in1();
    axi4s_vid_if axi4s_out();

    // Just flattening so that vivado stops throwing fits at me
    // when packaging IP... maybe a lot more of these to come.
    assign axi4s_in0.tvalid = s_axis_tvalid0;
    assign axi4s_in0.tdata  = s_axis_tdata0;
    assign axi4s_in0.tlast  = s_axis_tlast0;
    assign axi4s_in0.tuser  = s_axis_tuser0;
    assign s_axis_tready0   = axi4s_in0.tready;

    assign axi4s_in1.tvalid = s_axis_tvalid1;
    assign axi4s_in1.tdata  = s_axis_tdata1;
    assign axi4s_in1.tlast  = s_axis_tlast1;
    assign axi4s_in1.tuser  = s_axis_tuser1;
    assign s_axis_tready1   = axi4s_in1.tready;

    assign m_axis_tvalid   = axi4s_out.tvalid;
    assign m_axis_tdata    = axi4s_out.tdata;
    assign m_axis_tlast    = axi4s_out.tlast;
    assign m_axis_tuser    = axi4s_out.tuser;
    assign axi4s_out.tready= m_axis_tready;

    // Instantiate the module and hook it up.
    combine #(
        .COLOR_BITS(COLOR_BITS)
    ) combine_inst (
        .aclk(aclk),
        .areset_n(aresetn),
        .axi4s_RGB_in(axi4s_in0),
        .axi4s_edge_in(axi4s_in1),
        .axi4s_out(axi4s_out)
    );


endmodule