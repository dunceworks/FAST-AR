`default_nettype none


module axi4s_sub 
#(
    parameter TDATA_WIDTH = 16,         // # of bytes, example, 8, 16, 32, 64-bits
    parameter TID_WIDTH = 8,            // no more than 8
    parameter TDAT_8 = TDATA_WIDTH / 8,
    parameter TDEST_WIDTH = 8,          // no more than 8
    parameter TUSER_WIDTH = TDAT_8 * 2  // integer multiple of TDAT_8
)
(
    input wire aclk,
    input wire areset_n,

    //inputs from dom
    input wire                      tvalid, //Data is valid
    input wire [TDATA_WIDTH-1:0]    tdata,  //the data payload... duh
    input wire [TDAT_8-1:0]         tstrb,  //unused
    input wire [TDAT_8-1:0]         tkeep,  //unused
    input wire                      tlast,  //packet boundary
    input wire [TID_WIDTH-1:0]      tid,    //unused
    input wire [TDEST_WIDTH-1:0]    tdest,  //unused
    input wire [TUSER_WIDTH-1:0]    tuser,  //user side info
    input wire                      twakeup,//unused

    //outputs
    output wire tready,                      //Ready to receive

    // signals for submodule
    input  wire                     ready_in,
    output wire [TDATA_WIDTH-1:0]   data_out,
    output wire [TUSER_WIDTH-1:0]   user_out,
    output wire                     last_byte,
    output wire                     data_valid


);

    assign tready = ready_in;
    assign data_out = tdata;
    assign user_out = tuser;
    assign last_byte = tlast;
    assign data_valid = tvalid && tready;

endmodule