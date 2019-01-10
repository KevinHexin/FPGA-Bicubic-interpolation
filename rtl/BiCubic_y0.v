module BiCubic_y0 (
	input         clk,
	input         rst_n,
	input  [8:0]  coeffOne,
	input  [8:0]  coeffHalf,
	input  [8:0]  yBlend,bi_a,
	output [8:0]  bi_y0
);

reg [9:0] mul_x,mul_4_a;
reg [17:0] mul_3_a,mul_add_2_d;
reg [17:0] mul_2_a;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		mul_4_a<=10'd0;
		mul_3_a<=18'd0;
		mul_2_a<=18'd0;
		mul_add_2_d<=18'd0;
		
		mul_x<=10'd0;
	end
	else begin
		mul_4_a<={1'd0,bi_a};
		mul_3_a<=9'd5*bi_a;
		mul_2_a<=9'd8*bi_a;
		mul_add_2_d<=9'd4*bi_a;
		
		mul_x<=coeffOne + yBlend;
	end
end

wire [39:0] BiCubic_1_4;
mul_4 mul_4_y0_inst(
	.clk     (clk),
	.rst_n   (rst_n),
	.a       (mul_4_a),
	.b       (mul_x),
	.c       (mul_x),
	.d       (mul_x),
	.result  (BiCubic_1_4)
);

wire [37:0] BiCubic_1_3;
mul_3 mul_3_y0_inst(
	.clk     (clk),
	.rst_n   (rst_n),
	.a       (mul_3_a),
	.b       (mul_x),
	.c       (mul_x),
	.result  (BiCubic_1_3)
);

wire [27:0] BiCubic_1_2;
mul_2 mul_2_y0_inst(
	.clk     (clk),
	.rst_n   (rst_n),
	.a       (mul_x),
	.b       (mul_2_a),
	.result  (BiCubic_1_2)
);

mul_add_2 mul_add_2_y0_inst( 
	.clk        (clk),
	.rst_n      (rst_n),
	.a          (BiCubic_1_4),
	.b          (BiCubic_1_3),
	.c          (BiCubic_1_2),
	.d          (mul_add_2_d),
	.coeffHalf  (coeffHalf),
	.result     (bi_y0)
);

endmodule