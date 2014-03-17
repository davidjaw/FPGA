include "C:/Users/user/Desktop/FPGA/2013/FFT_PE/FFT16.v";

module FAS(
       clk, 
       rst, 
       data_valid, 
       data, 
       fft_d0,fft_d1,fft_d2,fft_d3,fft_d4,fft_d5,fft_d6,fft_d7,
       fft_d8,fft_d9,fft_d10,fft_d11,fft_d12,fft_d13,fft_d14,fft_d15,
       fft_valid,
       done,
       freq
       );
       
input	clk;
input	rst;
input	data_valid;
input signed [15:0] data;
output [31:0] fft_d0,fft_d1,fft_d2,fft_d3,fft_d4,fft_d5,fft_d6,fft_d7, 
              fft_d8,fft_d9,fft_d10,fft_d11,fft_d12,fft_d13,fft_d14,fft_d15;
output fft_valid;
output done;                      
output [3:0] freq;

wire [32*16-1:0] y;
wire [32*16-1:0] x;

assign fft_d0 = y[32*1-1:0];
assign fft_d1 = y[32*2-1:32*1];
assign fft_d2 = y[32*3-1:32*2];
assign fft_d3 = y[32*4-1:32*3];
assign fft_d4 = y[32*5-1:32*4];
assign fft_d5 = y[32*6-1:32*5];
assign fft_d6 = y[32*7-1:32*6];
assign fft_d7 = y[32*8-1:32*7];
assign fft_d8 = y[32*9-1:32*8];
assign fft_d9 = y[32*10-1:32*9];
assign fft_d10 = y[32*11-1:32*10];
assign fft_d11 = y[32*12-1:32*11];
assign fft_d12 = y[32*13-1:32*12];
assign fft_d13 = y[32*14-1:32*13];
assign fft_d14 = y[32*15-1:32*14];
assign fft_d15 = y[32*16-1:32*15];

BUFFER buffer1(clk, rst, data_valid, data, x, buffer_valid);
FFT16 fft1(clk, rst, x, buffer_valid, fft_valid, y);
ANALYSIS analysis1(clk, rst, fft_valid, y, done, freq);

endmodule
