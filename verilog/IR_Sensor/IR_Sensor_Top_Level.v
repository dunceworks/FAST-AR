////////////////////////////////////////////////////////////////// 
//
// File name: IR_Sensor_Top_Level.v
// 
// Description: This module connects all the modules related ot the IR sensor together
//
// Created  : 2026-04-16
// Modified : 2026-04-21
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     [X]
//
///////////////////////////////////////////////////////////////////
`default_nettype none

module IR_Sensor_Top_Level(
    input wire clk,
    input wire rst_n,
    input wire sensor,

    // I2C pins to setup codec
    output wire I2C_SCL,
    inout wire I2C_SDA,

    // I2S pins to exchange data
    output wire I2S_BCLK,
    output wire I2S_WCLK,
    output wire I2S_SDATA
);

    // Internal signals
    wire sensor_synch;
    wire word_clk_fall, word_clk_rise, bit_clk_fall;
    wire [15:0] audio data;

    // I2C setup
    I2C_Config u_i2c_setup(
        .clk(clk),
        .rst_n(rst_n),
        .I2C_SCL(I2C_SCL),
        .I2C_SDA(I2C_SDA)
    );

    // Internal "clk" generator
    Clock_Gen u_clk_gen(
        .clk(clk),
        .rst_n(rst_n),
        .bit_clk(I2S_BCLK),
        .word_clk(I2S_WCLK),
        .bclk_fall_tick(bit_clk_fall),
        .word_clk_fall(wclk_fall_tick),
        .word_clk_rise(wclk_rise_tick)
    );

    // Sensor data synchronizer
    Sensor_Synchronizer u_synch(
        .clk(clk),
        .rst_n(rst_n),
        .sensor_raw(sensor),
        .sensor(sensor_synch)
    );

    // Tone generator
    Wave_Generator u_tone (
        .clk(clk),
        .rst_n(rst_n),
        .tick_48khz(word_clk_fall),
        .sensor(sensor_synch),
        .data(audio_data)
    );

    // I2S transmitter with the codec
    I2S_Transmitter u_i2s (
        .clk(clk),
        .rst_n(rst_n),
        .bit_clk(bit_clk_fall),
        .word_clk_fall(word_clk_fall),
        .word_clk_rise(word_clk_rise),
        .data_in(audio_data),
        .data_out(I2S_SDATA)
    );

endmodule