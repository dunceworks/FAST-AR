////////////////////////////////////////////////////////////////// 
//
// File name: Wave_Generator.sv
// 
// Description: Module to generate the sound data
//
// Created  : 2026-04-10
// Modified : 2026-04-12
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     [X]
// Tested?      []
//
///////////////////////////////////////////////////////////////////
`default_nettype none

module Wave_Generator.sv(
    input wire clk,
    input wire rst_n,
    input wire tick_48khz,
    input wire sensor,
    output reg [15:0] data
);

reg [15:0] accumulator;
reg [15:0] rom [0:255];
reg [15:0] tune_word = 16'd601 // The tuning word determines the pitch of the beep.

// Load the beep sine wave rom
initial begin
    $readmemh("beep.mem", rom);
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        accumulator <= 0;
        data <= 0;
    end else if (tick_48khz) begin
        if (sensor) begin
            accumulator <= accumulator + tune_word;
            data <= rom[accumulator[15:8]];
        end else begin
            accumulator <= 0;
            data <= 0;
        end
    end
end

endmodule