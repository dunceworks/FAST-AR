////////////////////////////////////////////////////////////////// 
//
// File name: I2S_Transmitter.sv
// 
// Description: Module to serially transmit sound data to the codec
//
// Created  : 2026-04-12
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

module I2S_Transmitter(
    input wire clk,
    input wire bit_clk,
    input wire word_clk_rise,
    input wire word_clk_fall,
    input wire [15:0] data_in,
    input wire rst_n,
    output reg data_out
);

    reg [15:0] shift_reg;
    reg [3:0] bit_cnt;

    always_ff @(posedge of clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'h00_00;
            bit_cnt <= 4'h0;
            data_out <= 0;
        end else begin
            if (word_clk_fall || word_clk_rise) begin
                shift_reg <= data_in;
                bit_cnt <= 16'hF;
            end else if (bit_clk) begin
                data_out <= shift_reg[15];
                shift_reg <= {shift_reg[14:0], 1'b0};

                if (bit_cnt > 0) begin
                    bit_cnt <= bit_cnt - 1;
                end
            end
        end
    end

endmodule