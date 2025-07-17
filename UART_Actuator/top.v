`include "uart_tx.v"
`include "uart_rx.v"
`include "led_controller.v"

module top (
  // Outputs
  output wire led_red,     // Red LED output
  output wire led_blue,    // Blue LED output
  output wire led_green,   // Green LED output
  output wire uarttx,      // UART TX pin
  input wire uartrx,       // UART RX pin
);

  //--------------------------------------------------------------
  // Internal Oscillator
  //--------------------------------------------------------------
  wire int_osc;
  SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(int_osc)
  );
  //--------------------------------------------------------------
  // Baud Rate Generator (9600 baud @ 12MHz)
  //--------------------------------------------------------------
  reg [10:0] baud_counter;
  reg baud_tick;

  always @(posedge int_osc) begin
    if (baud_counter == 1249) begin
      baud_counter <= 0;
      baud_tick <= 1;
    end else begin
      baud_counter <= baud_counter + 1;
      baud_tick <= 0;
    end
  end

  //--------------------------------------------------------------
  // UART RX Signals
  //--------------------------------------------------------------
  wire [7:0] rx_byte;
  wire rx_done;

  uart_rx uart_rx_inst (
    .clk(baud_tick),
    .rx(uartrx),
    .rxbyte(rx_byte),
    .rxdone(rx_done)
  );

  //--------------------------------------------------------------
  // UART TX Signals (Loopback)
  //--------------------------------------------------------------
  reg [7:0] tx_byte;
  reg send_data;
  wire tx_done;
  wire tx_wire;

  always @(posedge int_osc) begin
    if (rx_done && !send_data) begin
      tx_byte <= rx_byte;   // echo back received byte
      send_data <= 1;
    end else if (tx_done) begin
      send_data <= 0;
    end
  end

  uart_tx uart_tx_inst (
    .clk(baud_tick),
    .txbyte(tx_byte),
    .senddata(send_data),
    .txdone(tx_done),
    .tx(tx_wire)
  );

  assign uarttx = tx_wire;

  //--------------------------------------------------------------
  // LED Controller
  //--------------------------------------------------------------
  wire led_r, led_g, led_b;

  led_controller led_ctrl_inst (
    .clk(int_osc),      // Use system clock
    .rx_byte(rx_byte),  // UART received byte
    .rx_done(rx_done),  // UART done flag
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b)
  );
SB_RGBA_DRV RGB_DRIVER (
  .RGBLEDEN(1'b1),
  .RGB0PWM(led_r),  // RGB0 → Red pin → driven by 'R'
  .RGB1PWM(led_g),  // RGB1 → Green pin → driven by 'G'
  .RGB2PWM(led_b),  // RGB2 → Blue pin → driven by 'B'
  .CURREN(1'b1),
  .RGB0(led_red),   // Physical FPGA pin 39
  .RGB1(led_green), // Physical FPGA pin 40
  .RGB2(led_blue)   // Physical FPGA pin 41
);

defparam RGB_DRIVER.RGB0_CURRENT = "0b100001";
defparam RGB_DRIVER.RGB1_CURRENT = "0b100001";
defparam RGB_DRIVER.RGB2_CURRENT = "0b100001";

endmodule
