////////////////////////////////////////////////////////////////// 
//
// File name: I2C_Config.sv
// 
// Description: Module to configure the audio codec
//
// Created  : 2026-04-09
// Modified : 2026-04-10
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     []
// Tested?      []
//
///////////////////////////////////////////////////////////////////

`default_nettype none

module I2C_Config (
    input  wire clk,         // Your 100MHz PL clock
    input  wire rst_n,       // Active-low reset
    
    // Codec I2C Pins (F5 and G5 on your board)
    inout  wire I2C_AIC_SDA, 
    output wire I2C_AIC_SCL, 
    output reg  AIC_nRST,    // Codec reset pin (E2)
    
    output reg  config_done  // Goes high when finished
);

    // TLV320 I2C Address (7-bit) + Write bit (0) = 8 bits total
    localparam CODEC_WRITE_ADDR = 8'b0011000_0; 

    // --- 1. CLOCK DIVIDER ---
    // I2C is slow (100 kHz). We divide our 100MHz clock by 1000.
    reg [9:0] clk_div;
    reg i2c_en; // Pulses at 100kHz
    
    always @(posedge clk) begin
        if (clk_div == 999) begin
            clk_div <= 0;
            i2c_en <= 1;
        end else begin
            clk_div <= clk_div + 1;
            i2c_en <= 0;
        end
    end

    // --- 2. CONFIGURATION ROM ---
    // Store your Register Addresses and Data here.
    // Example: 4 commands total (Change NUM_CMDS as needed)
    localparam NUM_CMDS = 21;
    reg [15:0] rom [0:NUM_CMDS-1];
    
    initial begin
        // --- 1. INITIALIZATION & CLOCKS ---
        rom[0]  = 16'h0000; // Select Page 0
        rom[1]  = 16'h01_01; // Software Reset (Wakes up the chip)
        
        // Assume FPGA provides MCLK. Route MCLK directly to the Codec Clock.
        rom[2]  = 16'h04_00; // Clock Setting: PLL Off, Codec_Clk = MCLK
        rom[3]  = 16'h1B_00; // Audio Interface: I2S mode, 16-bit data, Codec is Slave

        // --- 2. DIGITAL PROCESSING SETUP ---
        rom[4]  = 16'h0B_81; // Power up NDAC divider (Value = 1)
        rom[5]  = 16'h0C_82; // Power up MDAC divider (Value = 2)
        rom[6]  = 16'h0D_00; // DOSR (Oversampling) MSB = 0
        rom[7]  = 16'h0E_80; // DOSR LSB = 128
        rom[8]  = 16'h3C_08; // Select standard DAC Signal Processing Block (PRB_P8)

        // --- 3. ANALOG & POWER SETUP ---
        rom[9]  = 16'h00_01; // Select Page 1 (Analog registers)
        rom[10] = 16'h01_08; // Disable internal crude AVdd (AUP-ZU3 provides clean 3.3V)
        rom[11] = 16'h02_01; // Enable Master Analog Power Control
        rom[12] = 16'h7B_01; // Set reference charging time to 40ms

        // --- 4. LINE OUT (LOL / LOR) ROUTING ---
        // Instead of routing to Headphones, we route to the AUP-ZU3's green audio jack
        rom[13] = 16'h0E_08; // Route Left DAC output to LOL
        rom[14] = 16'h0F_08; // Route Right DAC output to LOR
        rom[15] = 16'h12_00; // Unmute LOL, set gain to 0dB
        rom[16] = 16'h13_00; // Unmute LOR, set gain to 0dB
        rom[17] = 16'h09_0C; // Power up the LOL and LOR amplifiers (Bits 3 and 2)

        // --- 5. TURN ON THE AUDIO ---
        rom[18] = 16'h00_00; // Select Page 0 again
        rom[19] = 16'h3F_D6; // Power up Left & Right DACs, route I2S Left/Right channels respectively
        rom[20] = 16'h40_00; // Unmute the DAC Digital Volume Control
    end

    // --- 3. STATE MACHINE ---
    reg [4:0] state;
    reg [7:0] cmd_index;   // Which ROM command we are on
    reg [4:0] bit_count;   // Counting 8 bits for data shifting
    reg [7:0] shift_reg;   // Holds the current byte being shifted out
    
    // Open-Drain driving for SDA (Never drive 1, only pull 0 or float Z)
    reg sda_out;
    assign I2C_AIC_SDA = (sda_out == 0) ? 1'b0 : 1'bz;
    
    // Simple SCL driving
    reg scl_out;
    assign I2C_AIC_SCL = scl_out;

    localparam S_RESET = 0, S_START = 1, S_SEND_DEV_ADDR = 2, S_ACK1 = 3;
    localparam S_SEND_REG_ADDR = 4, S_ACK2 = 5, S_SEND_DATA = 6, S_ACK3 = 7;
    localparam S_STOP = 8, S_DONE = 9;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_RESET;
            cmd_index <= 0;
            sda_out <= 1;
            scl_out <= 1;
            AIC_nRST <= 0; // Hold codec in reset
            config_done <= 0;
        end else if (i2c_en) begin
            
            case (state)
                S_RESET: begin
                    AIC_nRST <= 1; // Release codec reset
                    state <= S_START;
                end
                
                S_START: begin
                    sda_out <= 0; // SDA goes low while SCL is high
                    scl_out <= 1;
                    shift_reg <= CODEC_WRITE_ADDR;
                    bit_count <= 7;
                    state <= S_SEND_DEV_ADDR;
                end
                
                S_SEND_DEV_ADDR: begin
                    scl_out <= 0; // Pull clock low to change data
                    sda_out <= shift_reg[bit_count]; // Shift MSB first
                    
                    if (bit_count == 0) state <= S_ACK1;
                    else bit_count <= bit_count - 1;
                end
                
                S_ACK1: begin // Ignore ACK for simplicity in this template
                    scl_out <= 1; // Clock the ACK
                    shift_reg <= rom[cmd_index][15:8]; // Load Register Address
                    bit_count <= 7;
                    state <= S_SEND_REG_ADDR;
                end
                
                S_SEND_REG_ADDR: begin
                    scl_out <= 0; 
                    sda_out <= shift_reg[bit_count]; 
                    
                    if (bit_count == 0) state <= S_ACK2;
                    else bit_count <= bit_count - 1;
                end
                
                S_ACK2: begin
                    scl_out <= 1; 
                    shift_reg <= rom[cmd_index][7:0]; // Load Data
                    bit_count <= 7;
                    state <= S_SEND_DATA;
                end
                
                S_SEND_DATA: begin
                    scl_out <= 0; 
                    sda_out <= shift_reg[bit_count]; 
                    
                    if (bit_count == 0) state <= S_ACK3;
                    else bit_count <= bit_count - 1;
                end
                
                S_ACK3: begin
                    scl_out <= 1; 
                    state <= S_STOP;
                end
                
                S_STOP: begin
                    scl_out <= 1;
                    sda_out <= 1; // SDA goes high while SCL is high (Stop condition)
                    
                    if (cmd_index == NUM_CMDS - 1) begin
                        state <= S_DONE;
                    end else begin
                        cmd_index <= cmd_index + 1;
                        state <= S_START; // Loop back for next command
                    end
                end
                
                S_DONE: begin
                    config_done <= 1; // Tell the rest of your FPGA we are ready!
                end
            endcase
        end
    end
endmodule