`include "uart_tx.v"
`include "uart_rx.v"
//----------------------------------------------------------------------------
//                                                                          --
//                         Module Declaration                               --
//                                                                          --
//----------------------------------------------------------------------------
module uart (
  // outputs
  output wire led_red  , // Red
  output wire led_blue , // Blue
  output wire led_green, // Green
  output wire uarttx   , // UART Transmission pin
  input  wire uartrx   , // UART Receive pin
  input  wire hw_clk   // Not used here, using internal osc
);

  wire int_osc;
  reg  [10:0] baud_counter;
  reg  baud_tick;

  // TX signals
  reg  [7:0] tx_byte;
  reg  send_data;
  wire tx_done;
  wire tx_wire;

  // RX signals
  wire [7:0] rx_byte;
  wire rx_done;

//----------------------------------------------------------------------------
//                                                                          --
//                       Internal Oscillator                                --
//                                                                          --
//----------------------------------------------------------------------------
  SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(int_osc)
  );

//----------------------------------------------------------------------------
//                                                                          --
//                       Baud Rate Generator (9600 @ 12MHz)                 --
//                                                                          --
//----------------------------------------------------------------------------
  always @(posedge int_osc) begin
    if (baud_counter == 1249) begin // 12MHz / 9600 = 1250
      baud_counter <= 0;
      baud_tick <= 1;
    end else begin
      baud_counter <= baud_counter + 1;
      baud_tick <= 0;
    end
  end

//----------------------------------------------------------------------------
//                                                                          --
//                       Loopback Logic                                     --
//                                                                          --
//----------------------------------------------------------------------------
  always @(posedge int_osc) begin
    if (rx_done && !send_data) begin
      tx_byte <= rx_byte;  // Load RX data into TX
      send_data <= 1;      // Trigger TX FSM
    end else if (tx_done) begin
      send_data <= 0;      // Reset TX trigger after done
    end
  end

//----------------------------------------------------------------------------
//                                                                          --
//                       Instantiate UART TX                                --
//                                                                          --
//----------------------------------------------------------------------------
  uart_tx uart_tx_inst (
    .clk(baud_tick),  // baud tick = 1 bit time
    .txbyte(tx_byte),
    .senddata(send_data),
    .txdone(tx_done),
    .tx(tx_wire)
  );

//----------------------------------------------------------------------------
//                                                                          --
//                       Instantiate UART RX                                --
//                                                                          --
//----------------------------------------------------------------------------
  uart_rx uart_rx_inst (
    .clk(baud_tick),
    .rx(uartrx),
    .rxbyte(rx_byte),
    .rxdone(rx_done)
  );

//----------------------------------------------------------------------------
//                                                                          --
//                       Connect TX output pin                              --
//                                                                          --
//----------------------------------------------------------------------------
  assign uarttx = tx_wire;

//----------------------------------------------------------------------------
//                                                                          --
//                       Instantiate RGB primitive                          --
//                                                                          --
//----------------------------------------------------------------------------
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1                                            ),
    .RGB0PWM (rx_done), // Green LED shows RX done
    .RGB1PWM (send_data), // Blue LED shows TX active
    .RGB2PWM (tx_done), // Red LED shows TX done
    .CURREN  (1'b1                                            ),
    .RGB0    (led_green                                       ), //Actual Hardware connection
    .RGB1    (led_blue                                        ),
    .RGB2    (led_red                                         )
  );

  defparam RGB_DRIVER.RGB0_CURRENT = "0b100001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b100001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b100001";

endmodule
