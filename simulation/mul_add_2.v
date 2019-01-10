module mul_add_2(
	input        clk,
	input        rst_n,
	input [39:0] a,
	input [37:0] b,
	input [27:0] c,
	input [17:0] d,
	input [8:0]  coeffHalf,
	output [8:0] result
);

reg [45:0] result0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result0<=46'd0;
	end
	else begin
		result0<=a+(c<<16);
	end
end

reg [45:0] result1;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result1<=46'd0;
	end
	else begin
		result1<=(b<<8)+(d<<24);
	end
end

reg [45:0] result2;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result2<=46'd0;
	end
	else begin
		result2<=(result0 >= result1) ? (result0 - result1) : 46'd0;
	end
end

reg [45:0] result3;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result3 <= 0;
	end
	else begin
		result3 <= result2 /* + ((coeffHalf<<16)-1) */;
	end
end

reg [45:0] result4;
//寄存延时
always@(posedge clk)
begin
	result4 <= result3;
end

reg [8:0] result5;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result5 <= 0;
	end
	else begin
		result5 <= (result4 >> 24)&({ {37{1'b0}}, {9{1'b1}} });
	end
end

reg [8:0] result6,result7,result8,result9;
//寄存延时
always@(posedge clk)
begin
	result6 <= result5;
	result7 <= result6;
	result8 <= result7;
	result9 <= result8;
end

assign result = result9;
endmodule