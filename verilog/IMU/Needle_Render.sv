`default_nettype none

module Needle_Render
#(
    parameter LENGTH = 128,  // Length of the needle in pixels
    parameter WIDTH = 10  // Thickness of the needle in pixels
)(
    input wire clk,

    input wire [11:0] pixel_x,  // Current pixel x value
    input wire [11:0] pixel_y,  // Current pixel y value

    input wire [11:0] center_x, // Compass center x value
    input wire [11:0] center_y, // Compass center y value

    input wire [15:0] sin_theta,
    input wire [15:0] cos_theta,

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

    logic signed [16:0] distance;
    logic signed [16:0] along;

    always_comb begin
        distance  = (dx_sin - dy_cos) >>> 15;
        along = (dx_cos + dy_sin) >>> 15;
    end

    logic signed [16:0] abs_dist;

    always_comb begin
        if (distance < 0)
            abs_dist = -distance;
        else
            abs_dist = distance;
    end

    always_comb begin
        if (abs_dist < WIDTH && along > 0 && along < LENGTH)
            needle_pixel = 1;
        else
            needle_pixel = 0;
    end

endmodule