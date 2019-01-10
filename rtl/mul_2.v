module mul_2(
	input          clk,
	input          rst_n,
	input  [9:0]   a,
	input  [17:0]  b,
	output [27:0]  result
);

reg [27:0] result0;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result0<=28'd0;
	end
	else begin
		result0<=a*b;
	end
end

reg [27:0] result1,result2,result3;
//寄存延时
always@(posedge clk)
begin
	result1<=result0;
	result2<=result1;
	result3<=result2;
end

assign result = result3;

endmodule