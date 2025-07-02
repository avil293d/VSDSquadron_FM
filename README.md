## This repository contains projects implemented on VSDSquadron FPGA Mini development board.
The VSDSquadron FPGA Mini (FM) board is a compact and versatile prototyping platform developed by [VLSI System Design](https://www.vlsisystemdesign.com/) featuring an onboard FPGA programmer, dedicated flash memory, user-controllable RGB LED and full access to FPGA I/O pins—enabling seamless development and experimentation.
![Screenshot 2025-06-24 094806](https://github.com/user-attachments/assets/0a9426b3-d745-42ab-abf8-e9002ca4fa53)
Find out more at : [VSDSquadron FM](https://www.vlsisystemdesign.com/vsdsquadronfm/)

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
## Final Output
https://github.com/user-attachments/assets/39220e56-a86b-4138-bc8f-3b6550e641f5


# TASK-2

## Purpose of the Module

The Verilog module `uart.v` implements a **UART loopback mechanism**.  
When data is transmitted from a serial terminal **minicom**, it is immediately received back, verifying the FPGA’s UART functionality.  
## UART loopback mechanism Architecture

![Architecture](UART_loopback/Architecture.png)

```verilog
`include "uart_tx.v"
`include "uart_rx.v"
```
These are Verilog compiler directives that tell the synthesis tool to include the contents of these other Verilog files directly at the spot .

## Module Declaration

```verilog
module uart (
  output wire led_red,   // Red LED: Not used in this design
  output wire led_green, // Green LED: RX done
  output wire led_blue,  // Blue LED: TX active
  output wire uarttx,    // UART TX pin to FTDI RX
  input  wire uartrx,    // UART RX pin from FTDI TX
  input  wire hw_clk     // Not used here
);
```
- **RX pin** receives data from the terminal.
- **TX pin** sends data back to the terminal.
- **LEDs** visually indicate status.

## Transmitter Module : 

 The **UART Transmitter** module takes parallel data ( here it is 8-bit ASCII value of characters ) and converts it into a serial bitstream.  
 It typically frames each byte with a **start bit** and a **stop bit**, shifting out bits at the specified baud rate.  
In this design, when data is available to transmit, the **blue LED** is driven HIGH to show TX is active.
 ![UART_protocol](UART_loopback/uart_frame.png)

## Receiver Module :

The **UART Receiver** module continuously samples the RX line to detect the start bit.  
It then shifts in the incoming bits, reconstructing the original byte.  
Once reception is complete, the **green LED** is driven HIGH, showing that data was successfully received.


## Baud Rate Generator :
The Baud Rate Generator creates the precise timing needed for reliable serial communication.
The FPGA's internal 12 MHz oscillator is divided down by a counter to generate a baud_tick signal.
For a standard 9600 baud connection, the counter waits 1250 clock cycles (12 MHz ÷ 9600) to pulse baud_tick once for each data bit.
This baud_tick drives both the UART Receiver and Transmitter state machines, ensuring that bits are sampled and shifted exactly in sync with the expected serial bit rate.



## About Minicom Terminal

**Minicom** is a text-based serial terminal emulator on Linux.  
It connects to FPGA’s serial port , sends the  ASCII characters to the FPGA & receives looped-back data from the FPGA’s TX line.

Install minicom :  
```bash
sudo apt update
sudo apt install minicom
```

Run minicom : 
```bash
sudo minicom -b 9600 -D /dev/ttyUSB0
```
This runs the minicom terminal with the configuration of device as `/dev/ttyUSB0` and  baud rate `9600` .

### Note : The local echo needs to be enabled in the minicom terminal to view the loopback functionality.
### Go to Special Keys and enable the local Echo by pressing E . 
![](UART_loopback/Minicom_setup.png)
## PCF File Configuration

Maps logical Verilog ports to physical FPGA pins for the **VSDSquadron Mini Board**:

| Signal Name | FPGA Pin | Description                     |
|-------------|----------|---------------------------------|
| led_green   | 40       | Drives green LED (RX done)      |
| led_red     | 39       | Drives red LED (unused)         |
| led_blue    | 41       | Drives blue LED (TX active)     |
| uarttx      | 14       | UART TX pin                     |
| uartrx      | 15       | UART RX pin                     |
## Integrating with VSDSquadron FPGA Mini Board

The **Linux environment** and **FPGA toolchain** are set up as per the  
[VSDSquadron datasheet](https://www.vlsisystemdesign.com/wp-content/uploads/2025/01/datasheet.pdf).


Command to Build and flash :
```bash
make clean
make build
sudo make flash
```

- `make clean`: Remove old build files.
- `make build`: Synthesize the design.
- `sudo make flash`: Program the FPGA with the bitstream.

## Output Behavior

- The character is sent via **minicom** → FPGA RX Module receives it → **green LED** lights up.
- FPGA loops back the data → TX Module sends data back → **blue LED** lights up.
- The character is printed back on the minicom terminal which conforms it's functionality.
## Final Output
https://github.com/user-attachments/assets/e3e2d5f4-6ae9-43ad-92e8-8a1999056de6

# TASK-3


## Purpose of the Module

The Verilog module `Transmitter.v` implements a **UART transmitter**.  
This module continuously sends character 'D' using UART protocol from the FPGA's TX pin to the connected external device  
( PC ).

## UART Transmitter Architecture

![Architecture](Media/block_diagram_digital.png)

- **TX pin ( txbit --> tx --> uarttx )** transmits serial data to the external receiver (e.g., PC).


## Transmitter Module

The **UART transmitter** (`uart_tx_8n1.v`) converts an 8-bit ASCII character into a serial bitstream using the **8N1 protocol** (1 start bit, 8 data bits, 1 stop bit).  
It continuously sends the character when triggered by the internal counter.

## Baud Rate Generator

The design divides the FPGA’s internal **12 MHz clock** down to **9600 baud** using a counter.
This ensures precise bit timing for the UART transmission.

## State diagram of Transmitter Module 
![state_digram](/UART_tx_externa device/Media/State_diagram.jpeg)
## PCF File Configuration

| Signal Name | FPGA Pin | Description          |
|-------------|----------|----------------------|
| uarttx      | 14       | UART TX pin to FTDI  |
| led_green   | 40       | Optional LED         |
| led_red     | 39       | Optional LED         |
| led_blue    | 41       | Optional LED         |

## Build and Flash

```bash
make clean
make build
sudo make flash
```

- `make clean` — Removes old builds.
- `make build` — Synthesizes the bitstream.
- `sudo make flash` — Programs the FPGA.
## Using Picocom Terminal

the **Picocom** serial terminal is used to receive the transmitted data on your PC.

**Install Picocom:**

```bash
sudo apt update
sudo apt install picocom
```

**Run Picocom:**

```bash
sudo picocom -b 9600 /dev/ttyUSB0
```

Replace `/dev/ttyUSB0` with your actual device.
### Note : Move into the /dev directory if you don't have access to the actual device. 

![picocom](Media/hardware_device.png)
### Picocom running :
![running](Media/picocom_running.png) 
## Output
Once running, the serial terminal will display the transmitted character continuously, confirming the UART transmitter works.
## Final Output 
https://github.com/user-attachments/assets/f4680b41-391b-4b66-9004-a894ab15510f

