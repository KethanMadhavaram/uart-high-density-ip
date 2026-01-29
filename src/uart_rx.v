`timescale 1ns / 1ps

// -------------------------------------------------------------------------
// UART Receiver (Rx)
// 
// Configured for:
//  Clock Frequency: 50 MHz
//  Baud Rate: 9600
//  Oversampling: 16x (16 ticks per bit)
//
// Calculation:
// Clocks per Bit  = 50,000,000 / 9600 = 5208
// Clocks per Tick = 5208 / 16 = 325.5 (rounded to 325)
// -------------------------------------------------------------------------

module uart_rx 
  #(parameter CLKS_PER_TICK = 325)
  (
   input        clk,
   input        rx_serial_in,   // Renamed from rx_serial
   output reg   rx_done,        // Renamed from dv
   output reg [7:0] rx_data_out // Renamed from rx_byte
   );
    
  parameter s_IDLE  = 3'b000;
  parameter s_START = 3'b001;
  parameter s_DATA  = 3'b010;
  parameter s_STOP  = 3'b011;
  parameter s_CLEAN = 3'b100;
   
  reg [2:0]  rx_state = 0;      // Renamed from state
  reg [7:0]  rx_data_buffer = 0;
  reg [2:0]  bit_index = 0;
  reg [12:0] clk_count = 0; 
  reg        tick = 0; 
  reg [3:0]  tick_count = 0;
  reg [1:0]  sample_sum = 0; 

  // Initialize outputs
  initial begin
    rx_done = 0;
    rx_data_out = 0;
  end

  // Purpose: Generate a tick 16 times for every data bit
  // This allows us to sample the center of the bit for stability
  always @(posedge clk) begin
    if (clk_count < CLKS_PER_TICK-1) begin
      clk_count <= clk_count + 1;
      tick      <= 1'b0;
    end else begin
      clk_count <= 0;
      tick      <= 1'b1;
    end
  end

  // Purpose: Main FSM for receiving 8-bit data (8N1 format)
  always @(posedge clk) begin
    case (rx_state)
      s_IDLE : begin
          rx_done <= 1'b0;
          tick_count <= 0;
          sample_sum <= 0;
          bit_index <= 0;
          
          // Start bit is always a logic low (0)
          if (rx_serial_in == 1'b0) 
            rx_state <= s_START;
      end

      // Confirm start bit is valid by sampling the middle
      s_START : begin
          if (tick == 1'b1) begin
            // Sample at ticks 7, 8, 9 (middle of the start bit)
            if (tick_count == 7 || tick_count == 8 || tick_count == 9) 
                sample_sum <= sample_sum + rx_serial_in;

            if (tick_count == 15) begin
                // If majority samples are 0, it's a real start bit
                if (sample_sum < 2) begin
                    rx_state <= s_DATA;
                    tick_count <= 0; 
                    sample_sum <= 0;
                end else begin
                    // False alarm (glitch), go back to IDLE
                    rx_state <= s_IDLE;
                end
            end else begin
                tick_count <= tick_count + 1;
            end
          end
      end

      // Sample the actual data bits
      s_DATA : begin
          if (tick == 1'b1) begin
            // Again, sample in the middle (ticks 7, 8, 9)
            if (tick_count == 7 || tick_count == 8 || tick_count == 9) 
                sample_sum <= sample_sum + rx_serial_in;

            if (tick_count == 15) begin
               tick_count <= 0; 
               // Majority vote: if sum >= 2, the bit is a 1
               rx_data_buffer[bit_index] <= (sample_sum >= 2) ? 1'b1 : 1'b0;
               sample_sum <= 0;
               
               if (bit_index < 7) begin
                   bit_index <= bit_index + 1;
               end else begin
                   bit_index <= 0; 
                   rx_state <= s_STOP; 
               end
            end else begin
               tick_count <= tick_count + 1;
            end
          end
      end

      // Handle the Stop Bit (should be High)
      s_STOP : begin
          if (tick == 1'b1) begin
            if (tick_count == 15) begin
              rx_done <= 1'b1;       // Signal that valid data is ready
              rx_data_out <= rx_data_buffer;
              rx_state <= s_CLEAN;
            end else begin
               tick_count <= tick_count + 1;
            end
          end
      end

      // One clock cycle cleanup state
      s_CLEAN : begin
          rx_state <= s_IDLE;
          rx_done <= 1'b0;
      end

      default : rx_state <= s_IDLE;
    endcase
  end    
endmodule