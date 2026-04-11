///////////////////////////////////////////////////////// 
//
// File name: line_buffer.sv
// 
// Description: Line buffer module that stores a line of pixels and outputs them in a streaming fashion.
//              Optimized to use BRAM instead of a mega f***ton of LUTs
//
// Created  : 2026-03-02
// Modified : 2026-03-02
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

module line_buffer #(
    parameter D_WIDTH = 24, // Data width (e.g., 24 for RGB888 )
    parameter LINE_LENGTH = 1920 // Number of pixels in a line (1920 for 1080p)
)
(
    input wire clk, // Clock signal
    input wire rst_n, // Active low reset
    input wire [D_WIDTH-1:0] pixel_in, // Input pixel data
    input wire pixel_valid, // Indicates that pixel_in is valid (same as WE)
    output reg [D_WIDTH-1:0] pixel_out // Output pixel data

);


    // Internal line buffer storage
    (* ram_style = "block" *) reg [D_WIDTH-1:0] line_buffer [0:LINE_LENGTH-1];    // learned about this attribute. Lets hope it works :P (thanks vivado)
    reg [$clog2(LINE_LENGTH)-1:0] write_ptr;            // Write pointer (enough bits to address LINE_LENGTH)
    reg [$clog2(LINE_LENGTH)-1:0] read_ptr;            // read pointer (enough bits to address LINE_LENGTH)

    always_ff @(posedge clk) begin
        if (pixel_valid) begin
            // Write incoming pixel to the line buffer
            line_buffer[write_ptr] <= pixel_in;

            // Output the pixel from the line buffer
            pixel_out <= line_buffer[read_ptr];
        end
    end

    // Separating the counters 
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 1;
        end else if (pixel_valid) begin
            if (write_ptr == LINE_LENGTH - 1)
                write_ptr <= 0; // Wrap around after reaching the end of the line
            else 
                write_ptr <= write_ptr + 1;
            
            if (read_ptr == LINE_LENGTH - 1) 
                read_ptr <= 0; // Wrap around after reaching the end of the line
            else 
                read_ptr <= read_ptr + 1;            
        end
    end

endmodule