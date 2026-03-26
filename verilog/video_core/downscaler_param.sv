`default_nettype none

///////////////////////////////////////////////////////// 
//
// File name: downscaler.sv
// 
// Description: Downsizes the image to 128 dimensions.
//
// Created  : 2026-03-18
// Modified : 2026-03-25
// Author   : Wysong
//
// Team     : Dunce Works
//
// AI Disclosure: This code was initially written without AI assistance (not including small auto-completions - think small instantiations).
//                During debugging, Copilot was used to point out potential issues but not used to write any code. 
//                Comments written by the author.
//
// Written?     [X]
// SW Tested?   [X]
// HW Tested?   [ ]
//
////////////////////////////////////////////////////////


module downscaler #(
    parameter OUT_SIZE = 128,
    parameter DOWNSCALE_FACTOR = 8 // must be a power of 2: how many pixels we interpolate eg. 8 is 8x8 grid (up to user to check that this works...)
) 
(
    input wire aclk,
    input wire areset_n,

    axi4s_vid_if.master axi4s_out, //May have to swap these around again
    axi4s_vid_if.slave axi4s_in
);

    // Lotsa params to help calculate the cropping and downscaling.
    // especially for 
    localparam IMG_WIDTH = 1920;
    localparam IMG_HEIGHT = 1080;
    localparam BASE2_DS = $clog2(DOWNSCALE_FACTOR); // use for bit shifts
    localparam NUM_INTERPOL_ELEMS = DOWNSCALE_FACTOR * DOWNSCALE_FACTOR; // eg. 64 for 8x8
    localparam NUM_STAGES = $clog2(NUM_INTERPOL_ELEMS); // # stages in adder tree - log2(# interpolate elements)

    // Square size is basically user defined...
    localparam SQUARE_SIZE = OUT_SIZE * DOWNSCALE_FACTOR;

    localparam LEFT_CROP_STOP = (IMG_WIDTH - SQUARE_SIZE) / 2; // Hard to name these things but this is where we STOP cropping
    localparam RIGHT_CROP_START = LEFT_CROP_STOP + SQUARE_SIZE; //And this is where we START back up cropping
    localparam TOP_CROP_STOP = (IMG_HEIGHT - SQUARE_SIZE) / 2;
    localparam BOTTOM_CROP_START = TOP_CROP_STOP + SQUARE_SIZE;




    //////////////////////
    // INTERNAL SIGNALS //
    //////////////////////

    // Counter signals
    logic [$clog2(IMG_WIDTH)-1:0] x_count; // H pixel counter
    logic [$clog2(IMG_HEIGHT)-1:0] y_count; // V pixel counter
    logic x_valid, y_valid, not_cropping, interpolate;

    // Line buffer outputs
    logic [23:0] lbo [0:DOWNSCALE_FACTOR];

    // Adder tree things
    logic [23:0] pix_mat [0:DOWNSCALE_FACTOR-1][0:DOWNSCALE_FACTOR-1]; // 8x8 matrix to downscale
    logic [26:0] sum_r [0:NUM_STAGES][0:DOWNSCALE_FACTOR*DOWNSCALE_FACTOR-1];
    logic [26:0] sum_g [0:NUM_STAGES][0:DOWNSCALE_FACTOR*DOWNSCALE_FACTOR-1];
    logic [26:0] sum_b [0:NUM_STAGES][0:DOWNSCALE_FACTOR*DOWNSCALE_FACTOR-1];
    logic [23:0] avg_pixel; // Output pixel

    // AXI4-Stream delay registers (6 cycle compensation)
    // Just a simple shift reg style
    logic [5:0]tvalid_d;
    logic [5:0]tlast_d;
    logic [5:0]tuser_d;


    // Stall/pressure sig
    logic stall;
    assign stall = !axi4s_out.tready; // Backpressure from output
    

    assign lbo[0] = axi4s_in.tdata;



    //////////////////////////////
    // ROW BUFFER INSTANTIATION //
    //////////////////////////////
    // Yeah this was the most efficent way to do this... :D (this makes sense if you read the old version)

    genvar lbs;
    generate
        for(lbs = 0; lbs < DOWNSCALE_FACTOR; lbs++) begin
                line_buffer #(
                    .D_WIDTH(24), // RGB888
                    .LINE_LENGTH(SQUARE_SIZE) // Only need to buffer the cropped line
                ) row_buffer (
                    .clk(aclk),
                    .rst_n(areset_n),
                    .pixel_in(lbo[lbs]),
                    .pixel_valid(axi4s_in.tvalid && not_cropping), // Only write to buffer if within crop region
                    .pixel_out(lbo[lbs + 1]) 
                );
        end        
    endgenerate

    ///////////////////
    // X, Y COUNTERS //
    ///////////////////
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            x_count <= '0;
            y_count <= '0;
        end
        else if (!stall) begin
            if (axi4s_in.tvalid) begin
                if (x_count == IMG_WIDTH - 1) begin
                    x_count <= '0; // Reset at end of line
                    
                    if (y_count == IMG_HEIGHT - 1) 
                        y_count <= '0; // Reset at end of frame
                    else 
                        y_count <= y_count + 1; // Increment for each valid line
                    
                end else
                    x_count <= x_count + 1; // Increment for each valid pixel
                
            end
        end
    end



    ////////////////////////
    // CROP DETERMINATION //
    ////////////////////////
    assign x_valid = (x_count >= LEFT_CROP_STOP) && (x_count < RIGHT_CROP_START);
    assign y_valid = (y_count >= TOP_CROP_STOP) && (y_count < BOTTOM_CROP_START);
    assign not_cropping = x_valid && y_valid && axi4s_in.tvalid; // If either is valid, we're not cropping (oh and the data is valid duh)

    assign interpolate = (x_count - LEFT_CROP_STOP) % DOWNSCALE_FACTOR == 0 && (y_count - TOP_CROP_STOP) % DOWNSCALE_FACTOR == 0 && not_cropping; // Only interpolate every DOWNSCALE_FACTOR

    // Stuff the pixel matrix (and shift it)
    always_ff @(posedge aclk or negedge areset_n) begin
        if(!areset_n) begin
            // Clear pixel matrix on reset
            for (int i = 0; i < DOWNSCALE_FACTOR; i++) 
                for (int j = 0; j < DOWNSCALE_FACTOR; j++) 
                    pix_mat[i][j] <= '0;
        end
        else if(not_cropping) begin
            for(int i = 0; i < DOWNSCALE_FACTOR; i++) begin
                for (int j = 0; j < DOWNSCALE_FACTOR; j++) begin
                    if (j == 0)
                        pix_mat[i][j] <= lbo[i]; // Shift previous row down
                    else
                        pix_mat[i][j] <= pix_mat[i][j-1]; // Shift right
                end
            end
        end
    end



    //////////////////////////
    // PIPELINED ADDER TREE //
    //////////////////////////
    // Big 'ol adder tree to do the NUM_INTERPOL additions 
    // Each channel (RGB) gets it's own tree so 
    // aint no way thats getting done by hand.
    // Genvar please save me (it did)
    // NUM_STAGES total stages => #_elems >> cur_stage adders per stage 

    // Flatten layer 0 to simplify the tree
    always_comb begin
        for (int i = 0; i < DOWNSCALE_FACTOR; i++) begin
            for (int j = 0; j < DOWNSCALE_FACTOR; j++) begin
                sum_r[0][i*DOWNSCALE_FACTOR + j] = pix_mat[i][j][23:16]; // Red channel
                sum_g[0][i*DOWNSCALE_FACTOR + j] = pix_mat[i][j][15:8];  // Green channel
                sum_b[0][i*DOWNSCALE_FACTOR + j] = pix_mat[i][j][7:0];   // Blue channel
            end
        end
    end


    genvar stage, n;
    generate
        for (stage = 0; stage < NUM_STAGES; stage++) begin : adder_stages
            for (n = 0; n < (NUM_INTERPOL_ELEMS >> (stage + 1)); n++) begin : adders  // Halve the number of adders each stage (+1 since we start at 0)
                // made this comb and couldn't figure out why timing was trash.... oops
                always_ff @(posedge aclk or negedge areset_n) begin
                    if(!areset_n) begin
                        sum_r[stage + 1][n] <= '0;
                        sum_g[stage + 1][n] <= '0;
                        sum_b[stage + 1][n] <= '0;
                    end else if (!stall) begin
                        //Stage 0 everything is filled, stage 1 every other etc. stage 6 consolidates everything to one val (we hope)
                        sum_r[stage + 1][n] <= sum_r[stage][2*n] + sum_r[stage][2*n + 1]; 
                        sum_g[stage + 1][n] <= sum_g[stage][2*n] + sum_g[stage][2*n + 1];
                        sum_b[stage + 1][n] <= sum_b[stage][2*n] + sum_b[stage][2*n + 1];
                    end
                end
            end
        end
    endgenerate

    // Actually assign the avg pixel now.
    assign avg_pixel[23:16] = sum_r[NUM_STAGES][0] >> NUM_STAGES; // Divide by #_stages (bitshift)
    assign avg_pixel[15:8]  = sum_g[NUM_STAGES][0] >> NUM_STAGES; // since # elements = 2^#_stages
    assign avg_pixel[7:0]   = sum_b[NUM_STAGES][0] >> NUM_STAGES; // this is how much we want to shift...


    /////////////////////
    // AXI4-STREAM I/O //
    /////////////////////

    // To account for the big ol adder mess above we stall some of the AXI sigs
    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            tvalid_d <= '0;
            tlast_d <= '0;
            tuser_d <= '0;
        end else if (!stall) begin
            tvalid_d <= {tvalid_d[4:0], (not_cropping && axi4s_in.tvalid && interpolate)};
            tlast_d <= {tlast_d[4:0], (x_count == RIGHT_CROP_START - DOWNSCALE_FACTOR)};   // subtract DS_F to find the last pixel
            tuser_d <= {tuser_d[4:0], (x_count == LEFT_CROP_STOP) && (y_count == TOP_CROP_STOP)};
        end
    end

    // Output pixel data only if within crop region, otherwise output black
    assign axi4s_in.tready = !stall; // Backpressure from output

    assign axi4s_out.tdata = tvalid_d[5] ? avg_pixel : '0; // Output black for pixels outside crop region
    
    assign axi4s_out.tvalid = tvalid_d[5]; // Delayed version of tvalid to account for adder tree latency (#stage cycles)
    
    assign axi4s_out.tlast = tlast_d[5]; // Delayed version of tlast to account for adder tree latency (#stage cycles)
    
    assign axi4s_out.tuser = tuser_d[5];     // Only assert tuser for first pixel in crop region

endmodule