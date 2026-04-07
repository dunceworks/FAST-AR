`default_nettype none

module Gyro_Integrator
#(
    parameter SCALE = 16'd655
)(
    input logic clk,
    input logic rst,
    input logic sample_valid,
    input logic signed [15:0] gyro_z_raw,
    output logic signed [31:0] heading_angle
);

    logic signed [31:0] delta;

    always_comb begin
        delta = gyro_z_raw * SCALE;
    end
    

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            heading_angle <= 32'd0;
        end else if (sample_valid) begin
            heading_angle <= heading_angle + delta;
        end
        
    end

endmodule