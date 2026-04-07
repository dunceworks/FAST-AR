`default_nettype none

module Compass_Sprite
#(
    parameter IMG_W = 256,  // Compass Sprite width
    parameter IMG_H = 256,  // Compass Sprite height
    parameter SCREEN_W = 1920,
    parameter SCREEN_H = 1080
)(
    input  logic clk,

    input  logic [11:0] pixel_x,
    input  logic [11:0] pixel_y,

    // position of sprite center on screen
    input  logic [11:0] center_x,
    input  logic [11:0] center_y,

    // outputs
    output logic [23:0] sprite_rgb,
    output logic        sprite_valid
);

    //////////////////////
    // Compass Ring ROM //
    //////////////////////

    logic [23:0] rom [0: IMG_W * IMG_H - 1];

    initial begin
        $readmemh("compass.mem", rom);
    end

    ///////////////////////////////////
    // Coordinates within the sprite //
    ///////////////////////////////////
    logic signed [12:0] relative_x, relative_y; // x and y coordinates relative to the center of the sprite space
    logic [11:0] sprite_x, sprite_y;

    always_comb begin
        relative_x = $signed(pixel_x) - $signed(center_x) + (IMG_W/2);
        relative_y = $signed(pixel_y) - $signed(center_y) + (IMG_H/2);

        sprite_x = relative_x[11:0];
        sprite_y = relative_y[11:0];
    end

    // Check if the current pixel is within the sprite's bounds
    logic inside;
    assign inside = (relative_x >= 0 && relative_x < IMG_W && relative_y >= 0 && relative_y < IMG_H);

    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Grab the rgb data from the ROM and if the current pixel is inside the ROM, then output its rgb data //
    // and the valid signal                                                                                //
    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb begin
        addr = sprite_y * IMG_W + sprite_x;
    end

    // -------------------------------
    // Output
    // -------------------------------
    always_ff @(posedge clk) begin
        if (inside) begin
            sprite_rgb   <= rom[addr];
            sprite_valid <= 1;
        end else begin
            sprite_rgb   <= 24'd0;
            sprite_valid <= 0;
        end
    end

endmodule