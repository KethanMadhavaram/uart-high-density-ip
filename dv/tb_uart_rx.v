`timescale 1ns / 1ps


// UART Receiver Testbench
// 
// Test Configuration:
//  Clock Frequency: 50 MHz
//  Baud Rate: 9600
//  Oversampling: 16x
//
// Calculations:
// Clocks per Bit  = 50,000,000 / 9600 = 5208
// Clocks per Tick = 5208 / 16 = 325.5 (rounded to 325)
//
// Note: For simulation speed, we use smaller parameters (CLKS_PER_TICK = 4)
// to avoid waiting for millions of clock cycles.


module tb_uart_rx;

  parameter CLKS_PER_TICK = 4; 
  parameter BIT_PERIOD    = 1280; 

  // Simulation Registers
  reg r_Clock_Drive = 0;
  reg r_Rx_Serial_Drive = 1;

  // Mirror wires for waveform viewer visibility
  wire w_Clock_VIEW;
  wire w_Rx_Serial_VIEW;
  assign w_Clock_VIEW = r_Clock_Drive;
  assign w_Rx_Serial_VIEW = r_Rx_Serial_Drive;

  // Receiver Outputs
  wire w_Rx_DV;
  wire [7:0] w_Rx_Byte;

  // Instantiate Receiver (Unit Under Test)
  uart_rx #(.CLKS_PER_TICK(CLKS_PER_TICK)) RX_INST (
    .clk(w_Clock_VIEW),
    .rx_serial_in(w_Rx_Serial_VIEW),
    .rx_done(w_Rx_DV),          
    .rx_data_out(w_Rx_Byte)
  );

  // Clock Generation (50MHz simulation)
  always #10 r_Clock_Drive = ~r_Clock_Drive;

  // Watchdog Timer to prevent infinite loops
  initial begin
    #2000000; 
    $display("ERROR: Simulation timed out.");
    $finish;
  end

  // Task: UART Write Byte
  // Manually drives the serial line to simulate a transmitter
  task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
      // Start Bit
      r_Rx_Serial_Drive <= 1'b0;
      #(BIT_PERIOD); 
      
      // Data Bits (LSB First)
      for (ii=0; ii<8; ii=ii+1) begin
        r_Rx_Serial_Drive <= i_Data[ii];
        #(BIT_PERIOD);
      end
      
      // Stop Bit
      r_Rx_Serial_Drive <= 1'b1;
      #(BIT_PERIOD);
    end
  endtask

  // Main Test Sequence
  initial begin
    $dumpfile("uart_rx.vcd");
    $dumpvars(0, tb_uart_rx);
    #100;

    // Test 1: Verify reception of 0x41 ('A')
    $display("Test 1: Sending 0x41 ('A')...");

    fork
       // Thread 1: Drive the serial line
       UART_WRITE_BYTE(8'h41); 

       // Thread 2: Monitor for data valid pulse
       begin
           @(posedge w_Rx_DV); 
           if (w_Rx_Byte == 8'h41) 
               $display("SUCCESS: Received 0x41");
           else 
               $display("FAILURE: Received 0x%h", w_Rx_Byte);
       end
    join
    
    #100;

    // Test 2: Verify reception of 0x42 ('B')
    $display("Test 2: Sending 0x42 ('B')...");

    fork
       UART_WRITE_BYTE(8'h42);
       begin
           @(posedge w_Rx_DV);
           if (w_Rx_Byte == 8'h42) 
               $display("SUCCESS: Received 0x42");
           else 
               $display("FAILURE: Received 0x%h", w_Rx_Byte);
       end
    join

    // Allow time for waveform observation
    #5000;
    $finish;
  end

endmodule