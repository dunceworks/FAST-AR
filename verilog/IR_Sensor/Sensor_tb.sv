////////////////////////////////////////////////////////////////// 
//
// File name: Sensor_tb.sv
// 
// Description: A testbench to test the internal modules of the IR sensor pipeline
//              Due to the nature of these modules, this testbench is not self checking and
//              and primarily for checking correct timings between signals. Actual output
//              is best tested on board.
//
// Created  : 2026-04-14
// Modified : 2026-04-14
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     []
//
///////////////////////////////////////////////////////////////////
`default_nettype none

module Sensor_tb();

    // Testbench signals
    logic clk;
    logic rst_n;
    logic sensor;
    logic bit_clk_fall;
    logic word_clk_rise;
    logic word_clk_fall;
    logic bit_clk;
    logic word_clk;
    logic [15:0] audio_data;
    logic I2S_data_out;

    // Clock Generator instantiation
    Clock_Gen iDUT_clock_gen(
        .clk(clk),
        .rst_n(rst_n),
        .bit_clk(bit_clk),
        .word_clk(word_clk),
        .bclk_fall_tick(bit_clk_fall),
        .wclk_rise_tick(word_clk_rise),
        .wclk_fall_tick(word_clk_fall)
    );

    // Instantiate wave generator
    Wave_Generator iDUT_wave_gen(
        .clk(clk),
        .rst_n(rst_n),
        .tick_48khz(word_clk_fall),
        .sensor(sensor),
        .data(audio_data)
    );

    // Instantiate the I2S transmitter (communication with the audio codec)
    I2S_Transmitter iDUT_I2S(
        .clk(clk),
        .bit_clk(bit_clk),
        .word_clk_rise(word_clk_rise),
        .word_clk_fall(word_clk_fall),
        .data_in(audio_data),
        .rst_n(rst_n),
        .data_out(I2S_data_out)
    );

    initial begin
        // Signal initialization
        clk = 0;
        rst_n = 0;
        sensor = 0;

        repeat (10) @(negedge clk);

        rst_n = 1;

        repeat (100) @(negedge clk);

        sensor = 1;

        repeat (10000) @(negedge clk);

        repeat (5000) @(negedge clk);

        $display("Simulation finished. Inspect waveforms.");
        $stop;
    end

    always #5 clk = ~clk; // clock gen

endmodule