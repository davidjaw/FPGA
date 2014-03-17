module FFT16(
			 clk,
			 rst,
			 x,
			 ab_valid,
			 fft_pe_valid,
			 y
			 );

input clk, rst;
input [32*16-1:0] x;
input ab_valid;
output fft_pe_valid;
output [32*16-1:0] y;

wire [31:0] x_inner [15:0];
wire [31:0] y_inner [15:0];
wire [31:0] stage_one_a [7:0];
wire [31:0] stage_one_b [7:0];
wire [31:0] stage_two_a [7:0];
wire [31:0] stage_two_b [7:0];
wire [31:0] stage_thr_a [7:0];
wire [31:0] stage_thr_b [7:0];

assign y = {y_inner[15], y_inner[14], y_inner[13], y_inner[12], y_inner[11], y_inner[10],
			y_inner[9], y_inner[8], y_inner[7], y_inner[6], y_inner[5], y_inner[4],
			y_inner[3], y_inner[2], y_inner[1], y_inner[0]};

assign x_inner[0] = x[32*1-1:32*0];
assign x_inner[1] = x[32*2-1:32*1];
assign x_inner[2] = x[32*3-1:32*2];
assign x_inner[3] = x[32*4-1:32*3];
assign x_inner[4] = x[32*5-1:32*4];
assign x_inner[5] = x[32*6-1:32*5];
assign x_inner[6] = x[32*7-1:32*6];
assign x_inner[7] = x[32*8-1:32*7];
assign x_inner[8] = x[32*9-1:32*8];
assign x_inner[9] = x[32*10-1:32*9];
assign x_inner[10] = x[32*11-1:32*10];
assign x_inner[11] = x[32*12-1:32*11];
assign x_inner[12] = x[32*13-1:32*12];
assign x_inner[13] = x[32*14-1:32*13];
assign x_inner[14] = x[32*15-1:32*14];
assign x_inner[15] = x[32*16-1:32*15];
							//a			b							fft_a			fft_b
