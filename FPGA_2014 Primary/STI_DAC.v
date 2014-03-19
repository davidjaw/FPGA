module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output reg so_data, so_valid;

output reg pixel_finish, pixel_wr;
output reg signed [9:0] pixel_addr;
output reg [7:0] pixel_dataout;

//==============================================================================

reg [15:0] data_save;
reg [31:0] buffer;
reg [1:0] data_length;
reg [5:0] bits, times_counter;
reg pi_msb_reg;
reg pi_low_reg;
reg pi_fill_reg;
reg w_flag;
reg STI_busy, BUFFER_busy, LOAD_busy, flag, mem_ok, finish;	//inner busy

reg [8:0] counter;			// for STI
reg [8:0] mem_addr_count;


wire [5:0] mem_times;
wire [7:0] men_high, mem_low;
wire [31:0] reverse_buffer;

assign mem_times = (bits >> 3);

// data save
always@(posedge clk or posedge reset) begin
	if(reset) begin
		data_save <= 0;
		data_length <= 0;
		pi_msb_reg <= 0;
		pi_low_reg <= 0;
		pi_fill_reg <= 0;
		LOAD_busy <= 1;
	end
	else begin
		if((!BUFFER_busy) && (load) && (!pi_end)) begin
			// STI not busy
			data_save <= pi_data;
			data_length <= pi_length;
			pi_msb_reg <= pi_msb;
			pi_low_reg <= pi_low;
			pi_fill_reg <= pi_fill;
			LOAD_busy <= 0;
		end
		else begin
			if(flag) LOAD_busy <= 1;
		end
	end
end

// Save buffer
always@(posedge clk or posedge reset) begin
	if(reset) begin
		BUFFER_busy <= 0;
		buffer <= 0;
	end
	else begin
		// load data vaild
		if(!LOAD_busy) begin
			if(!STI_busy) begin
				BUFFER_busy <= 1;
				case(data_length) 
					0: begin	//8 bit out
						buffer <= (pi_low_reg)? data_save[15:8] : data_save[7:0];
						bits <= 8;
					end
					1: begin	//16 bit out
						buffer <= data_save;
						bits <= 16;
					end
					2: begin	//24 bit out
						buffer <= (pi_fill_reg)? {data_save, 8'd0} : {8'd0, data_save};
						bits <= 24;
					end
					3: begin	//32 bit out
						buffer <= (pi_fill_reg)? {data_save, 16'd0} : {16'd0, data_save};
						bits <= 32;
					end
				endcase
				if(flag) BUFFER_busy <= 0;
			 end
			// else begin
				//if ok
			// end
		end
	end
end

// STI 
always@(posedge clk or posedge reset) begin
	if(reset) begin
		counter <= 0;
		so_data <= 0;
		so_valid <= 0;
		STI_busy <= 0;
		flag <= 0;
	end
	else begin

		if(BUFFER_busy && mem_ok) begin
			if(counter != bits && !flag) begin
				counter <= counter + 1;
				so_data <= (!pi_msb_reg)? buffer[counter] : buffer[bits-1-counter];
				so_valid <= 1;
				STI_busy <= 1;
				flag <= 0;
			end
			else begin
				counter <= 0;
				so_valid <= 0;
				STI_busy <= 0;
				flag <= 1;
			end
		end
		else flag <= 0;

	end
end

// DAC ( save to mem )
always@(posedge clk or posedge reset) begin
	if(reset) begin
		mem_ok <= 0;
		finish <= 0;
		mem_addr_count <= 0;
		w_flag <= 0;
		pixel_wr <= 0;
		pixel_addr <= -1;
		pixel_finish <= 0;
		times_counter <= 1;
	end
	else begin
		if((BUFFER_busy && !mem_ok) || (finish && !pixel_finish)) begin
			if(!w_flag) begin
				if(finish) begin
					pixel_dataout <= 0;
					// mem addr
					if(pixel_addr != 255) begin
						pixel_addr <= pixel_addr + 1;
					end
					else begin
						pixel_finish <= 1;
					end
				end
				else begin
					case(times_counter)
						1:pixel_dataout <= (pi_msb_reg)? {buffer[bits-1-0],buffer[bits-1-1],buffer[bits-1-2],buffer[bits-1-3],buffer[bits-1-4],buffer[bits-1-5],buffer[bits-1-6],buffer[bits-1-7]} :{buffer[0],buffer[1],buffer[2],buffer[3],buffer[4],buffer[5],buffer[6],buffer[7]};
						2:pixel_dataout <= (pi_msb_reg)? {buffer[bits-1-8],buffer[bits-1-9],buffer[bits-1-10],buffer[bits-1-11],buffer[bits-1-12],buffer[bits-1-13],buffer[bits-1-14],buffer[bits-1-15]} :{buffer[8],buffer[9],buffer[10],buffer[11],buffer[12],buffer[13],buffer[14],buffer[15]};
						3:pixel_dataout <= (pi_msb_reg)? {buffer[bits-1-16],buffer[bits-1-17],buffer[bits-1-18],buffer[bits-1-19],buffer[bits-1-20],buffer[bits-1-21],buffer[bits-1-22],buffer[bits-1-23]} :{buffer[16],buffer[17],buffer[18],buffer[19],buffer[20],buffer[21],buffer[22],buffer[23]};
						4:pixel_dataout <= (pi_msb_reg)? {buffer[bits-1-24],buffer[bits-1-25],buffer[bits-1-26],buffer[bits-1-27],buffer[bits-1-28],buffer[bits-1-29],buffer[bits-1-30],buffer[bits-1-31]} :{buffer[24],buffer[25],buffer[26],buffer[27],buffer[28],buffer[29],buffer[30],buffer[31]};				
					endcase
					// mem addr
					if(mem_addr_count != bits+1) begin
						pixel_addr <= pixel_addr + 1;
						mem_addr_count <= mem_addr_count + 1;
					end
					else mem_addr_count <= 0;
				end
				w_flag <= 1;
				pixel_wr <= 0;
			end
			else begin
				pixel_wr <= 1;
				w_flag <= 0;
				// mem times
				if(times_counter != mem_times) begin
					times_counter <= times_counter + 1;
				end
				else begin
					times_counter <= 1;	
					mem_ok <= 1;
					if(pi_end) begin 
						finish <= 1;
					end
				end
			end
		end
		else if (flag == 1) mem_ok <= 0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		
	end
	else begin
		
	end
end



endmodule
