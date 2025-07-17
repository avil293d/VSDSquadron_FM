# TASK - 5 & 6

## Purpose of the Module

The Verilog design implements an **FPGA-based RGB LED control system** that receives **ASCII commands** over UART from a PC or serial terminal.  
It parses each received command, decodes it and controls three LEDs (Red, Green, and Blue) accordingly.  
It also **echoes back** each received character for confirmation and debugging.

## UART RGB LED Control Architecture

![Architecture](block_diagram_rgb_led.png)

- The **internal oscillator** generates the system clock.
- A **baud rate generator** produces a tick at 9600 baud for the UART logic.
- The **UART receiver ( uart_rx )** listens for incoming serial data.
- The **UART transmitter ( uart_tx )** echoes back each received byte.
- The **LED controller ( led_controller )** decodes commands and drives the RGB LED outputs.
- The **SB_RGBA_DRV primitive** maps the logical RGB outputs to physical pins with adjustable current drive.


## Command Protocol

The FPGA expects single-character ASCII commands:

| Command | Function             |
|---------|----------------------|
| `R`     | Turn **Red LED ON**  |
| `r`     | Turn **Red LED OFF** |
| `G`     | Turn **Green LED ON** |
| `g`     | Turn **Green LED OFF** |
| `B`     | Turn **Blue LED ON** |
| `b`     | Turn **Blue LED OFF** |           
## Modules Overview

### 1 .  `top.v`

This is the **top-level module** that integrates the entire system:

- Instantiates:
  - Internal oscillator ( SB_HFOSC )
  - Baud rate generator for 9600 baud
  - `uart_rx` for receiving commands
  - `uart_tx` for echoing received commands
  - `led_controller` for command parsing and LED control
  - `SB_RGBA_DRV` to drive physical RGB pins with set current

- Controls loopback logic:
  - Receives a byte → sends it back → updates LEDs.

### 2 . `uart_rx.v`

This module implements a **simple UART receiver**:

- Detects the start bit.
- Shifts in 8 data bits LSB first.
- Asserts `rxdone` for one clock when a byte is ready.
- Passes the byte to the top module.

#### Simulation Result :
![uart_rx_simulation_result]()

The testbench ( [led_controller_tb]() ) verifies the behavior of the uart_rx module by simulating .


### 3 . `uart_tx.v`

This module implements a **simple UART transmitter**:

- Waits for `senddata` signal.
- Transmits 1 start bit, 8 data bits, and 1 stop bit (8N1 format).
- Asserts `txdone` when transmission completes.

### 4 . `led_controller.v`

The LED controller **decodes each received command**:

```verilog
always @(posedge clk) begin
  if (rx_done) begin
    case (rx_byte)
      8'h52: led_r <= 1'b1; // 'R'
      8'h72: led_r <= 1'b0; // 'r'
      8'h47: led_g <= 1'b1; // 'G'
      8'h67: led_g <= 1'b0; // 'g'
      8'h42: led_b <= 1'b1; // 'B'
      8'h62: led_b <= 1'b0; // 'b'
      default: ; // Ignore other bytes
    endcase
  end
end
```
#### Simulation Result :
![led_controller_simulation_result]()

The testbench ( [led_controller_tb]() ) verifies the behavior of the led_controller module by simulating how it responds to specific UART command bytes. It generates a simple clock signal, then sends a series of ASCII command bytes ('R', 'r', 'G', 'g', 'B', 'b') one by one to the module. For each command, it asserts the rx_done signal to simulate a received UART byte, checks whether the appropriate LED control output (led_r, led_g, led_b) turns ON or OFF as expected.


## Pin Configuration (SB_RGBA_DRV)

| RGB Channel | FPGA Pin |  Description                  |
|-------------|----------|-------------------------------|
| `RGB0`      | 39       |  Red LED output               |
| `RGB1`      | 40       |  Green LED output             |
| `RGB2`      | 41       |  Blue LED output              |
| `uartrx`    | 14       |  RX input from PC FTDI TXD    |
| `uarttx`    | 15       |  TX output to PC FTDI RXD     |

## Using Picocom Terminal


**Run Picocom:**
```bash
sudo picocom -b 9600 /dev/ttyUSB0
```

Replace `/dev/ttyUSB0` with the actual FTDI device path.

The terminal will show the actual received character.

> Press `Ctrl + A` then `Ctrl + X` to exit Picocom.

## Output Behavior

When the commands like `R` , `r` , `G` , `g` , `B` , `b` are sent the   
corresponding LED(s) will turn ON or OFF instantly and the terminal will show the echoed character.

## Final Output