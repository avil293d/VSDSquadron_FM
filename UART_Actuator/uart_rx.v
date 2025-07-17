module uart_rx (
    input clk,         // baud tick
    input rx,          // incoming serial data line
    output reg [7:0] rxbyte, // received byte
    output reg rxdone  // high for 1 clk when byte done
);

    // States
    parameter STATE_IDLE   = 2'd0;
    parameter STATE_RXING  = 2'd1;
    parameter STATE_DONE   = 2'd2;

    reg [1:0] state = STATE_IDLE;
    reg [7:0] rx_shift = 8'b0;
    reg [2:0] bit_count = 3'd0;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                rxdone <= 1'b0;
                if (rx == 1'b0) begin  // start bit detected (low)
                    state <= STATE_RXING;
                    bit_count <= 0;
                end
            end

            STATE_RXING: begin
                rx_shift <= {rx, rx_shift[7:1]}; // shift in LSB first
                bit_count <= bit_count + 1;
                if (bit_count == 7) begin
                    state <= STATE_DONE;
                end
            end

            STATE_DONE: begin
                rxbyte <= rx_shift;   // latch received byte
                rxdone <= 1'b1;       // pulse done flag
                state <= STATE_IDLE;  // back to idle to catch next byte
            end
        endcase
    end

endmodule
