//----------------------------------------------------------------------------
//                                                                          --
//                         Module Declaration                               --
//                                                                          --
//----------------------------------------------------------------------------

module blue_fade (
  output wire led_red,     // Red 
  output wire led_blue,    // Blue 
  output wire led_green,   // Green
  input wire hw_clk,       // Hardware Oscillator, not the internal oscillator
  output wire testwire
);

//----------------------------------------------------------------------------
//                                                                          --
//                       Internal Oscillator                                --
//                       //not in use                                       --
//---------------------------------------------------------------------------- 
  wire int_osc;
  SB_HFOSC u_SB_HFOSC (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(int_osc)
  );

//----------------------------------------------------------------------------
//                                                                          --
//                             Counter                                       --
//                      used to generate lower frequency                    --
//----------------------------------------------------------------------------
  reg [27:0] frequency_counter_i = 0;
  
  always @(posedge hw_clk) begin
    frequency_counter_i <= frequency_counter_i + 1'b1;
  end

  assign testwire = frequency_counter_i[5];  // Debug signal

//----------------------------------------------------------------------------
//                                                                          --
//                        PWM Counter                                       --
//                   used for Brightness Control                            --
//----------------------------------------------------------------------------
  reg [7:0] pwm_counter = 0;
  always @(posedge hw_clk) pwm_counter <= pwm_counter + 1;

  reg [7:0] duty_cycle;
  always @(*) begin
    case (frequency_counter_i[24:21])
      4'd0 :  duty_cycle = 32;
      4'd1 :  duty_cycle = 64;
      4'd2 :  duty_cycle = 96;
      4'd3 :  duty_cycle = 128;
      4'd4 :  duty_cycle = 160;
      4'd5 :  duty_cycle = 192;
      4'd6 :  duty_cycle = 224;
      4'd7 :  duty_cycle = 255;
      4'd8 :  duty_cycle = 224;
      4'd9 :  duty_cycle = 192;
      4'd10:  duty_cycle = 160;
      4'd11:  duty_cycle = 128;
      4'd12:  duty_cycle = 96;
      4'd13:  duty_cycle = 64;
      4'd14:  duty_cycle = 32;
      4'd15:  duty_cycle = 0;
      default: duty_cycle = 0;
    endcase
  end

  wire pwm_signal = (pwm_counter < duty_cycle);

//----------------------------------------------------------------------------
//                                                                          --
//                       Instantiate RGB primitive                          --
//                                                                          --
//----------------------------------------------------------------------------
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM(1'b0),
    .RGB1PWM(1'b0),
    .RGB2PWM(pwm_signal),
    .CURREN(1'b1),
    .RGB0(led_red),
    .RGB1(led_green),
    .RGB2(led_blue)
  );

  defparam RGB_DRIVER.RGB0_CURRENT = "0b000000";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b000000";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b111100";

endmodule
