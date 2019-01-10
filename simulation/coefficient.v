module coefficient #(
	parameter FRACTION_BITS = 8,
	parameter COEFF_WIDTH   = 9
)(
	input               clk,    
	input               rst_n,
	input      [8:0]    coeffHalf,
	input      [8:0]    bi_y0,bi_y1,bi_y2,bi_y3,bi_x0,bi_x1,bi_x2,bi_x3,  
	output reg [8:0]    coeff00,coeff01,coeff02,coeff03,
	output reg [8:0]    coeff10,coeff11,coeff12,coeff13,
	output reg [8:0]    coeff20,coeff21,coeff22,coeff23,
	output reg [8:0]    coeff30,coeff31,coeff32,coeff33
);

reg [8:0]  bi_y0_reg,bi_y1_reg,bi_y2_reg,bi_y3_reg,bi_x0_reg,bi_x1_reg,bi_x2_reg,bi_x3_reg; 
reg [8:0]  bi_y0_reg0,bi_y1_reg0,bi_y2_reg0,bi_y3_reg0,bi_x0_reg0,bi_x1_reg0,bi_x2_reg0,bi_x3_reg0;
(* keep = "true" *)reg [8:0]  bi_y0_reg_dump0,bi_y1_reg_dump0,bi_y2_reg_dump0,bi_y3_reg_dump0,bi_x0_reg_dump0,bi_x1_reg_dump0,bi_x2_reg_dump0,bi_x3_reg_dump0;
(* keep = "true" *)reg [8:0]  bi_y0_reg_dump1,bi_y1_reg_dump1,bi_y2_reg_dump1,bi_y3_reg_dump1,bi_x0_reg_dump1,bi_x1_reg_dump1,bi_x2_reg_dump1,bi_x3_reg_dump1;
(* keep = "true" *)reg [8:0]  bi_y0_reg_dump2,bi_y1_reg_dump2,bi_y2_reg_dump2,bi_y3_reg_dump2,bi_x0_reg_dump2,bi_x1_reg_dump2,bi_x2_reg_dump2,bi_x3_reg_dump2;
(* keep = "true" *)reg [8:0]  bi_y0_reg_dump3,bi_y1_reg_dump3,bi_y2_reg_dump3,bi_y3_reg_dump3,bi_x0_reg_dump3,bi_x1_reg_dump3,bi_x2_reg_dump3,bi_x3_reg_dump3;
always@(posedge clk)
begin
	bi_y0_reg <= bi_y0;
	bi_y1_reg <= bi_y1;
	bi_y2_reg <= bi_y2;
	bi_y3_reg <= bi_y3;
	bi_x0_reg <= bi_x0;
	bi_x1_reg <= bi_x1;
	bi_x2_reg <= bi_x2;
	bi_x3_reg <= bi_x3;
	
	bi_y0_reg0 <= bi_y0_reg;
	bi_y1_reg0 <= bi_y1_reg;
	bi_y2_reg0 <= bi_y2_reg;
	bi_y3_reg0 <= bi_y3_reg;
	bi_x0_reg0 <= bi_x0_reg;
	bi_x1_reg0 <= bi_x1_reg;
	bi_x2_reg0 <= bi_x2_reg;
	bi_x3_reg0 <= bi_x3_reg;
	
	bi_y0_reg_dump0 <= bi_y0_reg0;
	bi_y1_reg_dump0 <= bi_y1_reg0;
	bi_y2_reg_dump0 <= bi_y2_reg0;
	bi_y3_reg_dump0 <= bi_y3_reg0;
	bi_x0_reg_dump0 <= bi_x0_reg0;
	bi_x1_reg_dump0 <= bi_x1_reg0;
	bi_x2_reg_dump0 <= bi_x2_reg0;
	bi_x3_reg_dump0 <= bi_x3_reg0;
	
	bi_y0_reg_dump1 <= bi_y0_reg0;
	bi_y1_reg_dump1 <= bi_y1_reg0;
	bi_y2_reg_dump1 <= bi_y2_reg0;
	bi_y3_reg_dump1 <= bi_y3_reg0;
	bi_x0_reg_dump1 <= bi_x0_reg0;
	bi_x1_reg_dump1 <= bi_x1_reg0;
	bi_x2_reg_dump1 <= bi_x2_reg0;
	bi_x3_reg_dump1 <= bi_x3_reg0;
	
	bi_y0_reg_dump2 <= bi_y0_reg0;
	bi_y1_reg_dump2 <= bi_y1_reg0;
	bi_y2_reg_dump2 <= bi_y2_reg0;
	bi_y3_reg_dump2 <= bi_y3_reg0;
	bi_x0_reg_dump2 <= bi_x0_reg0;
	bi_x1_reg_dump2 <= bi_x1_reg0;
	bi_x2_reg_dump2 <= bi_x2_reg0;
	bi_x3_reg_dump2 <= bi_x3_reg0;
	
	bi_y0_reg_dump3 <= bi_y0_reg0;
	bi_y1_reg_dump3 <= bi_y1_reg0;
	bi_y2_reg_dump3 <= bi_y2_reg0;
	bi_y3_reg_dump3 <= bi_y3_reg0;
	bi_x0_reg_dump3 <= bi_x0_reg0;
	bi_x1_reg_dump3 <= bi_x1_reg0;
	bi_x2_reg_dump3 <= bi_x2_reg0;
	bi_x3_reg_dump3 <= bi_x3_reg0;
