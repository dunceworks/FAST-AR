////////////////////////////////////////////////////////////////// 
//
// File name: Clock_Gen.sv
// 
// Description: Generates the clock signals used to interact with the audio codec
//
// Created  : 2026-04-14
// Modified : 2026-04-21
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     [X]
// Tested?      []
//
///////////////////////////////////////////////////////////////////
`default_nettype none
module Clock_Gen (
    input  wire clk,
    input  wire rst_n,

    // Physical pins that go straight out to the TLV320 Codec
    output reg  bit_clk,
    output reg  word_clk,

    // Internal 1-cycle pulses to drive other modules
    output reg  bclk_fall_tick,
    output reg  wclk_rise_tick,
    output reg  wclk_fall_tick
);

    reg [6:0] bclk_div_cnt; // Counts 0 to 64 (65 total cycles)
    reg [4:0] bit_cnt;      // Counts 0 to 31 (32 bits per stereo frame)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_div_cnt <= 0;
            bit_cnt <= 0;
            bit_clk <= 0;
            word_clk <= 0;
            bclk_fall_tick <= 0;
            wclk_rise_tick <= 0;
            wclk_fall_tick <= 0;
            
        end else begin
            
            // 1. Default state: Ticks are 1 cycle pulses
            bclk_fall_tick <= 0;
            wclk_rise_tick <= 0;
            wclk_fall_tick <= 0;

            // 2. The Master Divider (Counts to 64)
            if (bclk_div_cnt == 64) begin
                bclk_div_cnt <= 0;
            end else begin
                bclk_div_cnt <= bclk_div_cnt + 1;
            end

            // 3. Generate the physical clocks and internal ticks
            if (bclk_div_cnt == 0) begin
                bit_clk <= 1'b1; // Rising edge of physical Bit Clock
                
            end else if (bclk_div_cnt == 32) begin
                bit_clk <= 1'b0; // Falling edge of physical Bit Clock
                
                // Send out the bit clock tick
                bclk_fall_tick <= 1'b1; 
                
                // Track where we are in the 32-bit audio frame
                bit_cnt <= bit_cnt + 1;

                // I2S Standard: Word Clock toggles on the falling edge of the bit clock
                if (bit_cnt == 15) begin
                    word_clk <= 1'b1;       // Right Channel Start
                    wclk_rise_tick <= 1'b1; // Tell the Transmitter
                    
                end else if (bit_cnt == 31) begin
                    word_clk <= 1'b0;       // Left Channel Start
                    wclk_fall_tick <= 1'b1; // Tell the Transmitter
                end
            end
        end
    end
endmodule