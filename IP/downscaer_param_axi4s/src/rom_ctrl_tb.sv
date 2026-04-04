`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 04:38:34 PM
// Design Name: 
// Module Name: rom_ctrl_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rom_ctrl_tb();

    logic clk;
    logic enable;
    logic [7:0] addr;
    logic [7:0] dout;

    int failed = 0;
    int total = 0;


    //Expected values
    logic [7:0] rom [0:7];
    initial begin
        rom[0] = 8'hA3;
        rom[1] = 8'h5C;
        rom[2] = 8'h7E;
        rom[3] = 8'hF0;
        rom[4] = 8'h1B;
        rom[5] = 8'hC4;
        rom[6] = 8'h9D;
        rom[7] = 8'hE2;
    end

    //Instantiate DUT
    minilab0 iDUT (.clk(clk),
                   .enable(enable),
                   .addr(addr),
                   .dout(dout)
                   );



initial begin
    clk = 0;
    addr = 8'b0000_0001;
    enable = 0;

    //Test expected behavior
    for (int i = 0; i < 8; i++) begin
        @(negedge clk);
        addr = 8'b0000_0001 << i;
        enable = 1;

        // Check output
        @(negedge clk);
        total++;
        if (dout !== rom[i]) begin
            $display("Test failed for addr %0d: expected %h, got %h", i, rom[i], dout);
            failed++;
        end

        @(negedge clk);
        enable = 0;
        @(negedge clk);
        total++;
        if (dout !== 8'h00) begin
            $display("Test failed for addr %0d: expected 0x00, got %h", i, dout);
            failed++;
        end
    end

    //Test edge case (invalid address) should output value stored at addr 0
    @(negedge clk);
    addr = 8'b0000_0000; // Invalid one-hot
    enable = 1;
    @(negedge clk);
    total++;
    if (dout !== rom[0]) begin
        $display("Test failed for invalid addr: expected %h, got %h", rom[0], dout);
        failed++;
    end

    repeat(2)@(negedge clk);
    addr = 8'b1111_1111; // Invalid one-hot
    enable = 1;
    @(negedge clk);
    total++;
    if (dout !== rom[0]) begin
        $display("Test failed for invalid addr: expected %h, got %h", rom[0], dout);
        failed++;
    end


    if (failed == 0)
        $display("Yahoo!! All tests passed! %0d/%0d", total, total);
    else
        $display("%0d/%0d tests failed. Back to the mines...", failed, total);
    $stop;
end

always #5 clk <= ~clk;


endmodule
