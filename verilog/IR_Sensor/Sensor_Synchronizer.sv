////////////////////////////////////////////////////////////////// 
//
// File name: Sensor_Synchronizer.sv
// 
// Description: Module synchronizing the asynchronous sensor input
//
// Created  : 2026-04-09
// Modified : 2026-04-09
// Author(s): Cadiena
//
// Team     : Dunce Works
//
// Written?     [X]
// Tested?      []
//
///////////////////////////////////////////////////////////////////
`default_nettype none

module Sensor_Synchronizer(
    input wire clk,
    input wire rst_n,
    input wire sensor_raw,
    output reg sensor
);

//(* ASYNC_REG = "TRUE" *) reg ff0, ff1, sensor;
reg ff0, ff1;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ff0 <= 0;
        ff1 <= 0;
        sensor <= 0;
    end else begin
        ff0 <= sensor_raw;
        ff1 <= ff0;
        sensor <= ff1;
    end
end

endmodule