end

reg [17:0] coeff00_mul,coeff01_mul,coeff02_mul,coeff03_mul;
reg [17:0] coeff10_mul,coeff11_mul,coeff12_mul,coeff13_mul;
reg [17:0] coeff20_mul,coeff21_mul,coeff22_mul,coeff23_mul;
reg [17:0] coeff30_mul,coeff31_mul,coeff32_mul,coeff33_mul;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		coeff00_mul <= 0;
		coeff01_mul <= 0;
		coeff02_mul <= 0;
		coeff03_mul <= 0;
		coeff10_mul <= 0;
		coeff11_mul <= 0;
		coeff12_mul <= 0;
		coeff13_mul <= 0;
		coeff20_mul <= 0;
		coeff21_mul <= 0;
		coeff22_mul <= 0;
		coeff23_mul <= 0;
		coeff30_mul <= 0;
		coeff31_mul <= 0;
		coeff32_mul <= 0;
		coeff33_mul <= 0;
	end
	else
	begin
		coeff00_mul <= bi_x0_reg_dump0*bi_y0_reg_dump0;
		coeff01_mul <= bi_x1_reg_dump0*bi_y0_reg_dump1;
		coeff02_mul <= bi_x2_reg_dump0*bi_y0_reg_dump2;
		coeff03_mul <= bi_x3_reg_dump0*bi_y0_reg_dump3;
		//                 
		coeff10_mul <= bi_x0_reg_dump1*bi_y1_reg_dump0;
		coeff11_mul <= bi_x1_reg_dump1*bi_y1_reg_dump1;
		coeff12_mul <= bi_x2_reg_dump1*bi_y1_reg_dump2;
		coeff13_mul <= bi_x3_reg_dump1*bi_y1_reg_dump3;
		//                
		coeff20_mul <= bi_x0_reg_dump2*bi_y2_reg_dump0;
		coeff21_mul <= bi_x1_reg_dump2*bi_y2_reg_dump1;
		coeff22_mul <= bi_x2_reg_dump2*bi_y2_reg_dump2;
		coeff23_mul <= bi_x3_reg_dump2*bi_y2_reg_dump3;
		//                 
		coeff30_mul <= bi_x0_reg_dump3*bi_y3_reg_dump0;
		coeff31_mul <= bi_x1_reg_dump3*bi_y3_reg_dump1;
		coeff32_mul <= bi_x2_reg_dump3*bi_y3_reg_dump2;
		coeff33_mul <= bi_x3_reg_dump3*bi_y3_reg_dump3;
	end
end

