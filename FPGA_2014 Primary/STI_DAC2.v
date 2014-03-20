module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input	clk, reset;
input	load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input	pi_fill;
output reg so_data, so_valid;

output reg pixel_finish, pixel_wr;
output reg [8:0] pixel_addr;
output reg [7:0] pixel_dataout;

//==============================================================================

//triggers ↓
reg tri_load, tri_STI, tri_buffer, tri_pix, busy_STI, tri_pix_reg, tri_finish;
reg pi_msb_reg, pi_low_reg, pi_fill_reg;
reg [15:0] data_saved;
reg [1:0] pi_length_reg;
reg [31:0] buffer;
reg [5:0] counter;
reg [2:0] pix_count;
reg [7:0] pix_reg [1:0];

wire [31:0] rvs_buffer;
wire judge;
wire [31:0] bits;
genvar i;
assign rvs_buffer[i] = buffer[31-i];
assign bits = 8*(1+pi_length_reg)-1;
assign judge = (counter == bits)? 1:0;


// loaddata, use trigger: tri_load, tri_STI
always@(posedge clk or posedge reset) begin
	if(reset) begin
		tri_load <= 0;
		pi_length_reg <= 0;
	end
	else begin
		if(load) begin
			tri_load <= 1;
			data_saved <= pi_data;
			pi_msb_reg <= pi_msb;
			pi_length_reg <= pi_length;
			pi_fill_reg <= pi_fill;
			pi_low_reg <= pi_low;
		end
		else tri_load <= (busy_STI && tri_STI)? 0 : tri_load ;
	end
end
// buffer level, tri:busy_STI, tri_buffer, tri_load
always@(posedge clk or posedge reset) begin
	if(reset) begin
		tri_buffer <= 0;
	end
	else begin
		if (tri_load && !busy_STI) begin
			case(pi_length_reg)
				2'd0: begin
					buffer <= {24'b0, ((pi_low_reg) ? data_saved[15:8] : data_saved[7:0])};
					tri_buffer <= 1;
				end
				2'd1: begin
					buffer <= {16'b0, data_saved};
					tri_buffer <= 1;
				end
				2'd2: begin
					buffer <= {8'b0, ((pi_fill_reg) ? {data_saved[15:0], 8'b0} : {8'b0, data_saved[15:0]})};
					tri_buffer <= 1;
				end
				default: begin
					buffer <= (pi_fill_reg) ? {data_saved[15:0], 16'b0} : {16'b0, data_saved[15:0]};
					tri_buffer <= 1;
				end
			endcase
		end
		else begin
			tri_buffer <= (judge && tri_load)? 0 : tri_buffer;
		end
	end
end
// output level, tri=tri_buffer, tri_STI, busy_STI
always@(posedge clk or posedge reset) begin
	if(reset) begin
		tri_STI <= 0;
		counter <= 0;
		busy_STI<= 0;
		so_data <= 0;
		pix_count <= 0;
		tri_pix_reg <= 0;
		tri_pix <= 0;
	end
	else begin
		if(tri_buffer && tri_load) begin
			tri_STI <= (judge) ? 1 : 0;
			busy_STI <= 1;
			so_valid <= 1;
			counter <= (counter == bits ) ? 0 : counter+1;
			so_data <= (!pi_msb_reg) ? buffer[counter] : rvs_buffer[8*(3-pi_length_reg)+counter];
			// pixel steal singal ↓
			tri_pix_reg <= (pix_count == 7 ) ? ~tri_pix_reg : tri_pix_reg;
			pix_count <= (pix_count == 7 ) ? 0 : pix_count+1;
			pix_reg[tri_pix_reg][7-pix_count] <= (!pi_msb_reg) ? buffer[counter] : rvs_buffer[8*(3-pi_length_reg)+counter];
			tri_pix <= (pix_count == 7 ) ? 1:0;
		end
		else begin
			tri_STI <= (judge) ? 1 : 0;
			busy_STI <= 0;
			counter <= 0;
			so_valid <= 0;
			tri_pix <= (pix_count == 7 ) ? 1:0;
		end
	end
end
//pixel level tri: tri_buffer
always@(posedge clk or posedge reset) begin
	if(reset) begin
		pixel_finish <= 0;
		pixel_addr <= 0;
		pixel_finish <= 0;
		pixel_wr <= 0;
		pixel_dataout <= 0;
		tri_finish <= 0;
	end
	else begin
		if(tri_pix) begin
			pixel_dataout <= pix_reg[~tri_pix_reg];
			pixel_wr <= 1;
			pixel_finish <= (pixel_addr == 255)? 1 : 0;
			tri_finish <= (pi_end && tri_STI)? 1 : 0;
		end
		else if(tri_finish) begin
			pixel_wr <= (pixel_finish)? 0:~pixel_wr;
			pixel_dataout <= 0;
			pixel_addr <= (pixel_wr)? pixel_addr:pixel_addr + 1;
			pixel_finish <= (pixel_addr == 255)? 1 : 0;
		end
		else begin
			pixel_wr <= 0;
			pixel_addr <= (pixel_wr)? pixel_addr + 1 : pixel_addr;
		end
	end
end

endmodule
