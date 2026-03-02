`default_nettype none


module axi4s_dom 
#(
    parameter TDATA_WIDTH = 16, // # of bytes, example, 8, 16, 32, 64-bits
    parameter TID_WIDTH = 8,    // no more than 8
    parameter TDAT_8 = TDATA_WIDTH / 8,
    parameter TDEST_WIDTH = 8,  // no more than 8
    parameter TUSER_WIDTH = TDAT_8 * 2   // integer multiple of TDAT_8
)
(
    input wire aclk,
    input wire areset_n,
    
    //outputs
    output wire                      tvalid, //Data is valid
    output wire [TDATA_WIDTH-1:0]    tdata,  //the data payload... duh
    output wire [TDAT_8-1:0]         tstrb,  //unused
    output wire [TDAT_8-1:0]         tkeep,  //unused
    output wire                      tlast,  //packet boundary
    output wire [TID_WIDTH-1:0]      tid,    //unused
    output wire [TDEST_WIDTH-1:0]    tdest,  //unused
    output wire [TUSER_WIDTH-1:0]    tuser,  //user side info
    output wire                      twakeup,//unused

    //inputs from next AXI4S module
    input wire tready,                      //Ready to receive

    // signals from submodule
    input wire [TDATA_WIDTH-1:0]   data_in,
    input wire [TUSER_WIDTH-1:0]   user_in,
    input wire                     last_byte,
    input wire                     data_valid

);

    assign tvalid = data_valid; //can not wait for tready
    assign tdata = data_in;
    assign tuser = user_in;
    assign tlast = last_byte;
    assign tstrb = {TDAT_8{1'b1}};
    assign tkeep = {TDAT_8{1'b1}}; 


endmodule