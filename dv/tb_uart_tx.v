`timescale 1ns / 1ps

// UART Transmitter Testbench
// 
// Test Configuration:
// - Clock Frequency: 50 MHz
// - Baud Rate: 9600
//
// Calculation:
// Clocks per Bit = 50,000,000 / 9600 = 5208
//
// Note: For simulation speed, we use a smaller parameter (CLKS_PER_BIT = 4)
// to avoid waiting for millions of clock cycles.


module tb_uart_tx;
  
  // Use a small value for simulation speed, actual hardware needs 5208
  parameter CLKS_PER_BIT = 4; 
  parameter CLK_PERIOD   = 20; 

  reg       r_Clock = 0;
  reg       r_Reset = 0;      
  reg       r_Tx_Start = 0;   
  reg [7:0] r_Tx_Byte = 0;    
  wire      w_Tx_Serial;      
  wire      w_Tx_Busy;      
  wire      w_Tx_Done;        

  // Instantiate the Transmitter
  UART_Tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) TX_INST (
    .clk(r_Clock),
    .tx_rst(r_Reset),             
    .start(r_Tx_Start),
    .tx_data_in(r_Tx_Byte),  
    .tx_serial_out(w_Tx_Serial), 
    .tx_busy(w_Tx_Busy),                 
    .tx_done(w_Tx_Done)         
  );

  // Generate 50MHz Clock
  always #(CLK_PERIOD/2) r_Clock = ~r_Clock;

  initial begin
    $dumpfile("uart_tx.vcd"); 
    $dumpvars(0, tb_uart_tx);
    
    // Default state
    r_Tx_Start = 0;
    r_Tx_Byte  = 0;
    r_Reset    = 1; 
    #100; 
    r_Reset    = 0; 
    #95;

    // Test 1: Send 0x55 (Alternating bits 01010101)
    $display("Test 1: Sending 0x55...");
    r_Tx_Byte  = 8'h55; 
    r_Tx_Start = 1'b1;  
    #(CLK_PERIOD);      
    r_Tx_Start = 1'b0;  

    // Wait for the done signal
    @(posedge w_Tx_Done);
    $display("Test 1: Finished.");
    
    #95; 

    // Test 2: Send 0x37 (Random pattern)
    $display("Test 2: Sending 0x37...");
    r_Tx_Byte  = 8'h37;
    r_Tx_Start = 1'b1;
    #(CLK_PERIOD);
    r_Tx_Start = 1'b0;

    @(posedge w_Tx_Done);
    $display("Test 2: Finished.");
    #100;

    $finish; 
  end

endmodule