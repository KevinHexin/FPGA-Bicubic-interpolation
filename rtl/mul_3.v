module mul_3(
	input clk,
	input rst_n,
	input [17:0] a,
	input [9:0] b,c,
	output [37:0] result
);

reg [19:0] result0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result0<=20'd0;
	end
	else begin
		result0<=c*b;
	end
end

reg [17:0] a_reg;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		a_reg<=18'd0;
	end
	else begin
		a_reg<=a;
	end
end

reg [19:0] result1;
reg [17:0] a_reg0;
//寄存延时
always@(posedge clk)
begin
	result1<=result0;
	a_reg0<=a_reg;
end

reg [37:0] result2;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result2<=38'd0;
	end
	else begin
		result2<=result1*a_reg0;
	end
end

reg [37:0] result3;
//寄存延时
always@(posedge clk)
begin
	result3<=result2;
end

assign result = result3;

endmodule