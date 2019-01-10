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

reg [39:0] result2;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result2<=40'd0;
	end
	else begin
		result2<=result0*result1;
	end
end

assign result = result2;

endmodule