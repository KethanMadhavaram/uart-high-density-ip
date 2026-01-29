`timescale 1ns / 1ps

// UART Transmitter (Tx)
// 
// Configuration:
// - Clock Frequency: 50 MHz
// - Baud Rate: 9600
//
// Calculation:
// Clocks per Bit = 50,000,000 / 9600 = 5208

module UART_Tx 
  #(parameter CLKS_PER_BIT = 5208)
  (
   input       start,
   input       clk,
   input       tx_rst,          
   input [7:0] tx_data_in,      
   output reg  tx_serial_out,   
   output reg  tx_busy,         
   output reg  tx_done          
   );

  reg [12:0] clk_count;
  reg [2:0]  bit_index;
  reg [2:0]  tx_state;          
  reg [7:0]  tx_data_buffer;    

  parameter IDLE      = 2'b00;
  parameter START_BIT = 2'b01;
  parameter DATA_BITS = 2'b10;
  parameter STOP_BIT  = 2'b11;

  always @(posedge clk)
  begin
    if(tx_rst) 
    begin
        tx_state      <= IDLE;          
        tx_serial_out <= 1'b1;  
        tx_done       <= 1'b0;          
        tx_busy       <= 1'b0;          
        clk_count     <= 0;
        bit_index     <= 0;
    end
    else 
    case(tx_state) 
      
      // Wait for the start signal
      IDLE : begin 
          tx_serial_out <= 1'b1; // Idle line is High
          tx_done       <= 1'b0;        
          tx_busy       <= 1'b0;        
          clk_count     <= 0;
          bit_index     <= 0;
          
          if(start)
          begin
              tx_busy        <= 1'b1;           
              tx_data_buffer <= tx_data_in;     
              tx_state       <= START_BIT;      
          end
      end

      // Send Start Bit (Logic Low)
      START_BIT : begin
          if(clk_count < CLKS_PER_BIT - 1)
          begin
              tx_serial_out <= 1'b0; 
              clk_count     <= clk_count + 1;
          end
          else
          begin
              clk_count <= 0;
              tx_state  <= DATA_BITS;   
           end 
      end

      // Send Data Bits (LSB first)
      DATA_BITS : begin
          if(clk_count < CLKS_PER_BIT - 1)
          begin
              tx_serial_out <= tx_data_buffer[bit_index]; 
              clk_count     <= clk_count + 1;
           end
           else 
           begin
              clk_count <= 0;
              if(bit_index < 7)
              begin
                  bit_index <= bit_index + 1;
                  tx_state  <= DATA_BITS; 
              end
              else
              begin
                  bit_index <= 0;
                  tx_state  <= STOP_BIT;  
              end
           end 
      end 

      // Send Stop Bit (Logic High)
      STOP_BIT : begin 
          if(clk_count < CLKS_PER_BIT - 1)
          begin
              tx_serial_out <= 1'b1; 
              clk_count     <= clk_count + 1;
          end
          else
          begin
              tx_done  <= 1'b1;   
              tx_busy  <= 1'b0;   
              tx_state <= IDLE;   
          end 
      end 
      
      default: tx_state <= IDLE;
      
    endcase
  end
endmodule