FFT_PE fft_pe1 (clk, rst, x_inner[0], x_inner[8],  3'd0, ab_valid,  stage_one_a[0], stage_one_b[0], fft_pe_valid1);
FFT_PE fft_pe2 (clk, rst, x_inner[1], x_inner[9],  3'd1, ab_valid,  stage_one_a[1], stage_one_b[1], fft_pe_valid2);
FFT_PE fft_pe3 (clk, rst, x_inner[2], x_inner[10], 3'd2, ab_valid, stage_one_a[2], stage_one_b[2], fft_pe_valid3);
FFT_PE fft_pe4 (clk, rst, x_inner[3], x_inner[11], 3'd3, ab_valid, stage_one_a[3], stage_one_b[3], fft_pe_valid4);
FFT_PE fft_pe5 (clk, rst, x_inner[4], x_inner[12], 3'd4, ab_valid, stage_one_a[4], stage_one_b[4], fft_pe_valid5);
FFT_PE fft_pe6 (clk, rst, x_inner[5], x_inner[13], 3'd5, ab_valid, stage_one_a[5], stage_one_b[5], fft_pe_valid6);
FFT_PE fft_pe7 (clk, rst, x_inner[6], x_inner[14], 3'd6, ab_valid, stage_one_a[6], stage_one_b[6], fft_pe_valid7);
FFT_PE fft_pe8 (clk, rst, x_inner[7], x_inner[15], 3'd7, ab_valid, stage_one_a[7], stage_one_b[7], fft_pe_valid8);


FFT_PE fft_pe9 (clk, rst, stage_one_a[0], stage_one_a[4],  3'd0,  fft_pe_valid8, stage_two_a[0], stage_two_b[0], fft_pe_valid9);
FFT_PE fft_pe10 (clk, rst, stage_one_a[1], stage_one_a[5], 3'd2, fft_pe_valid8, stage_two_a[1], stage_two_b[1], fft_pe_valid10);
FFT_PE fft_pe11 (clk, rst, stage_one_a[2], stage_one_a[6], 3'd4, fft_pe_valid8, stage_two_a[2], stage_two_b[2], fft_pe_valid11);
FFT_PE fft_pe12 (clk, rst, stage_one_a[3], stage_one_a[7], 3'd6, fft_pe_valid8, stage_two_a[3], stage_two_b[3], fft_pe_valid12);
FFT_PE fft_pe13 (clk, rst, stage_one_b[0], stage_one_b[4], 3'd0, fft_pe_valid8, stage_two_a[4], stage_two_b[4], fft_pe_valid13);
FFT_PE fft_pe14 (clk, rst, stage_one_b[1], stage_one_b[5], 3'd2, fft_pe_valid8, stage_two_a[5], stage_two_b[5], fft_pe_valid14);
FFT_PE fft_pe15 (clk, rst, stage_one_b[2], stage_one_b[6], 3'd4, fft_pe_valid8, stage_two_a[6], stage_two_b[6], fft_pe_valid15);
FFT_PE fft_pe16 (clk, rst, stage_one_b[3], stage_one_b[7], 3'd6, fft_pe_valid8, stage_two_a[7], stage_two_b[7], fft_pe_valid16);


FFT_PE fft_pe17 (clk, rst, stage_two_a[0], stage_two_a[2], 3'd0, fft_pe_valid16, stage_thr_a[0], stage_thr_a[1], fft_pe_valid17);
FFT_PE fft_pe18 (clk, rst, stage_two_a[1], stage_two_a[3], 3'd4, fft_pe_valid16, stage_thr_b[0], stage_thr_b[1], fft_pe_valid18);
FFT_PE fft_pe19 (clk, rst, stage_two_b[0], stage_two_b[2], 3'd0, fft_pe_valid16, stage_thr_a[2], stage_thr_a[3], fft_pe_valid19);
FFT_PE fft_pe20 (clk, rst, stage_two_b[1], stage_two_b[3], 3'd4, fft_pe_valid16, stage_thr_b[2], stage_thr_b[3], fft_pe_valid20);
FFT_PE fft_pe21 (clk, rst, stage_two_a[4], stage_two_a[6], 3'd0, fft_pe_valid16, stage_thr_a[4], stage_thr_a[5], fft_pe_valid21);
FFT_PE fft_pe22 (clk, rst, stage_two_a[5], stage_two_a[7], 3'd4, fft_pe_valid16, stage_thr_b[4], stage_thr_b[5], fft_pe_valid22);
FFT_PE fft_pe23 (clk, rst, stage_two_b[4], stage_two_b[6], 3'd0, fft_pe_valid16, stage_thr_a[6], stage_thr_a[7], fft_pe_valid23);
FFT_PE fft_pe24 (clk, rst, stage_two_b[5], stage_two_b[7], 3'd4, fft_pe_valid16, stage_thr_b[6], stage_thr_b[7], fft_pe_valid24);


FFT_PE fft_pe25 (clk, rst, stage_thr_a[0], stage_thr_b[0], 3'd0, fft_pe_valid24, y_inner[0], y_inner[8], fft_pe_valid25);
FFT_PE fft_pe26 (clk, rst, stage_thr_a[1], stage_thr_b[1], 3'd0, fft_pe_valid24, y_inner[4], y_inner[12], fft_pe_valid26);
FFT_PE fft_pe27 (clk, rst, stage_thr_a[2], stage_thr_b[2], 3'd0, fft_pe_valid24, y_inner[2], y_inner[10], fft_pe_valid27);
FFT_PE fft_pe28 (clk, rst, stage_thr_a[3], stage_thr_b[3], 3'd0, fft_pe_valid24, y_inner[6], y_inner[14], fft_pe_valid28);
FFT_PE fft_pe29 (clk, rst, stage_thr_a[4], stage_thr_b[4], 3'd0, fft_pe_valid24, y_inner[1], y_inner[9], fft_pe_valid29);
FFT_PE fft_pe30 (clk, rst, stage_thr_a[5], stage_thr_b[5], 3'd0, fft_pe_valid24, y_inner[5], y_inner[13], fft_pe_valid30);
FFT_PE fft_pe31 (clk, rst, stage_thr_a[6], stage_thr_b[6], 3'd0, fft_pe_valid24, y_inner[3], y_inner[11], fft_pe_valid31);
FFT_PE fft_pe32 (clk, rst, stage_thr_a[7], stage_thr_b[7], 3'd0, fft_pe_valid24, y_inner[7], y_inner[15], fft_pe_valid32);

assign fft_pe_valid = fft_pe_valid32;

endmodule

