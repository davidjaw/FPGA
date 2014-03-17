module comparator(a, b, out_a, out_b);
	input  [63:0] a, b;
	output [63:0]    out_a, out_b;

	assign out_a = (a>b) ? a : b;
	assign out_b = (a>b) ? b : a;

endmodule
