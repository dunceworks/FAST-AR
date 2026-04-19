/////////////////////////////////////////////////////////  SIMULATION ONLY FILE
//
// File name: axi4s_checker.sv                             SIMULATION ONLY FILE
// 
// Description: Checks the output of an AXI4-Stream to detect violations or unexpected behavior.
//              IDK why I didn't do this before... probably would have saved me debugging time.         SIMULATION ONLY
//
// Created  : 2026-04-16
// Modified : 2026-05-16
// Author   : Wysong
//
// Team     : Dunce Works
//
// AI Disclosure: No AI was used in th writing of this code. or evidently that last sentence.
//
// Written?     [X]
// SW Tested?   [X]
//
/////////////////////////////////////////////////////////  SIMULATION ONLY FILE


module axi4s_checker #(
    parameter EXPECTED_WIDTH,
    parameter EXPECTED_HEIGHT
)(

    input aclk,
    input areset_n,

    input RANDOM_STALL,         //assert whenever you want to try and break stuff

    axi4s_vid_if.master axi4s_in    // No axi out. Terminates here :D
);

parameter DIMENSION = $clog2(EXPECTED_WIDTH);

//Internal counters. Nothing elegant here. Coming off a long day.
logic [DIMENSION+1:0] x_counter;
logic [DIMENSION+1:0] y_counter;

always_ff @(posedge aclk or negedge areset_n) begin
    if(areset_n)
        x_counter <= '0;


    else if (axi4s_in.tvalid && axi4s_in.tready) begin

        if(axi4s_in.tuser) begin
            x_counter <= '0;
            y_counter <= '0;
        end
        else if (axi4s_in.tlast) begin
            if (x_counter != EXPECTED_WIDTH)
                $display("Error: Expected width of %0d, but got %0d at line %0d", EXPECTED_WIDTH, x_counter, $line);
            x_counter <= '0;
            y_counter <= y_counter + 1;
            if (y_counter == EXPECTED_HEIGHT) begin
                $display("Info: Reached expected height of %0d at line %0d", EXPECTED_HEIGHT, $line);
                y_counter <= '0; // Reset for next frame
            end
        end
        else
            x_counter <= x_counter + 1;

    end

end




endmodule