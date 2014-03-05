module LCD_CTRL(clk,reset,cmd,cmd_valid,datain,dataout,output_valid,busy);
	input reset;
	input clk;
	input cmd_valid;
	input [2:0] cmd;
	input [7:0] datain;
	output reg [7:0] dataout;
	output reg output_valid;
	output reg busy;
	//
	reg [7:0] data_saved [107:0]; //12*9
	reg [3:0] x,y,state_next,state_current,current_x,current_y,x_zoomreg,y_zoomreg;
	parameter load_data=4'b0000;
	parameter zoom_in=4'b0001;
	parameter zoom_fit=4'b0010;
	parameter shift_right=4'b0011;
	parameter shift_left=4'b0100;
	parameter shift_up=4'b0101;
	parameter shift_down=4'b0110;
	parameter pause=4'b0111;
	parameter state_out=4'b1000;
	reg zooming;
	reg [6:0] counter;
	//
	always@(*)
	begin
		if(!busy) begin
			if(cmd==1 && zooming)		state_next<=state_out;
			else if(cmd>2 && zooming)  	state_next<=cmd;
			else if(cmd>2 && !zooming)  	state_next<=zoom_fit;
			else if(cmd<3)  			state_next<=cmd;
			else  						state_next<=pause;
		end
	end
	//
	always@(posedge clk)
	begin
		if(reset) begin
			output_valid<=0;
			dataout<=0;
			busy<=0;
			state_current<=pause;
			counter<=0;
			x<=1;
			y<=1;
		end
		else begin
			case (state_current)
				pause: begin
					state_current<=state_next;
					if(state_next!=pause) busy<=1;
				end
				load_data: begin
					zooming<=0;
					if(counter != 108) begin
						if(y==1) begin 
							data_saved[x*y-1]<=datain;
						end
						else begin
							data_saved[x+12*(y-1)-1]<=datain;
						end
						if(x==12) begin
							x<=1;
							y<=y+1;
							counter<=counter+1;
						end
						else begin
							x<=x+1;
							counter<=counter+1;
						end
					end
					else begin
						counter<=0;
						state_current<=zoom_fit;
						x<=1;
						y<=1;
					end
				end
				zoom_fit: begin
					zooming<=0;
					current_x<=2;
					current_y<=2;
					state_current<=state_out;
				end
				zoom_in: begin
					zooming<=1;
					current_x<=5;
					current_y<=4;
					x_zoomreg<=8;
					y_zoomreg<=4;
					state_current<=state_out;
				end
				shift_up: begin
					current_y<=(current_y==1)?(current_y):(current_y-1);
					state_current<=state_out;
					x_zoomreg<=current_x+3;
					y_zoomreg<=(current_y==1)?(current_y):(current_y-1);
				end
				shift_down: begin
					current_y<=(current_y==6)?(current_y):(current_y+1);
					state_current<=state_out;
					x_zoomreg<=current_x+3;
					y_zoomreg<=(current_y==6)?(current_y):(current_y+1);
				end
				shift_left: begin
					current_x<=(current_x==1)?(current_x):(current_x-1);
					state_current<=state_out;
					x_zoomreg<=(current_x==1)?(current_x+3):(current_x+2);
					y_zoomreg<=current_y;
				end
				shift_right: begin
					current_x<=(current_x==9)?(current_x):(current_x+1);
					state_current<=state_out;
					x_zoomreg<=(current_x==9)?(current_x+3):(current_x+4);
					y_zoomreg<=current_y;
				end
				state_out: begin
					if(counter!=16) begin
						output_valid<=1;
						if (current_y==1) begin
							dataout<=data_saved[current_x*current_y-1];
						end
						else begin
							dataout<=data_saved[current_x+12*(current_y-1)-1];
						end
						if(zooming) begin
							if(current_x==x_zoomreg) begin
								current_x<=x_zoomreg-3;
								current_y<=current_y+1;	
								counter<=counter+1;		
							end
							else begin
								current_x<=current_x+1;	
								counter<=counter+1;		
							end
						end
						else begin
							if(current_x==11) begin
								current_x<=2;
								current_y<=current_y+2;
								counter<=counter+1;		
							end
							else begin
								current_x<=current_x+3;	
								counter<=counter+1;		
							end
						end
					end
					else begin
						counter<=0;
						busy<=0;
						output_valid<=0;
						state_current<=pause;
						current_x<=x_zoomreg-3;
						current_y<=y_zoomreg;
					end
				end
				
			endcase
		end
	end
	//
endmodule
	
