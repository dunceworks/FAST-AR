///////////////////////////////////////////////////////// 
//
// File name: Compass_tb.sv
// 
// Description: Testbench for Compass Ring module
//
// Created  : 2026-03-26
// Modified : 2026-03-26
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     [X]
//
////////////////////////////////////////////////////////
`default_nettype none

module Compass_tb();

    // Local params
    parameter IMG_W = 256,
    parameter IMG_H = 256,
    parameter SCREEN_W = 1920,
    parameter SCREEN_H = 1080

    // testbench signals
    logic clk;
    logic rreset_n;

    logic [11:0] pixel_x;
    logic [11:0] pixel_y;

    logic [11:0] center_x;
    logic [11:0] center_y;

    logic [23:0] sprite_rgb;
    logic sprite_valid;

    // Instantiate DUT
    Compass_Sprite #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .SCREEN_W(SCREEN_W),
        .SCREEN_H(SCREEN_H)
    ) iDUT (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .center_x(center_x),
        .center_y(center_y),
        .sprite_rgb(sprite_rgb),
        .sprite_valid(sprite_valid)
    );

    initial begin
        // Default signals
        clk = 0;
        reset_n = 0;

        center_x = IMG_W/2;
        center_y = IMG_H/2;

        // Open file
        file = $fopen("compass.hex", "w");

        // Write PPM header
        $fwrite(file, "P3\n");
        $fwrite(file, "%0d %0d\n", IMG_W, IMG_H);
        $fwrite(file, "255\n");

        // Wait a couple cycles
        repeat (5) @(posedge clk);

        // -------------------------
        // Scan all pixels
        // -------------------------
        for (int y = 0; y < IMG_H; y++) begin
            for (int x = 0; x < IMG_W; x++) begin

                pixel_x = x;
                pixel_y = y;

                @(posedge clk);
                @(posedge clk); 

                if (sprite_valid)
                    $fwrite(file, "%06x\n", sprite_rgb);
                else
                    $fwrite(file, "%06x\n", 24'h000000);
            end
            $fwrite(file, "\n");
        end

        $fclose(file);

        $display("Image written to compass.hex");

        $finish;
    end

    always #5 clk = ~clk; // clock gen

endmodule