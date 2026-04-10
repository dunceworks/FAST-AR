`timescale 1ns / 1ps
`default_nettype wire

//////////////////////////////////////////////////////////////////////////////////
// Company: UW-Madison
// Engineer: Henry Wysong-Grass
// 
// Create Date: 01/22/2026 04:01:39 PM
// Design Name: minilab0
// Module Name: minilab0
// Project Name: minilab0
// Target Devices: 
// Tool Versions: 
// Description: 8x8 ROM with one-hot address input and enable
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//  For non one-hot encodings, the default address address is 0
// 
//////////////////////////////////////////////////////////////////////////////////

module minilab0(
    input   logic clk,
    input   logic enable,
    input   logic [7:0]addr,        //One hot
    output  logic [7:0]dout
    );  

    // 8x8 ROM
    logic [7:0] rom [0:7];
    logic [2:0] addr_bin;


    //Random value for testing
    assign rom[0] = 8'hA3;
    assign rom[1] = 8'h5C;
    assign rom[2] = 8'h7E;
    assign rom[3] = 8'hF0;
    assign rom[4] = 8'h1B;
    assign rom[5] = 8'hC4;
    assign rom[6] = 8'h9D;
    assign rom[7] = 8'hE2;

    // Decode one-hot address to binary for 
    // indexing into ROM
    always_comb begin
        case (addr)
            8'b0000_0001: addr_bin = 3'b000;
            8'b0000_0010: addr_bin = 3'b001;
            8'b0000_0100: addr_bin = 3'b010;
            8'b0000_1000: addr_bin = 3'b011;
            8'b0001_0000: addr_bin = 3'b100;
            8'b0010_0000: addr_bin = 3'b101;
            8'b0100_0000: addr_bin = 3'b110;
            8'b1000_0000: addr_bin = 3'b111;
            default:      addr_bin = 3'b000; // Default case
        endcase
    end

    always_ff @(posedge clk) begin
        if (enable) begin
            dout <= rom[addr_bin];
        end
        else begin
            dout <= '0;
        end

    end
    


endmodule
