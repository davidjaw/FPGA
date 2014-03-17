module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
	input clk;
	input reset;
	input nt;
	input [2:0] xi, yi;
	output reg busy;
	output reg po;
	output reg [2:0] xo, yo;
	//
	reg [7:0] saved_x [3:1];
	reg [7:0] saved_y [3:1];
	reg [7:0] current_x,current_y;
	reg trigger_END,trigger_nt;
	reg [1:0] state,counter;
	parameter loaddata=2'b00;
	parameter state_output=2'b01;
	parameter state_cheak=2'b10;
	parameter get_slope=2'b11;
	reg [7:0] slope;
	//
	always@(posedge clk) begin
		if(reset) begin
			busy<=0;
			po<=0;
			counter<=0;
			state<=loaddata;
			current_x<=1;
			current_y<=1;
			trigger_END<=0;
			trigger_nt<=1;
		end
		if(!reset) begin
			case (state)
				loaddata: begin
					if(nt && !trigger_nt) begin
						trigger_nt<=1;
						busy<=1;
						saved_x[current_x]<=xi;
						saved_y[current_y]<=yi;
						current_x<=current_x+1;
						current_y<=current_y+1;
						counter<=counter+1;
					end
					else if(trigger_nt) begin
						if(counter == 3) begin
							state<=state_cheak;
							counter<=0;
							current_x<=saved_x[1];
							current_y<=saved_y[1];
							trigger_nt<=0;
							slope<=(saved_y[3]-saved_y[2])*(current_x-saved_x[3])-(saved_x[2]-saved_x[3])*(saved_y[3]-current_y);
						end
						else begin
							busy<=1;
							saved_x[current_x]<=xi;
							saved_y[current_y]<=yi;
							current_x<=current_x+1;
							current_y<=current_y+1;
							counter<=counter+1;
						end
					end
				end
				state_cheak: begin
					if(!trigger_END) begin
						if(current_x!=saved_x[1]) begin
							if($signed(slope)>0) begin //slop<0 outside triangle
								current_x<=saved_x[1];
								current_y<=current_y+1;
								state<=get_slope;
							end
							else state<=state_output;
						end
						else begin
							if(current_y!=saved_y[3])  state<=state_output;
							else begin	
								trigger_END<=1;
								state<=state_output;
							end
						end
					end
					else begin
						busy<=0;
						state<=loaddata;
						current_x<=1;
						current_y<=1;
						trigger_END<=0;
					end
				end
				state_output: begin
					po<=1;
					xo<=current_x;
					yo<=current_y;
					current_x<=current_x+1;
					state<=get_slope;
				end
				get_slope: begin
					po<=0;
					slope<=(saved_y[3]-saved_y[2])*(current_x-saved_x[3])-(saved_x[2]-saved_x[3])*(saved_y[3]-current_y);
					state<=state_cheak;
				end
			endcase
		end
	end
	endmodule
	
