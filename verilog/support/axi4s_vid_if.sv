///////////////////////////////////////////////////////// 
//
// File name: axi4s_vid_if.sv
// 
// Description: AXI4-Stream video interface definition.
//
// Created  : 2026-03-02
// Modified : 2026-03-02
// Author   : Wysong
//
// Team     : Dunce Works
//
////////////////////////////////////////////////////////

interface axi4s_vid_if #(parameter D_WIDTH = 24);
    logic                tvalid;
    logic [D_WIDTH-1:0]  tdata;
    logic                tlast;
    logic                tuser;
    logic                tready;

    // The Manager (Source/Dom) drives data out
    modport dom (
        output tvalid, tdata, tlast, tuser,
        input  tready
    );

    // The Subordinate (Sink/Sub) receives data in
    modport sub (
        input  tvalid, tdata, tlast, tuser,
        output tready
    );
endinterface