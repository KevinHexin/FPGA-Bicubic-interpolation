module mul_4(
	input clk,
	input rst_n,
	input [9:0] a,b,c,d,
	output [39:0] result
);

reg [19:0] result0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result0<=20'd0;
	end
	else begin
		result0<=a*b;
	end
end

reg [19:0] result1;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result1<=20'd0;
	end
	else begin
		result1<=c*d;
	end
end

reg [19:0] result2;
reg [19:0] result3;
//寄存延时
always@(posedge clk)
begin
	result2<=result0;
	result3<=result1;
end

reg [39:0] result4;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result4<=40'd0;
	end
	else begin
		result4<=result2*result3;
	end
end

reg [39:0] result5;
//寄存延时
always@(posedge clk)
begin
	result5<=result4;
end

assign result = result5;

endmodule