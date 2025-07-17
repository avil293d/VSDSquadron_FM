`timescale 1ns/1ps

module led_controller_tb;

  // Testbench signals
  reg clk;
  reg [7:0] rx_byte;
  reg rx_done;
  wire led_r;
  wire led_g;
  wire led_b;

  // DUT instantiation
  led_controller uut (
    .clk(clk),
    .rx_byte(rx_byte),
    .rx_done(rx_done),
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b)
  );

  // Clock generation: 100 MHz
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 ns period
  end

  // VCD dump setup
  initial begin
    $dumpfile("led_controller.vcd");
    $dumpvars(0, led_controller_tb);
  end

  // Stimulus
  initial begin
    $display("===== Starting LED Controller Testbench =====");
    rx_byte = 8'd0;
    rx_done = 0;

    // Wait for global reset
    #20;

    // Test RED ON ('R' = 0x52)
    rx_byte = 8'h52; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'R': led_r=%b (expect 1)", led_r);

    // Test RED OFF ('r' = 0x72)
    rx_byte = 8'h72; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'r': led_r=%b (expect 0)", led_r);

    // Test GREEN ON ('G' = 0x47)
    rx_byte = 8'h47; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'G': led_g=%b (expect 1)", led_g);

    // Test GREEN OFF ('g' = 0x67)
    rx_byte = 8'h67; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'g': led_g=%b (expect 0)", led_g);

    // Test BLUE ON ('B' = 0x42)
    rx_byte = 8'h42; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'B': led_b=%b (expect 1)", led_b);

    // Test BLUE OFF ('b' = 0x62)
    rx_byte = 8'h62; rx_done = 1; #10; rx_done = 0; #10;
    $display("Sent 'b': led_b=%b (expect 0)", led_b);

    $display("===== Test Complete. Check led_controller.vcd =====");

    $finish;
  end

endmodule
