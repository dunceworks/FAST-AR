///////////////////////////////////////////////////////// 
//
// File name: downscaler_wrapper.sv
// 
// Description: Wrapper for the downscaler module.
//
// Created  : 2026-03-18
// Modified : 2026-03-19
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


module downscaler_wrapper (
    input wire aclk,
    input wire aresetn,

// Standard Xilinx Naming for Slave (Input)
    input  logic               s_axis_tvalid,
    input  logic        [23:0] s_axis_tdata,
    input  logic               s_axis_tlast,
    input  logic               s_axis_tuser,
    output logic               s_axis_tready,
    
    // Standard Xilinx Naming for Master (Output)
    output logic               m_axis_tvalid,
    output logic        [23:0] m_axis_tdata,
    output logic               m_axis_tlast,
    output logic               m_axis_tuser,
    input  logic               m_axis_tready
);

    axi4s_vid_if axi4s_in();
    axi4s_vid_if axi4s_out();

    // Just flattening so that vivado stops throwing fits at me
    // when packaging IP... maybe a lot more of these to come.
    assign axi4s_in.tvalid = s_axis_tvalid;
    assign axi4s_in.tdata  = s_axis_tdata;
    assign axi4s_in.tlast  = s_axis_tlast;
    assign axi4s_in.tuser  = s_axis_tuser;
    assign s_axis_tready   = axi4s_in.tready;

    assign m_axis_tvalid   = axi4s_out.tvalid;
    assign m_axis_tdata    = axi4s_out.tdata;
    assign m_axis_tlast    = axi4s_out.tlast;
    assign m_axis_tuser    = axi4s_out.tuser;
    assign axi4s_out.tready= m_axis_tready;

    // Instantiate the downscaler
    downscaler #(
        .IMG_WIDTH(1920),
        .IMG_HEIGHT(1080)
    ) downscaler_inst (
        .aclk(aclk),
        .areset_n(aresetn),
        .axi4s_in(axi4s_in),
        .axi4s_out(axi4s_out)
    );


endmodule