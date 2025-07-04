
module uart_tx_8n1 (
    input clk,
    input baud_tick,
    input [7:0] txbyte,
    input senddata,
    output reg txdone,
    output tx
);

    parameter STATE_IDLE = 2'b00;
    parameter STATE_START = 2'b01;
    parameter STATE_DATA = 2'b10;
    parameter STATE_STOP = 2'b11;

    reg [1:0] state = STATE_IDLE;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_shift = 0;
    reg txbit = 1'b1;

    assign tx = txbit;

    always @(posedge clk) begin
        txdone <= 0;

        case (state)
            STATE_IDLE: begin
                txbit <= 1'b1;
                if (senddata) begin
                    tx_shift <= txbyte;
                    state <= STATE_START;
                end
            end

            STATE_START: begin
                if (baud_tick) begin
                    txbit <= 1'b0;
                    state <= STATE_DATA;
                    bit_index <= 0;
                end
            end

            STATE_DATA: begin
                if (baud_tick) begin
                    txbit <= tx_shift[0];
                    tx_shift <= tx_shift >> 1;

                    if (bit_index < 7)
                        bit_index <= bit_index + 1;
                    else
                        state <= STATE_STOP;
                end
            end

            STATE_STOP: begin
                if (baud_tick) begin
                    txbit <= 1'b1;
                    state <= STATE_IDLE;
                    txdone <= 1'b1;
                end
            end

            default: state <= STATE_IDLE;
        endcase
    end

endmodule
