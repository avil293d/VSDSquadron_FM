# TASK-1

## Purpose of the module :

The Verilog module `blue_fade.v` implements a fading effect on the **blue LED** using the hardware clock on board and pulse-width modulation (PWM). The design demonstrates a smooth brightness control using counters and PWM logic.

---

## Module Declaration

```verilog
module blue_fade (
  output wire led_red,
  output wire led_blue,
  output wire led_green,
  input wire hw_clk,
  output wire testwire
);
```

This defines the top-level interface to the module:
- Controls three LED outputs (Red, Blue, Green)
- Accepts an external hardware clock (`hw_clk`)
- Outputs a debug signal (`testwire`)

---

## Ports

| Port       | Direction | Description                                                                 |
|------------|-----------|-----------------------------------------------------------------------------|
| `led_red`  | Output    | Drives the red LED. Always off in this design.                              |
| `led_blue` | Output    | Drives the blue LED. Modulated using PWM for fading effect.                 |
| `led_green`| Output    | Drives the green LED. Always off in this design.                            |
| `hw_clk`   | Input     | Hardware clock input driving all logic.                                     |
| `testwire` | Output    | Debug signal derived from bit 5 of frequency counter. Useful for testing.   |

---

## Internal Oscillator (Not Used)

```verilog
wire int_osc;
SB_HFOSC u_SB_HFOSC (
  .CLKHFPU(1'b1),
  .CLKHFEN(1'b1),
  .CLKHF(int_osc)
);
```

The internal oscillator is instantiated but not used in this design. The module uses the external `hw_clk` as its actual clock source.

---

## Frequency Counter

```verilog
reg [27:0] frequency_counter_i = 0;

always @(posedge hw_clk) begin
  frequency_counter_i <= frequency_counter_i + 1'b1;
end

assign testwire = frequency_counter_i[5];
```

- A 28-bit counter that increments with every rising edge of `hw_clk`.
- Bit 5 is connected to `testwire`, producing a low-frequency square wave useful for debugging or probing signal activity.
- `frequency_counter_i[24:21]` controls which brightness level is currently active — like stepping through a brightness animation frame-by-frame.
---

## PWM Counter

```verilog
reg [7:0] pwm_counter = 0;
always @(posedge hw_clk) pwm_counter <= pwm_counter + 1;
```

- An 8-bit counter used to produce the pulse-width modulation signal.
- Repeats every 256 clock cycles, forming the base of the PWM wave.

---

## Duty Cycle Control

```verilog
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
```

- Based on bits `[24:21]` of the frequency counter, this logic generates a **triangular waveform pattern** for brightness.
- The 4 bit  wide counter  goes from 0 to 15 giving 16 distinct brightness levels.

- The duty cycle gradually ramps from 32 to 255, then decrease symmetrically  forming a triangular wave, repeating endlessly.
- This results in a smooth fade-in and fade-out effect for the blue LED.

---

## PWM Signal Generation

```verilog
wire pwm_signal = (pwm_counter < duty_cycle);
```

- Compares `pwm_counter` to `duty_cycle` to generate a square wave.
- When the counter is less than the duty cycle, the output is HIGH.
- This HIGH duration determines the average voltage level to blue LED. More on **PWM** method at [LINK](https://www.geeksforgeeks.org/electronics-engineering/pulse-width-modulation-pwm/).
---

## RGB LED Driver

```verilog
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
```

- This primitive connects the internal logic to physical RGB LEDs.
- Only the **blue** LED is driven by PWM (`pwm_signal`), while red and green are kept OFF.
- The blue channel's current is set to a high value to ensure visibility.

---

## PCF File configuration :
- The **VSDSquadron.pcf**  (Physical Constraints File)  maps logical Verilog signals to physical FPGA pins in Lattice iCE40 designs.

- To ensure proper functionality the PCF file must be verified against the VSDSquadron FPGA [datasheet](https://www.vlsisystemdesign.com/wp-content/uploads/2025/01/datasheet.pdf).


| Signal Name | FPGA Pin | Description               |
|-------------|----------|---------------------------|
| led_red     | 39       | Drives red LED            |
| led_green    | 40       | Drives green LED           |
| led_blue   | 41       | Drives blue LED          |
| hw_clk      | 20       | External hardware clock   |
| testwire    | 17       | Debug output              |

---

## Integrating with VSDSquadron FPGA Mini Board :
- The required softwares are installed and the Linux environment is 
setup as specified in the [datasheet](https://www.vlsisystemdesign.com/wp-content/uploads/2025/01/datasheet.pdf).
- The following command is used in Terminal to navigate to the **led_fade** directory .
```
cd ~/VSDSquadron_FM/led_fade
```
- The board is connected to the PC through USB-C .
- The connection is verified to the Oracle Virtual Machine .
- The following commands are executed to program the VSDSquadron FPGA Mini (FM) board . 
```
make clean  
make build  
sudo make flash
```
- `make clean`: Removes old build files

- `make build` : Synthesizes the design

- `sudo make flash` : Programs the FPGA with the new bitstream 

## Output Behavior

- **_Blue LED fades in and out continuously_**.
- Red and Green LEDs remain off at all times.
https://github.com/user-attachments/assets/787d44bd-6eae-4c6e-adef-b33189555a0f
