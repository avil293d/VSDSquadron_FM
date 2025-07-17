module led_controller (
    input wire clk,               // system clock
    input wire [7:0] rx_byte,     // received UART byte
    input wire rx_done,           // high for 1 cycle when byte received

    output reg led_r,             // Red LED control
    output reg led_g,             // Green LED control
    output reg led_b              // Blue LED control
);

    always @(posedge clk) begin
        if (rx_done) begin
            case (rx_byte)
                // ---- Red LED ----
                8'h52: led_r <= 1'b1;   // 'R' → Red ON
                8'h72: led_r <= 1'b0;   // 'r' → Red OFF

                // ---- Green LED ----
                8'h47: led_g <= 1'b1;   // 'G' → Green ON
                8'h67: led_g <= 1'b0;   // 'g' → Green OFF

                // ---- Blue LED ----
                8'h42: led_b <= 1'b1;   // 'B' → Blue ON
                8'h62: led_b <= 1'b0;   // 'b' → Blue OFF

                default: ; // ignore other bytes
            endcase
        end
    end

endmodule
