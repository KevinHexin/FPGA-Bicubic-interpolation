module BiCubic(
	input         clk,
	input         rst_n,
	input  [8:0]  coeffOne,
	input  [8:0]  coeffHalf,
	input  [8:0]  yBlend,bi_a,xBlend,
	output [8:0]  bi_y0,bi_y1,bi_y2,bi_y3,bi_x0,bi_x1,bi_x2,bi_x3
);

BiCubic_y3 BiCubic_y3_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.yBlend    (yBlend),
	.bi_a      (bi_a),
	.bi_y3     (bi_y3)
);

BiCubic_y2 BiCubic_y2_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.yBlend    (yBlend),
	.bi_a      (bi_a),
	.bi_y2     (bi_y2)
);

BiCubic_y1 BiCubic_y1_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffHalf (coeffHalf),
	.yBlend    (yBlend),
	.bi_a      (bi_a),
	.bi_y1     (bi_y1)
);

BiCubic_y0 BiCubic_y0_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.yBlend    (yBlend),
	.bi_a      (bi_a),
	.bi_y0     (bi_y0)
);

///////////////////////////////////////////////

BiCubic_x3 BiCubic_x3_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.xBlend    (xBlend),
	.bi_a      (bi_a),
	.bi_x3     (bi_x3)
);

BiCubic_x2 BiCubic_x2_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.xBlend    (xBlend),
	.bi_a      (bi_a),
	.bi_x2     (bi_x2)
);

BiCubic_x1 BiCubic_x1_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffHalf (coeffHalf),
	.xBlend    (xBlend),
	.bi_a      (bi_a),
	.bi_x1     (bi_x1)
);

BiCubic_x0 BiCubic_x0_inst(
	.clk       (clk),
	.rst_n     (rst_n),
	.coeffOne  (coeffOne),
	.coeffHalf (coeffHalf),
	.xBlend    (xBlend),
	.bi_a      (bi_a),
	.bi_x0     (bi_x0)
);

endmodule