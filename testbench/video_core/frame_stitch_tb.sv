///////////////////////////////////////////////////////// 
//
// File name: frame_stitch_tb.sv
// 
// Description: Tests the crop_image module.
//
// Created  : 2026-03-09
// Modified : 2026-03-09
// Author   : Wysong
//
// Team     : Dunce Works
//
// Written?     [X]
//
////////////////////////////////////////////////////////

module frame_stitch_tb ();

// Local params
parameter COLOR_BITS = 8;       // Number of bits per color channel (R, G, B), ex. 8 == RGB888
parameter IMG_WIDTH_OUT = 1920;
parameter IMG_HEIGHT_OUT = 1080;
parameter IMG_WIDTH_IN = IMG_WIDTH_OUT / 2; // Input is half width since we're stitching two frames together
parameter IMG_HEIGHT_IN = IMG_HEIGHT_OUT;


parameter IMG_SIZE = IMG_WIDTH_OUT * IMG_HEIGHT_OUT;
parameter IN_IMG_SIZE = IMG_WIDTH_IN * IMG_HEIGHT_IN;




// Interfaces
axi4s_vid_if axi4s_in_intf ();
axi4s_vid_if axi4s_out_intf ();

// Testbench signals
logic clk;
logic reset_n;

// Test image
logic [(COLOR_BITS*3)-1:0] test_image [0:IMG_SIZE-1];

// Output file handle
integer file_out;

//Instantiate DUT (ohmygosh look how clean it looks :D )
frame_stitch #(
    .COLOR_BITS(COLOR_BITS),
    .IMG_WIDTH(IMG_WIDTH_OUT),
    .IMG_HEIGHT(IMG_HEIGHT_OUT)
) dut (
    .aclk(clk),
    .areset_n(reset_n),
    .axi4s_in(axi4s_in_intf),
    .axi4s_out(axi4s_out_intf)
);


initial begin
    // Default signals
    clk = 0;        
    reset_n = 0;    // reset

    // Load the test image from memory
    $readmemh("..\\py\\test_img_gen\\output_hex\\camel_960x1080.hex", test_image);  // Raw RGB data in hex format
    file_out = $fopen("frame_stitch_output.hex", "w");

    repeat(2) @(negedge clk); // Wait a couple cycles

    // Deassert reset
    reset_n = 1;

    $display("Modules reset. Starting test...");

    //Set tready on axi4s_out to 1 to indicate we're ready to receive data (upstream flow of tready)
    axi4s_out_intf.tready <= 1'b1;

    // For loop over the test image and send pixels into the DUT
    for (int i = 0; i < IN_IMG_SIZE; i++) begin
        axi4s_in_intf.tvalid <= 1'b1;
        axi4s_in_intf.tdata <= test_image[i];

        // Wait until DUT is ready to receive data
        while (!axi4s_in_intf.tready) begin
            //$display("Waiting for tready...");
            @(posedge clk);
        end


        // Send data

        if(i == 0)
            axi4s_in_intf.tuser <= 1'b1; // First pixel of the frame
        else
            axi4s_in_intf.tuser <= 1'b0;
        
        if (i+1 % (IMG_WIDTH_IN) == 0) begin
            axi4s_in_intf.tlast <= 1'b1; // Last pixel
        end else begin
            axi4s_in_intf.tlast <= 1'b0;
        end

        // Wait for one cycle to send the data
        @(posedge clk);
    end

    axi4s_in_intf.tvalid <= 1'b0; // Done sending data

    $display("Image processed. Collating into file.");

    // Wait a few cycles to ensure all data is processed

    repeat(100) @(negedge clk);

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