reg [18:0] coeff00_add,coeff01_add,coeff02_add,coeff03_add;
reg [18:0] coeff10_add,coeff11_add,coeff12_add,coeff13_add;
reg [18:0] coeff20_add,coeff21_add,coeff22_add,coeff23_add;
reg [18:0] coeff30_add,coeff31_add,coeff32_add,coeff33_add;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		coeff00_add <= 0;
		coeff01_add <= 0;
		coeff02_add <= 0;
		coeff03_add <= 0;
		coeff10_add <= 0;
		coeff11_add <= 0;
		coeff12_add <= 0;
		coeff13_add <= 0;
		coeff20_add <= 0;
		coeff21_add <= 0;
		coeff22_add <= 0;
		coeff23_add <= 0;
		coeff30_add <= 0;
		coeff31_add <= 0;
		coeff32_add <= 0;
		coeff33_add <= 0;
	end
	else
	begin
		/* coeff00_add <= coeff00_mul + (coeffHalf - 1);
		coeff01_add <= coeff01_mul + (coeffHalf - 1);
		coeff02_add <= coeff02_mul + (coeffHalf - 1);
		coeff03_add <= coeff03_mul + (coeffHalf - 1);
		//             
		coeff10_add <= coeff10_mul + (coeffHalf - 1);
		coeff11_add <= coeff11_mul + (coeffHalf - 1);
		coeff12_add <= coeff12_mul + (coeffHalf - 1);
		coeff13_add <= coeff13_mul + (coeffHalf - 1);
		//             
		coeff20_add <= coeff20_mul + (coeffHalf - 1);
		coeff21_add <= coeff21_mul + (coeffHalf - 1);
		coeff22_add <= coeff22_mul + (coeffHalf - 1);
		coeff23_add <= coeff23_mul + (coeffHalf - 1);
		//             
		coeff30_add <= coeff30_mul + (coeffHalf - 1);
		coeff31_add <= coeff31_mul + (coeffHalf - 1);
		coeff32_add <= coeff32_mul + (coeffHalf - 1);
		coeff33_add <= coeff33_mul + (coeffHalf - 1); */
		
		coeff00_add <= coeff00_mul;
		coeff01_add <= coeff01_mul;
		coeff02_add <= coeff02_mul;
		coeff03_add <= coeff03_mul;
		//             
		coeff10_add <= coeff10_mul;
		coeff11_add <= coeff11_mul;
		coeff12_add <= coeff12_mul;
		coeff13_add <= coeff13_mul;
		//             
		coeff20_add <= coeff20_mul;
		coeff21_add <= coeff21_mul;
		coeff22_add <= coeff22_mul;
		coeff23_add <= coeff23_mul;
		//             
		coeff30_add <= coeff30_mul;
		coeff31_add <= coeff31_mul;
		coeff32_add <= coeff32_mul;
		coeff33_add <= coeff33_mul;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		coeff00 <= 0;
		coeff01 <= 0;
		coeff02 <= 0;
		coeff03 <= 0;
		coeff10 <= 0;
		coeff11 <= 0;
		coeff12 <= 0;
		coeff13 <= 0;
		coeff20 <= 0;
		coeff21 <= 0;
		coeff22 <= 0;
		coeff23 <= 0;
		coeff30 <= 0;
		coeff31 <= 0;
		coeff32 <= 0;
		coeff33 <= 0;
	end
	else
	begin
		coeff00 <= (coeff00_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff01 <= (coeff01_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff02 <= (coeff02_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff03 <= (coeff03_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		//                 
		coeff10 <= (coeff10_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff11 <= (coeff11_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff12 <= (coeff12_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff13 <= (coeff13_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		//                  
		coeff20 <= (coeff20_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff21 <= (coeff21_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff22 <= (coeff22_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff23 <= (coeff23_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		//                 
		coeff30 <= (coeff30_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff31 <= (coeff31_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff32 <= (coeff32_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
		coeff33 <= (coeff33_add>>FRACTION_BITS) & {{COEFF_WIDTH{1'b0}}, {COEFF_WIDTH{1'b1}}};
	end
end

endmodule