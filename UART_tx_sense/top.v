`include "uart_tx_8n1.v"

//----------------------------------------------------------------------------
//                                                                          --
//                         Module Declaration                               --
//                                                                          --
//----------------------------------------------------------------------------
module top (
    output trig_pin,  // HC-SR04 Trigger pin
    input echo_pin,   // HC-SR04 Echo pin
    output uart_tx,   // UART TX pin to FTDI RXD
    output led        // status LED
);
//----------------------------------------------------------------------------
//                                                                          --
//                       Internal Oscillator                                --
//                                                                          --
//----------------------------------------------------------------------------
    wire clk_int;

    SB_HFOSC #(.CLKHF_DIV("0b10")) u_hfosc (.CLKHFEN(1'b1),.CLKHFPU(1'b1),.CLKHF(clk_int));
//----------------------------------------------------------------------------
//                                                                          --
//                Trigger pulse generator : ~10us every 60ms                --
//                                                                          --
//----------------------------------------------------------------------------

    reg [19:0] trig_counter = 0;
    reg trig_reg = 0;

    always @(posedge clk_int) begin
        if (trig_counter < 720_000)
            trig_counter <= trig_counter + 1;
        else
            trig_counter <= 0;

        if (trig_counter < 120)
            trig_reg <= 1;
        else
            trig_reg <= 0;
    end

    assign trig_pin = trig_reg;

//----------------------------------------------------------------------------
//                                                                          --
//                               Echo timer                                 --
//                                                                          --
//----------------------------------------------------------------------------
    
    reg echo_prev = 0;
    reg [31:0] echo_counter = 0;
    reg [31:0] echo_pulse = 0;
    reg echo_done = 0;

    always @(posedge clk_int) begin
        echo_prev <= echo_pin;

        if (echo_prev == 0 && echo_pin == 1) begin
            echo_counter <= 0;
            echo_done <= 0;
        end else if (echo_pin == 1) begin
            echo_counter <= echo_counter + 1;
        end else if (echo_prev == 1 && echo_pin == 0) begin
            echo_pulse <= echo_counter;
            echo_done <= 1;
        end else begin
            echo_done <= 0;
        end
    end
//----------------------------------------------------------------------------
//                                                                          --
//                       Counter for indicator LED                          --
//                                                                          --
//----------------------------------------------------------------------------

    
    reg [21:0] led_counter = 0;
    reg led_reg = 0;

    always @(posedge clk_int) begin
        if (echo_done) led_counter <= 600_000;
        else if (led_counter > 0) led_counter <= led_counter - 1;

        led_reg <= (led_counter > 0);
    end

    assign led = led_reg;

//----------------------------------------------------------------------------
//                                                                          --
//                       Baud Generator                                     --
//                                                                          --
//----------------------------------------------------------------------------

    
    reg [15:0] baud_div = 0;
    reg baud_tick = 0;

    always @(posedge clk_int) begin
        if (baud_div == 1249) begin
            baud_div <= 0;
            baud_tick <= 1;
        end else begin
            baud_div <= baud_div + 1;
            baud_tick <= 0;
        end
    end



//----------------------------------------------------------------------------
//                                                                          --
//                        distance calculator                               --
//                                                                          --
//----------------------------------------------------------------------------

    reg [15:0] distance_cm = 0;

    always @(posedge clk_int) begin
        if (echo_done)
            distance_cm <= echo_pulse >> 6;  // adjust shift factor for your sensor scale
    end

//----------------------------------------------------------------------------
//                                                                          --
//                       BCD converter (Double Dabble)                            --
//                                                                          --
//----------------------------------------------------------------------------   


    reg [15:0] binary;
    reg [19:0] bcd;
    reg [4:0] bcd_count = 0;
    reg bcd_busy = 0;
    reg bcd_done = 0;
    reg [1:0] bcd_phase = 0; 

    always @(posedge clk_int) begin
        if (echo_done && !bcd_busy) begin
            binary <= distance_cm;
            bcd <= 0;
            bcd_count <= 16;
            bcd_busy <= 1;
            bcd_done <= 0;
            bcd_phase <= 1;  
        end else if (bcd_busy) begin
            case (bcd_phase)
                1: begin
                    if (bcd[19:16] >= 5) bcd[19:16] <= bcd[19:16] + 3;
                    if (bcd[15:12] >= 5) bcd[15:12] <= bcd[15:12] + 3;
                    if (bcd[11:8]  >= 5) bcd[11:8]  <= bcd[11:8]  + 3;
                    if (bcd[7:4]   >= 5) bcd[7:4]   <= bcd[7:4]   + 3;
                    bcd_phase <= 2;  
                end
                2: begin
                    bcd <= {bcd[18:0], binary[15]};
                    binary <= binary << 1;

                    if (bcd_count == 0) begin
                        bcd_busy <= 0;
                        bcd_done <= 1;
                        bcd_phase <= 0; 
                    end else begin
                        bcd_count <= bcd_count - 1;
                        bcd_phase <= 1; 
                    end
                end
            endcase
        end else begin
            bcd_done <= 0;
        end
    end

//----------------------------------------------------------------------------
//                                                                          --
//                       BCD to ASCII                               --
//                                                                          --
//----------------------------------------------------------------------------

    reg [7:0] ascii_h, ascii_t, ascii_u;

    always @(posedge clk_int) begin
        if (bcd_done) begin
            ascii_h <= "0" + bcd[15:12];
            ascii_t <= "0" + bcd[11:8];
            ascii_u <= "0" + bcd[7:4];
        end
    end

//----------------------------------------------------------------------------
//                                                                          --
//                        UART transmitter                                  --
//                                                                          --
//----------------------------------------------------------------------------
    reg [7:0] txbyte = 0;
    reg senddata = 0;
    wire txdone;
    reg [4:0] tx_state = 0;

    uart_tx_8n1 UART_TX (
        .clk(clk_int),
        .baud_tick(baud_tick),
        .txbyte(txbyte),
        .senddata(senddata),
        .txdone(txdone),
        .tx(uart_tx)
    );

    always @(posedge clk_int) begin
        senddata <= 0;

        case (tx_state)
            0: if (bcd_done) tx_state <= 1;

            1: begin txbyte <= "D"; senddata <= 1; tx_state <= 2; end
            2: if (txdone) begin txbyte <= ":"; senddata <= 1; tx_state <= 3; end
            3: if (txdone) begin txbyte <= " "; senddata <= 1; tx_state <= 4; end

            4: if (txdone) begin txbyte <= ascii_h; senddata <= 1; tx_state <= 5; end
            5: if (txdone) begin txbyte <= ascii_t; senddata <= 1; tx_state <= 6; end
            6: if (txdone) begin txbyte <= ascii_u; senddata <= 1; tx_state <= 7; end

            7: if (txdone) begin txbyte <= " "; senddata <= 1; tx_state <= 8; end
            8: if (txdone) begin txbyte <= "c"; senddata <= 1; tx_state <= 9; end
            9: if (txdone) begin txbyte <= "m"; senddata <= 1; tx_state <= 10; end

            10: if (txdone) begin txbyte <= 8'h0D; senddata <= 1; tx_state <= 11; end  // CR
            11: if (txdone) begin txbyte <= 8'h0A; senddata <= 1; tx_state <= 12; end  // LF

            12: if (txdone) tx_state <= 0;
        endcase
    end

endmodule
