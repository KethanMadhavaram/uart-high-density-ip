`timescale 1ns / 1ps

// UART Top Level Module
// 
// Description:
//  Wraps UART Transmitter and Receiver into a single IP core.
//
// Configuration:
//  Clock Frequency: 50 MHz
//  Baud Rate: 9600
//
// Calculation:
//  Clocks per Bit = 50,000,000 / 9600 = 5208


module uart_top 
  #(parameter CLKS_PER_BIT = 5208)
  (
   // System Signals
   input        clk,
   input        rst,          // Master Reset (Applied to Tx)

   // Transmitter Interface
   input        tx_start,
   input [7:0]  tx_data_in,
   output       tx_serial_out,
   output       tx_busy,
   output       tx_done,

   // Receiver Interface
   input        rx_serial_in,
   output       rx_done,
   output [7:0] rx_data_out
   );

  // Instantiate Transmitter
  UART_Tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) TX_INST (
    .clk(clk),
    .tx_rst(rst),
    .start(tx_start),
    .tx_data_in(tx_data_in),
    .tx_serial_out(tx_serial_out), 
    .tx_busy(tx_busy),
    .tx_done(tx_done)
  );

  // Instantiate Receiver
  // Note: Rx samples at 16x oversampling, so tick calc is internal
  uart_rx #(.CLKS_PER_TICK(CLKS_PER_BIT/16)) RX_INST (
    .clk(clk),
    .rx_serial_in(rx_serial_in),  
    .rx_done(rx_done),
    .rx_data_out(rx_data_out)
  );

endmodule