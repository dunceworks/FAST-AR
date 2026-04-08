`default_nettype none

module Sin_Cos_LUT
(
    input wire clk,
    input wire signed [7:0] heading_angle,
    output reg signed [15:0] sin_out,
    output reg signed [15:0] cos_out
);

    logic signed [15:0] sin_table [0:255];

    initial begin
        $readmemh("sin_table.mem", sin_table);
    end

    always_ff @(posedge clk) begin
        sin_out <= sin_table[heading_angle];
        cos_out <= sin_table[heading_angle + 8'd64];  // cos(*) = sin(* + 90)
    end

endmodule