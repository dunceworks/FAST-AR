`default_nettype none

module Needle_Render
#(
    parameter LENGTH = 100,  // Length of the needle in pixels
    parameter WIDTH = 8  // Thickness of the needle in pixels
)(
    input logic clk,

    input logic [11:0] pixel_x,  // Current pixel x value
    input logic [11:0] pixel_y,  // Current pixel y value

    input logic [11:0] center_x, // Compass center x value
    input logic [11:0] center_y, // Compass center y value

    input logic [15:0] sin_theta,
    input logic [15:0] cose_theta

    output logic needle_pixel
);

    ////////////////////////////////
    // Distance from center pixel //
    ////////////////////////////////
    logic signed [12:0] dx, dy;

    always_comb begin
        dx = $signed(pixel_x) - $signed(center_x);
        dy = $signed(pixel_y) - $signed(center_y);
    end

    ///////////////////////////
    // Calculate Dot product //
    ///////////////////////////

    logic signed [31:0] dx_sin, dy_cos;
    logic signed [31:0] dx_cos, dy_sin;

    always_comb begin
        dx_sin = dx * sin_theta;
        dy_cos = dy * cos_theta;
        dx_cos = dx * cos_theta;
        dy_sin = dy * sin_theta;
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Calculate distance and projection of the pixel to the needle line in order to see if the current pixel //
    // should be colored as part of the needle.                                                               //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic signed [16:0] dist;
    logic signed [16:0] along;

    always_comb begin
        dist  = (dx_sin - dy_cos) >>> 15;
        along = (dx_cos + dy_sin) >>> 15;
    end

    logic signed [16:0] abs_dist;

    always_comb begin
        if (dist < 0)
            abs_dist = -dist;
        else
            abs_dist = dist;
    end

    always_comb begin
        if (abs_dist < WIDTH && along > 0 && along < LENGTH)
            needle_pixel = 1;
        else
            needle_pixel = 0;
    end

endmodule