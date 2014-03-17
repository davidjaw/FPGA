`timescale 1ns/100ps
module FC(clk, rst, cmd, done, M_RW, M_A, M_D, F_IO, F_CLE, F_ALE, F_REN, F_WEN, F_RB);
input clk;
input rst;
input [32:0] cmd;
output reg done;
output M_RW;
output reg [6:0] M_A;
inout  [7:0] M_D;
inout  [7:0] F_IO;
output reg F_CLE;
output reg F_ALE;
output reg F_REN;
output reg F_WEN;
input F_RB;

reg M_D_e, F_IO_e, IM_trigger, F_WEN_flip, delay, delay2, delay3;
reg [7:0] M_D_reg, F_IO_reg;
reg [32:0] cmd_reg;
reg [7:0] IM_count, flash_count;
reg [4:0] state;
reg [1:0] R_REN_flip;

parameter IDLE2=5'd0;
parameter RESET=5'd1;
parameter PAUSE=5'd14;
parameter READ_CMD=5'd2;
parameter W_A8_JUDGE=5'd3;
parameter W_A8_TRUE=5'd4;
parameter W_A8_FALSE=5'd5;
parameter W_ADDR_CYCLE1=5'd6;
parameter W_ADDR_CYCLE2=5'd7;
parameter W_ADDR_CYCLE3=5'd8;
parameter W_DATA_CYCLE=5'd9;
parameter IDLE=5'd10;
parameter W_DATA_CYCLE_OK=5'd11;
parameter W_WRITE_10H=5'd12;
parameter W_BUSY_JUDGE=5'd13;
parameter R_A8_JUDGE=5'd15;
parameter R_ADDR_CYCLE1=5'd16;
parameter R_ADDR_CYCLE2=5'd17;
parameter R_ADDR_CYCLE3=5'd18;
parameter R_BUSY_JUDGE=5'd19;
parameter R_DATA_CYCLE=5'd20;

wire flash_read;
wire [17:0] flash_addr;
wire [6:0] IM_addr;
wire [6:0] data_length;

assign flash_read = cmd_reg[32];
assign flash_addr = cmd_reg[31:14];
assign IM_addr = cmd_reg[13:7];
assign data_length = cmd_reg[6:0];

assign M_D = (M_D_e) ? M_D_reg : 8'dz;
assign F_IO = (F_IO_e) ? F_IO_reg : 8'dz;
assign M_RW = ~M_D_e;

// state
always@(negedge clk or posedge rst) begin
	if (rst) begin
		state <= PAUSE;
		delay2 <= 0;
	end
	else begin
		case(state)
			IDLE2 : begin
				state <= READ_CMD;
			end
			READ_CMD: begin
				state <= RESET;
			end
			RESET: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= (flash_read)? R_A8_JUDGE : W_A8_JUDGE;
					delay2 <= 0;
				end
			end
			W_A8_JUDGE: begin
				if(flash_addr[8] == 1) state <= W_A8_TRUE;
				else state <= W_A8_FALSE;
			end
			W_A8_TRUE: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= W_A8_FALSE;
					delay2 <= 0;
				end
			end
			W_A8_FALSE: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= W_ADDR_CYCLE1;
					delay2 <= 0;
				end
			end
			W_ADDR_CYCLE1,
			W_ADDR_CYCLE2,
			W_ADDR_CYCLE3: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= state + 1;
					delay2 <= 0;
				end
			end
			W_DATA_CYCLE: begin
				state <= IDLE;
			end
			IDLE: begin
				state <= W_DATA_CYCLE_OK;			
			end
			W_DATA_CYCLE_OK: begin
				if(flash_count == data_length) state <= W_WRITE_10H;			
			end
			W_WRITE_10H: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= W_BUSY_JUDGE;
					delay2 <= 0;
				end
			end
			W_BUSY_JUDGE: begin
				if(F_RB) state <= PAUSE;
			end
			PAUSE: begin
				state <= IDLE2;
			end
			R_A8_JUDGE: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= R_ADDR_CYCLE1;
					delay2 <= 0;
				end
			end
			R_ADDR_CYCLE1,
			R_ADDR_CYCLE2,
			R_ADDR_CYCLE3: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					state <= state + 1;
					delay2 <= 0;
				end
			end
			R_BUSY_JUDGE: begin
				if(F_RB) state <= R_DATA_CYCLE;
			end
			R_DATA_CYCLE: begin
				delay2 <= 1;
				if(delay2 == 1) begin
					if(flash_count == data_length) state <= PAUSE;
					delay2 <= 0;
				end
			end
		endcase
	end
end

// controller
always@(negedge clk or posedge rst) begin
	if (rst) begin
		IM_trigger <= 0;
		M_D_e <= 0;
		F_IO_e <= 1;
		M_D_reg <= 8'd0;
		F_IO_reg <= 8'd0;
		flash_count <=0;
		delay <= 0;
		done <= 0;
		cmd_reg <= 0;
	end
	else begin
		case(state)
			IDLE2 : begin
				done <= 0;
			end
			READ_CMD: begin
				cmd_reg <= cmd;
				done <= 0;
			end
			RESET: begin
				done <= 0;
				F_IO_e <= 1;
				F_IO_reg <= 8'hff;	
			end			
			W_A8_TRUE: begin
				F_IO_e <= 1;
				F_IO_reg <= 8'h01;
			end
			W_A8_FALSE: begin
				F_IO_e <= 1;
				F_IO_reg <= 8'h80;
			end
			W_ADDR_CYCLE1: begin
				F_IO_e <= 1;
				F_IO_reg <= flash_addr[7:0];			
			end					
			W_ADDR_CYCLE2: begin
				F_IO_e <= 1;
				F_IO_reg <= flash_addr[16:9];	
			end					
			W_ADDR_CYCLE3: begin
				F_IO_e <= 1;
				F_IO_reg <= {7'd0, flash_addr[17]};
			end
			W_DATA_CYCLE: begin
				IM_trigger <= 1;
				M_D_e <= 0;
				F_IO_e <= 1;
			end
			W_DATA_CYCLE_OK: begin
				if(delay == 0) begin
					if(flash_count != data_length+1) begin
						F_IO_reg <= M_D;
						flash_count <= flash_count+1;
					end
					delay <= 1;
				end
				else begin
					delay <= 0;
				end
			end
			W_WRITE_10H: begin
				F_IO_e <= 1;
				F_IO_reg <= 8'h10;
				IM_trigger <= 0;
				flash_count <= 0;
			end
			PAUSE: begin
				done <= 1;
				IM_trigger <= 0;
				flash_count <= 0;
			end
			R_A8_JUDGE: begin
				F_IO_e <= 1;
				F_IO_reg <= (flash_addr[8])? 8'h01 : 8'h00;
			end
			R_ADDR_CYCLE1: begin
				F_IO_e <= 1;
				F_IO_reg <= flash_addr[7:0];				
			end
			R_ADDR_CYCLE2: begin
				F_IO_e <= 1;
				F_IO_reg <= flash_addr[16:9];				
			end
			R_ADDR_CYCLE3: begin
				F_IO_e <= 1;
				F_IO_reg <= {7'd0, flash_addr[17]};	
				delay <= 0;
			end
			R_DATA_CYCLE: begin
				F_IO_e <= 0;
				M_D_e <= 1;
				IM_trigger <= 1;
				if(delay == 1) begin
					if(flash_count != data_length) begin
						M_D_reg <= F_IO;
						flash_count <= flash_count+1;
					end
					delay <= 0;
				end
				else begin
					delay <= 1;
				end
			end
		endcase
	end
end

// could be crash
always@(negedge clk or posedge rst) begin //flash write
	if (rst) begin
		F_CLE <= 0;
		F_ALE <= 0;
		F_REN <= 1;
		F_WEN <= 0;
		F_WEN_flip <= 0;
		R_REN_flip <= 0;
	end
	else begin
		case(state)
			RESET, R_A8_JUDGE, W_A8_TRUE, W_A8_FALSE, W_WRITE_10H: begin
				F_CLE <= 1;
				F_ALE <= 0;
				case (F_WEN_flip)
					0: begin
						F_WEN <= 0;
						F_WEN_flip <= 1;
					end
					1: begin
						F_WEN <= 1;
						F_WEN_flip <= 0;
					end
				endcase
			end
			R_ADDR_CYCLE1,
			R_ADDR_CYCLE2,
			R_ADDR_CYCLE3,
			W_ADDR_CYCLE1,
			W_ADDR_CYCLE2,
			W_ADDR_CYCLE3: begin
				F_CLE <= 0;
				F_ALE <= 1;
				case (F_WEN_flip)
					0: begin
						F_WEN <= 0;
						F_WEN_flip <= 1;
					end
					1: begin
						F_WEN <= 1;
						F_WEN_flip <= 0;
					end
				endcase
			end
			W_DATA_CYCLE_OK: begin
				F_CLE <= 0;
				F_ALE <= 0;
				// F_REN <= 0;
				case (F_WEN_flip)
					0: begin
						F_WEN <= 0;
						F_WEN_flip <= 1;
					end
					1: begin
						F_WEN <= 1;
						F_WEN_flip <= 0;
					end
				endcase
			end
			R_DATA_CYCLE: begin
				F_CLE <= 0;
				F_ALE <= 0;
				case (R_REN_flip)
					0: begin
						F_REN <= 0;
						R_REN_flip <= 1;
					end
					1: begin
						F_REN <= 1;
						R_REN_flip <= 0;
					end
					// 2: begin
						// F_REN <= 1;
						// R_REN_flip <= 0;
					// end
				endcase
			end
		endcase
	end
end

always@(negedge clk or posedge rst) begin //IM part
	if (rst) begin
		IM_count<=0;
		delay3<=0;
		M_A<=0;
	end
	else begin
		if (IM_trigger) begin
			if(!delay3) begin
				if(IM_count != data_length) begin
					IM_count <= IM_count + 1;
					M_A <= IM_addr + IM_count;
				end
				else begin
					IM_count <= 0;
				end
				delay3 <= 1;
			end
			else begin
				delay3 <= 0;
			end
			// if(M_D_e) begin
				//output M_D_reg

			// end
			// else begin
				//input

			// end
		end
	end
end

endmodule
