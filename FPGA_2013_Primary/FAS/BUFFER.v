module BUFFER(
       clk, 
       rst, 
       data_valid_i, 
       data,
	   x,
	   data_valid_o
       );
       
input	clk;
input	rst;
input	data_valid_i;
input [15:0] data;

output [32*16-1:0] x;
output reg data_valid_o;

reg [15:0] data_saved [159:0];
reg [7:0] counter1;	//0~16
reg [7:0] counter2; //0~10

reg [31:0] x_inner [15:0];
reg trigger;

assign x = {x_inner[15], x_inner[14], x_inner[13], x_inner[12],
			x_inner[11], x_inner[10], x_inner[9], x_inner[8],
			x_inner[7], x_inner[6], x_inner[5], x_inner[4],
			x_inner[3], x_inner[2], x_inner[1], x_inner[0]};

// receive data from controller
always@(posedge clk, posedge rst) begin

	if(rst == 1) begin
		counter1 <= 0;
		counter2 <= 0;
		trigger <= 0;
	end
	else begin
		if(data_valid_i) begin
			if(counter1 != 16) begin
				data_saved[counter2*16+counter1] <= data;
				counter1 <= counter1 + 1;
				trigger <= 0;
			end
			else begin
				data_saved[(counter2+1)*16] <= data;
				counter1 <= 1;
				counter2 <= counter2 + 1;
				trigger <= 1;
			end
		end
	end

end

// send data to fft module
always@(posedge clk, posedge rst) begin

	if(rst == 1) begin
		data_valid_o <= 0;
	end
	else if(trigger) begin	// next could be wrong
		x_inner[0]  <= {data_saved[(counter2-1)*16+0], 16'd0}; 
		x_inner[1]  <= {data_saved[(counter2-1)*16+1], 16'd0}; 
		x_inner[2]  <= {data_saved[(counter2-1)*16+2], 16'd0}; 
		x_inner[3]  <= {data_saved[(counter2-1)*16+3], 16'd0}; 
		x_inner[4]  <= {data_saved[(counter2-1)*16+4], 16'd0}; 
		x_inner[5]  <= {data_saved[(counter2-1)*16+5], 16'd0}; 
		x_inner[6]  <= {data_saved[(counter2-1)*16+6], 16'd0}; 
		x_inner[7]  <= {data_saved[(counter2-1)*16+7], 16'd0}; 
		x_inner[8]  <= {data_saved[(counter2-1)*16+8], 16'd0}; 
		x_inner[9]  <= {data_saved[(counter2-1)*16+9], 16'd0}; 
		x_inner[10] <= {data_saved[(counter2-1)*16+10], 16'd0};
		x_inner[11] <= {data_saved[(counter2-1)*16+11], 16'd0};
		x_inner[12] <= {data_saved[(counter2-1)*16+12], 16'd0};
		x_inner[13] <= {data_saved[(counter2-1)*16+13], 16'd0};
		x_inner[14] <= {data_saved[(counter2-1)*16+14], 16'd0};
		x_inner[15] <= {data_saved[(counter2-1)*16+15], 16'd0};
		data_valid_o <= 1;
	end
	else data_valid_o <= 0;

end

endmodule
