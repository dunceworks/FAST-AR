`default_nettype none

module I2C_Master
#(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000
)(
    input  wire clk,
    input  wire rst,

    // Command interface
    input  wire        cmd_valid,
    input  wire [2:0]  cmd,         // 0=START,1=STOP,2=WRITE,3=READ
    input  wire [7:0]  tx_byte,
    input  wire        ack_in,      // ACK to send after read
    output reg  [7:0]  rx_byte,
    output reg         cmd_ready,
    output reg         ack_error,

    inout  wire sda,
    inout  wire scl
);

    // ============================================================
    // Clock Divider
    // ============================================================

    localparam DIVIDER = CLK_FREQ / (I2C_FREQ * 4);

    reg [$clog2(DIVIDER)-1:0] div_cnt;
    reg scl_int;
    reg scl_enable;

    wire scl_rise, scl_fall;

    always @(posedge clk) begin
        if (rst) begin
            div_cnt <= 0;
            scl_int <= 1;
        end else if (scl_enable) begin
            if (div_cnt == DIVIDER-1) begin
                div_cnt <= 0;
                scl_int <= ~scl_int;
            end else
                div_cnt <= div_cnt + 1;
        end else begin
            scl_int <= 1; // idle high
            div_cnt <= 0;
        end
    end

    assign scl_rise = (div_cnt == DIVIDER-1) && (scl_int == 0);
    assign scl_fall = (div_cnt == DIVIDER-1) && (scl_int == 1);

    // ============================================================
    // Open Drain Handling
    // ============================================================

    reg sda_drive_low;
    reg scl_drive_low;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign scl = scl_drive_low ? 1'b0 : 1'bz;

    wire sda_in = sda;

    always @(*) begin
        scl_drive_low = ~scl_int;
    end

    // ============================================================
    // FSM
    // ============================================================

    typedef enum logic [3:0] {
        IDLE,
        START_A,
        START_B,
        WRITE_BIT,
        READ_BIT,
        WRITE_ACK,
        READ_ACK,
        STOP_A,
        STOP_B,
        DONE
    } state_t;

    state_t state, next_state;

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;

    // ----------------------------
    // State Register
    // ----------------------------
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ----------------------------
    // Next-State Logic
    // ----------------------------
    always @(*) begin
        next_state = state;

        case (state)

        IDLE:
            if (cmd_valid)
                case (cmd)
                    3'd0: next_state = START_A;
                    3'd1: next_state = STOP_A;
                    3'd2: next_state = WRITE_BIT;
                    3'd3: next_state = READ_BIT;
                endcase

        START_A:
            if (scl_rise)
                next_state = START_B;

        START_B:
            next_state = DONE;

        WRITE_BIT:
            if (bit_cnt == 0 && scl_rise)
                next_state = WRITE_ACK;

        WRITE_ACK:
            if (scl_rise)
                next_state = DONE;

        READ_BIT:
            if (bit_cnt == 0 && scl_rise)
                next_state = READ_ACK;

        READ_ACK:
            if (scl_rise)
                next_state = DONE;

        STOP_A:
            if (scl_rise)
                next_state = STOP_B;

        STOP_B:
            next_state = DONE;

        DONE:
            next_state = IDLE;

        endcase
    end

    // ----------------------------
    // Output / Data Logic
    // ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            cmd_ready <= 1;
            sda_drive_low <= 0;
            scl_enable <= 0;
            ack_error <= 0;
        end else begin

            case (state)

            IDLE: begin
                cmd_ready <= 1;
                scl_enable <= 0;
                sda_drive_low <= 0;
            end

            START_A: begin
                cmd_ready <= 0;
                scl_enable <= 0;
                sda_drive_low <= 1; // SDA low while SCL high
            end

            START_B: begin
                scl_enable <= 1;
            end

            WRITE_BIT: begin
                shift_reg <= tx_byte;
                bit_cnt <= 3'd7;
                scl_enable <= 1;

                if (scl_fall)
                    sda_drive_low <= ~shift_reg[bit_cnt];

                if (scl_rise && bit_cnt != 0)
                    bit_cnt <= bit_cnt - 1;
            end

            WRITE_ACK: begin
                sda_drive_low <= 0; // release
                if (scl_rise)
                    ack_error <= sda_in;
            end

            READ_BIT: begin
                sda_drive_low <= 0; // release line
                scl_enable <= 1;

                if (scl_rise) begin
                    rx_byte[bit_cnt] <= sda_in;
                    if (bit_cnt != 0)
                        bit_cnt <= bit_cnt - 1;
                end
            end

            READ_ACK: begin
                if (scl_fall)
                    sda_drive_low <= ~ack_in; // send ACK/NACK
            end

            STOP_A: begin
                sda_drive_low <= 1;
                scl_enable <= 0;
            end

            STOP_B: begin
                sda_drive_low <= 0; // release SDA high
            end

            DONE: begin
                cmd_ready <= 1;
                scl_enable <= 0;
            end

            endcase
        end
    end    
endmodule
