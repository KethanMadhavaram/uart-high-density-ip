`timescale 1ns / 1ps

// UART Loopback Testbench
// 
// Description:
//  Verifies full-duplex communication by connecting Tx directly to Rx.
//
// Configuration:
//  Clock Frequency: 50 MHz
//  Baud Rate: 9600
//
// Calculation:
//  Clocks per Bit = 50,000,000 / 9600 = 5208


module tb_loopback;

  // Simulation Parameters
  // Rx ticks every 4 clocks. Since it samples 16x per bit:
  // Bit Period must be 4 * 16 = 64 clocks.
  parameter CLKS_PER_TICK = 4;
  parameter CLKS_PER_BIT  = 64;  
  parameter CLK_PERIOD    = 20;

  reg       r_Clock = 0;
  reg       r_Reset = 0;
  reg       r_Tx_Start = 0;
  reg [7:0] r_Tx_Byte = 0;
  
  wire      w_Tx_Serial;
  wire      w_Tx_Busy;
  wire      w_Tx_Done;
  wire      w_Rx_Done;
  wire [7:0] w_Rx_Data_Out;

  // Instantiate Transmitter
  // Drives the bit for 64 clock cycles
  UART_Tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) TX_INST (
    .clk(r_Clock),
    .tx_rst(r_Reset),
    .start(r_Tx_Start),
    .tx_data_in(r_Tx_Byte),
    .tx_serial_out(w_Tx_Serial), 
    .tx_busy(w_Tx_Busy),
    .tx_done(w_Tx_Done)
  );

  // Instantiate Receiver
  // Ticks every 4 clocks (Total 4 * 16 = 64 clocks/bit)
  uart_rx #(.CLKS_PER_TICK(CLKS_PER_TICK)) RX_INST (
    .clk(r_Clock),
    .rx_serial_in(w_Tx_Serial),  
    .rx_done(w_Rx_Done),
    .rx_data_out(w_Rx_Data_Out)
  );

  // Generate 50MHz Clock
  always #(CLK_PERIOD/2) r_Clock = ~r_Clock;

  initial begin
    $dumpfile("loopback_test.vcd");
    $dumpvars(0, tb_loopback);

    // Initial State
    r_Tx_Start = 0;
    r_Tx_Byte  = 0;
    r_Reset    = 1;
    #100;
    r_Reset    = 0;
    #100;

    // Test 1: Send 0x37 via Loopback
    $display("Test 1: Sending 0x37...");
    
    r_Tx_Byte  = 8'h37;
    r_Tx_Start = 1'b1;
    #(CLK_PERIOD);
    r_Tx_Start = 1'b0;

    // Wait for Receiver to finish
    @(posedge w_Rx_Done);

    if (w_Rx_Data_Out == 8'h37)
        $display("SUCCESS: Received 0x37");
    else
        $display("FAILURE: Received 0x%h", w_Rx_Data_Out);

    #100;

    // Test 2: Send 0xA5 via Loopback
    $display("Test 2: Sending 0xA5...");

    r_Tx_Byte  = 8'hA5;
    r_Tx_Start = 1'b1;
    #(CLK_PERIOD);
    r_Tx_Start = 1'b0;

    @(posedge w_Rx_Done);

    if (w_Rx_Data_Out == 8'hA5)
        $display("SUCCESS: Received 0xA5");
    else
        $display("FAILURE: Received 0x%h", w_Rx_Data_Out);
    
    #1000;
    $finish;
  end

endmodule