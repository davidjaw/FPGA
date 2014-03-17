module FFT_PE(
			 clk,
			 rst,
			 a,
			 b,
			 power,
			 ab_valid,
			 fft_a,
			 fft_b,
			 fft_pe_valid
			 );
input clk, rst;
input signed [31:0] a, b;
input [2:0] power;
input ab_valid;
output [31:0] fft_a, fft_b;
output reg fft_pe_valid;

wire signed [31:0] w_r [7:0];
wire signed [31:0] w_i [7:0];

// real
wire signed [31:0] a_i, c_i;
// image
wire signed [31:0] b_i, d_i; 

reg signed [31:0] fft_a_r, fft_b_r;
reg signed [31:0] fft_a_i, fft_b_i;

assign a_i = a[31:16];
assign b_i = a[15:0];
assign c_i = b[31:16];
assign d_i = b[15:0];

assign fft_a = {fft_a_r[15:0], fft_a_i[15:0]};
assign fft_b = {fft_b_r[31:16], fft_b_i[31:16]};

assign w_r[0] = 32'h00010000;
assign w_r[1] = 32'h0000EC83;
assign w_r[2] = 32'h0000B504;
assign w_r[3] = 32'h000061F7;
assign w_r[4] = 32'h00000000;
assign w_r[5] = 32'hFFFF9E09;
assign w_r[6] = 32'hFFFF4AFC;
assign w_r[7] = 32'hFFFF137D;

assign w_i[0] = 32'h00000000;
assign w_i[1] = 32'hFFFF9E09;
assign w_i[2] = 32'hFFFF4AFC;
assign w_i[3] = 32'hFFFF137D;
assign w_i[4] = 32'hFFFF0000;
assign w_i[5] = 32'hFFFF137D;
assign w_i[6] = 32'hFFFF4AFC;
assign w_i[7] = 32'hFFFF9E09;

wire signed [64:0] debug;
assign debug = (a_i-c_i)*w_r[0];

always@(posedge clk or posedge rst) begin
	if(rst == 1) begin
		fft_pe_valid <= 0;
	end
	else begin
		if(ab_valid) begin
			fft_a_r <= (a_i+c_i);
			fft_a_i <= (b_i+d_i);

			fft_b_r <= (a_i-c_i)*w_r[power]-(b_i-d_i)*w_i[power];
			fft_b_i <= (b_i-d_i)*w_r[power]+(a_i-c_i)*w_i[power];		

			fft_pe_valid <= 1;
		end
		else fft_pe_valid <= 0;
	end
end

endmodule

