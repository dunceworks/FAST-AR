///////////////////////////////////////////////////////// 
//
// File name: grayscale_tb.sv
// 
// Description: Testbench for the grayscale module.
//
// Created  : 2026-03-08
// Modified : 2026-03-08
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [ ]
//
////////////////////////////////////////////////////////

`default_nettype none

module grayscale_tb();

// Interfaces
axi4s_vid_if axi4s_in_intf ();
axi4s_vid_if axi4s_out_intf ();

// Testbench signals
logic clk;
logic reset_n;


//Instantiate DUT
grayscale #(
        .COLOR_BITS(8)
    ) iDUT (
        .aclk(clk),
        .areset_n(reset_n),
        .axi4s_in(axi4s_in_intf),   // SV automatically hooks this up to the .dom modport
        .axi4s_out(axi4s_out_intf)  // SV automatically hooks this up to the .sub modport
    );


initial begin
    // Default signals
    clk = 0;        
    reset_n = 0;    // reset
    



end


always #5 clk = ~clk; // clock gen

endmodule