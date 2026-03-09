///////////////////////////////////////////////////////// 
//
// File name: combine_tb.sv
// 
// Description: Tests the combine module.
//
// Created  : 2026-03-08
// Modified : 2026-03-08
// Author(s):
//
// Team     : Dunce Works
//
// Written?     [X]
//
////////////////////////////////////////////////////////

module combine_tb ();


// Local params
parameter COLOR_BITS = 8;       // Number of bits per color channel (R, G, B), ex. 8 == RGB888
parameter IMG_WIDTH = 100;
parameter IMG_HEIGHT = 100;
parameter IMG_SIZE = IMG_WIDTH * IMG_HEIGHT;



// Interfaces
axi4s_vid_if axi4s_in_RGB_intf ();
axi4s_vid_if axi4s_in_edge_intf ();
axi4s_vid_if axi4s_out_intf ();

// Testbench signals
logic clk;
logic reset_n;

// Test image
logic [(COLOR_BITS*3)-1:0] RGB_image [0:IMG_SIZE-1];
logic [(COLOR_BITS*3)-1:0] edge_image [0:IMG_SIZE-1];

// Output file handle
integer file_out;

//Instantiate DUT (ohmygosh look how clean it looks :D )
 combine #(
        .COLOR_BITS(COLOR_BITS)
    ) iDUT (
        .aclk(clk),
        .areset_n(reset_n),
        .axi4s_RGB_in(axi4s_in_RGB_intf),
        .axi4s_edge_in(axi4s_in_edge_intf),
        .axi4s_out(axi4s_out_intf)
    );


initial begin
    // Default signals
    clk = 0;        
    reset_n = 0;    // reset

    // Load the test image from memory
    $readmemh("..\\py\\test_img_gen\\output_hex\\idkwhatthisthingis.hex", RGB_image);  // Make sure pixel data lines up
    $readmemh("..\\py\\test_img_gen\\sv_hex_out\\sobel_output.hex", edge_image);  // Make sure pixel data lines up
    file_out = $fopen("combine_output.hex", "w");

    repeat(2) @(negedge clk); // Wait a couple cycles

    // Deassert reset
    reset_n = 1;

    //Set tready on axi4s_out to 1 to indicate we're ready to receive data (upstream flow of tready)
    axi4s_out_intf.tready <= 1'b1;

    // For loop over the test image and send pixels into the DUT
    for (int i = 0; i < IMG_SIZE; i++) begin
        axi4s_in_RGB_intf.tvalid <= 1'b1;
        axi4s_in_RGB_intf.tdata <= RGB_image[i];
        axi4s_in_edge_intf.tvalid <= 1'b1;
        axi4s_in_edge_intf.tdata <= edge_image[i];

        // Wait until DUT is ready to receive data
        while (!axi4s_in_RGB_intf.tready & axi4s_in_edge_intf.tready) begin
            axi4s_in_RGB_intf.tvalid <= 1'b0; // Don't send data until ready
            axi4s_in_edge_intf.tvalid <= 1'b0;
            @(posedge clk);
        end


        // Send data

        if(i == 0) begin
            axi4s_in_RGB_intf.tuser <= 1'b1; // First pixel of the frame
            axi4s_in_edge_intf.tuser <= 1'b1;
        end 
        else begin
            axi4s_in_RGB_intf.tuser <= 1'b0;
            axi4s_in_edge_intf.tuser <= 1'b0;
        end
        if (i+1 % (IMG_WIDTH) == 0) begin
            axi4s_in_RGB_intf.tlast <= 1'b1; // Last pixel
            axi4s_in_edge_intf.tlast <= 1'b1;
        end else begin
            axi4s_in_RGB_intf.tlast <= 1'b0;
            axi4s_in_edge_intf.tlast <= 1'b0;
        end

        // Wait for one cycle to send the data
        @(posedge clk);
    end

    axi4s_in_RGB_intf.tvalid <= 1'b0; // Done sending data
    axi4s_in_edge_intf.tvalid <= 1'b0;

    $display("Image processed. Collating into file.");

    // Wait a few cycles to ensure all data is processed

    repeat(20) @(negedge clk);

    $stop; // End of test

end


//Run independently of the initial block to check for output data from the DUT
always begin
    
    @(posedge clk);
    if (axi4s_out_intf.tvalid) begin
        // Capture the output pixel data
        logic [(COLOR_BITS*3)-1:0] out_pixel;
        out_pixel = axi4s_out_intf.tdata;

        // Write the output pixel to the file in hex format
        $fwrite(file_out, "%h\n", out_pixel); // Write output in hex format
    end

end

always #5 clk = ~clk; // clock gen



endmodule