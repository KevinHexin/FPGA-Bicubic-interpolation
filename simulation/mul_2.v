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

reg [27:0] result1;
//加一级延迟
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result1<=28'd0;
	end
	else begin
		result1<=result0;
	end
end

assign result = result1;

endmodule