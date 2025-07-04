# TASK-4

## Purpose of the Module

The Verilog module `top.v` implements an ultrasonic distance measurement system with an HC-SR04 sensor, measures the echo time, converts the measured distance to ASCII and transmits it via a UART transmitter to a connected external device (e.g., PC).

## UART Distance Measurement Architecture

![Architecture](Media/block_diagram_digital.png)

- The Trigger pin (`trig_pin`) generates a ~10µs pulse every 60ms to trigger the HC-SR04 sensor.
- The Echo pin (`echo_pin`) receives the returned pulse which is timed to calculate distance.
- The measured distance is converted to BCD, then mapped to ASCII.
- The TX pin (`uart_tx`) sends the distance in centimeters over UART to the PC.

## UART Transmitter Module

The **UART transmitter** (`uart_tx_8n1.v`) converts the ASCII characters for the distance value to a serial bitstream using the **8N1 UART protocol** (1 start bit, 8 data bits, 1 stop bit).  
It transmits formatted data in the form `D: 123 cm` for every measurement cycle.

## Baud Rate Generator

A counter divides the FPGA’s internal **12 MHz clock** down to **9600 baud**, providing precise UART timing.


## PCF File Configuration

| Signal Name | FPGA Pin | Description                 |
|-------------|----------|-----------------------------|
| uart_tx     | 14       | UART TX pin to FTDI RXD     |
| trig_pin    | 12       | HC-SR04 Trigger pin         |
| echo_pin    | 11       | HC-SR04 Echo pin (input)    |
| led         | 40       | LED indicates measurement   |

## Build and Flash

```bash
make clean
make build
sudo make flash
```

- `make clean` — Removes previous build files.
- `make build` — Synthesizes and generates the bitstream.
- `sudo make flash` — Programs the FPGA.

## Using Picocom Terminal

**Picocom** is used to view the transmitted distance data on PC.

**Install Picocom:**

```bash
sudo apt update
sudo apt install picocom
```

**Run Picocom:**

```bash
sudo picocom -b 9600 /dev/ttyUSB0
```

Replace `/dev/ttyUSB0` with your actual FTDI device path.  

![picocom](Media/hardware_device.png)

**Picocom running:**

![running](Media/picocom_running.png)

> Press `Ctrl + A` then `Ctrl + X` to exit Picocom.

## Output

When running, the terminal continuously displays the measured distance in the format:

```
D: 23 cm
```

This confirms the ultrasonic sensor, distance calculation logic and UART transmitter are working correctly.

## Final Output

[output-video]()