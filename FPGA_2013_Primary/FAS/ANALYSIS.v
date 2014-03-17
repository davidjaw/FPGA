module ANALYSIS(
       clk, 
       rst, 
       fft_valid, 
       data,
	   done,
	   freq
       );

input	clk;
input	rst;
input	fft_valid;
input signed [32*16-1:0] data;
reg [63:0] calc_data [15:0];
reg [2:0] state;

integer i;

output reg done;
output reg [3:0] freq;

wire signed [16*32-1:0] data_inner[15:0];

wire [63:0] v [30:1];

assign data_inner[0] = data[32*1-1:0];
assign data_inner[1] = data[32*2-1:32*1];
assign data_inner[2] = data[32*3-1:32*2];
assign data_inner[3] = data[32*4-1:32*3];
assign data_inner[4] = data[32*5-1:32*4];
assign data_inner[5] = data[32*6-1:32*5];
assign data_inner[6] = data[32*7-1:32*6];
assign data_inner[7] = data[32*8-1:32*7];
assign data_inner[8] = data[32*9-1:32*8];
assign data_inner[9] = data[32*10-1:32*9];
assign data_inner[10] = data[32*11-1:32*10];
assign data_inner[11] = data[32*12-1:32*11];
assign data_inner[12] = data[32*13-1:32*12];
assign data_inner[13] = data[32*14-1:32*13];
assign data_inner[14] = data[32*15-1:32*14];
assign data_inner[15] = data[32*16-1:32*15];

comparator u1(calc_data[0], calc_data[1], v[1], v[2]);
comparator u2(calc_data[2], calc_data[3], v[3], v[4]);
comparator u3(calc_data[4], calc_data[5], v[5], v[6]);
comparator u4(calc_data[6], calc_data[7], v[7], v[8]);
comparator u5(calc_data[8], calc_data[9], v[9], v[10]);
comparator u6(calc_data[10], calc_data[11], v[11], v[12]);
comparator u7(calc_data[12], calc_data[13], v[13], v[14]);
comparator u8(calc_data[14], calc_data[15], v[15], v[16]);
           
comparator u9(v[1], v[3], v[17], v[18]);
comparator u10(v[5], v[7], v[19], v[20]);
comparator u11(v[9], v[11], v[21], v[22]);
comparator u12(v[13], v[15], v[23], v[24]);
           
comparator u13(v[17], v[19], v[25], v[26]);
comparator u14(v[21], v[23], v[27], v[28]);
           
comparator u15(v[25], v[27], v[29], v[30]);
	
always@(posedge clk or posedge rst) begin

	if(rst == 1) begin
		done <= 0;
		state <= 0;
	end
	else if(fft_valid) begin
		state <= 1;
	end
	case (state)
		1: begin
			calc_data[0]  <= data_inner[0] * data_inner[0];
			calc_data[1]  <= data_inner[1] * data_inner[1];
			calc_data[2]  <= data_inner[2] * data_inner[2];
			calc_data[3]  <= data_inner[3] * data_inner[3];
			calc_data[4]  <= data_inner[4] * data_inner[4];
			calc_data[5]  <= data_inner[5] * data_inner[5];
			calc_data[6]  <= data_inner[6] * data_inner[6];
			calc_data[7]  <= data_inner[7] * data_inner[7];
			calc_data[8]  <= data_inner[8] * data_inner[8];
			calc_data[9]  <= data_inner[9] * data_inner[9];
			calc_data[10] <= data_inner[10] * data_inner[10];
			calc_data[11] <= data_inner[11] * data_inner[11];
			calc_data[12] <= data_inner[12] * data_inner[12];
			calc_data[13] <= data_inner[13] * data_inner[13];
			calc_data[14] <= data_inner[14] * data_inner[14];
			calc_data[15] <= data_inner[15] * data_inner[15];
			state <= 2;
		end
		2: begin
			done <= 1;
			freq <= (v[29]==calc_data[0])? 0:
			(v[29]==calc_data[1])? 1:
			(v[29]==calc_data[2])? 2:
			(v[29]==calc_data[3])? 3:
			(v[29]==calc_data[4])? 4:
			(v[29]==calc_data[5])? 5:
			(v[29]==calc_data[6])? 6:
			(v[29]==calc_data[7])? 7:
			(v[29]==calc_data[8])? 8:
			(v[29]==calc_data[9])? 9:
			(v[29]==calc_data[10])? 10:
			(v[29]==calc_data[11])? 11:
			(v[29]==calc_data[12])? 12:
			(v[29]==calc_data[13])? 13:
			(v[29]==calc_data[14])? 14:
			(v[29]==calc_data[15])? 15:15;
			state <= 0;
		end
		default: done <= 0;
	endcase
end

endmodule
