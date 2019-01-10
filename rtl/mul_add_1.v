module mul_add_1(
	input        clk,
	input        rst_n,
	input [39:0] a,
	input [37:0] b,
	input        c,
	input [8:0]  coeffHalf,
	output[8:0]  result
);

reg [45:0] result0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result0<=46'd0;
	end
	else begin
		result0<=a+(c<<32);
	end
end

reg [45:0] b_reg;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		b_reg <= 46'd0;
	end
	else begin
		b_reg <= b << 8;
	end
end

reg [45:0] result1;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result1<=46'd0;
	end
	else begin
		result1<=(result0 >= b_reg) ? (result0 - b_reg) : 46'd0;
	end
end

reg [45:0] result2;
//寄存延时
always@(posedge clk)
begin
	result2 <= result1;
end

reg [45:0] result3;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result3 <= 0;
	end
	else begin
		result3 <= result2 + ((coeffHalf << 16) - 1);
	end
end

reg [8:0] result4;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result4 <= 9'd0;
	end
	else begin
		result4 <= (result3>>24)&({ {37{1'b0}}, {9{1'b1}} });
	end
end

reg [8:0] result5,result6;
//寄存延时
always@(posedge clk)
begin
	result5 <= result4;
	result6 <= result5;
end

assign result = result6;
endmodule