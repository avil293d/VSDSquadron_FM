`timescale 1ns/1ps

module uart_rx_tb;
    reg clk = 0;
    reg rx = 1;
    wire [7:0] rxbyte;
    wire rxdone;

    uart_rx uut (
        .clk(clk),
        .rx(rx),
        .rxbyte(rxbyte),
        .rxdone(rxdone)
    );
  
    always #5 clk = ~clk;

    
    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end

    
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            rx <= 0; 
            @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i]; 
                @(posedge clk);
            end
            rx <= 1; 
            @(posedge clk);
        end
    endtask


    task test_char(input [7:0] send_char);
        reg [7:0] received_char;
        begin
            send_uart_byte(send_char);
            wait(rxdone == 1);
            received_char = rxbyte;
            @(posedge clk); 
            if (received_char == send_char)
                $display("send char = %c, received char = %c, pass", send_char, received_char);
            else
                $display("send char = %c, received char = %c, fail", send_char, received_char);
        end
    endtask

    initial begin
        $display("UART RX Testbench Begin");
        repeat (3) @(posedge clk);

        test_char("G"); 
        test_char("b"); 

        #20;
        $finish;
    end
endmodule
