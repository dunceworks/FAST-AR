///////////////////////////////////////////////////////// 
//
// File name: combine.sv
// 
// Description: Combines the edge detect and sharpened frame to produce the final sharpened wireframe image
//              basically just a mux that outputs neon green when on an edge and the sharpened image otherwise. 
//              Uses AXI4-Stream for I/O.
//
// Created  : 2026-03-01
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////

module combine #(
    parameter COLOR_BITS = 8
)
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.dom axi4s_RGB_in,
    axi4s_vid_if.dom axi4s_edge_in,
    axi4s_vid_if.sub axi4s_out

);
    logic [COLOR_BITS-1:0] r;
    logic [COLOR_BITS-1:0] g;
    logic [COLOR_BITS-1:0] b;
    logic [COLOR_BITS-1:0] data_out;   // 8-bit grayscale output

    logic tvalid_flopped;
    logic tlast_flopped;
    logic tready_flopped;
    logic tuser_flopped;

    // Meta signals
    logic stall, data_valid;    
    assign stall = !axi4s_out.tready;
    assign data_valid = axi4s_RGB_in.tvalid && axi4s_edge_in.tvalid; // valid when both inputs are valid


    logic use_edge;
    assign use_edge = axi4s_edge_in.tdata[15:8] != 0; // If strength is above threshold, consider it an edge

    // Add a single flop stage
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            tvalid_flopped <= 1'b0;
            tlast_flopped <= 1'b0;
            tready_flopped <= 1'b0;
            tuser_flopped <= 1'b0;
        end else if (!stall) begin
            tvalid_flopped <= axi4s_RGB_in.tvalid && axi4s_edge_in.tvalid; // valid when both inputs are valid
            tlast_flopped <= axi4s_RGB_in.tlast;
            tuser_flopped <= axi4s_RGB_in.tuser;
        end
    end

    // Output logic: if edge detected (edge_in > 128), output neon green, else output RGB



    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end else if (data_valid && !stall) begin
            r <= use_edge ? 8'h00 : axi4s_RGB_in.tdata[23:16]; // If edge detected, set R to 0, else pass through RGB input
            g <= use_edge ? axi4s_edge_in.tdata[15:8] : axi4s_RGB_in.tdata[15:8];  // If edge detected, set G to 255, else pass through RGB input
            b <= use_edge ? 8'h00 : axi4s_RGB_in.tdata[7:0];   // If edge detected, set B to 0, else pass through RGB input
        end
    end

    assign axi4s_out.tdata = {r, g, b};
    assign axi4s_out.tvalid = tvalid_flopped;

    assign axi4s_out.tlast = tlast_flopped;
    assign axi4s_out.tuser = tuser_flopped;


    assign axi4s_RGB_in.tready = data_valid ? axi4s_out.tready : 1'b1;    //tready flows *UP* the pipeline
    assign axi4s_edge_in.tready = data_valid ? axi4s_out.tready : 1'b1;    //tready flows *UP* the pipeline


endmodule