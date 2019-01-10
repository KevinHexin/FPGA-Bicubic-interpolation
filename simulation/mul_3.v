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

reg [37:0] result1;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		result1<=38'd0;
	end
	else begin
		result1<=result0*a_reg;
	end
end

assign result = result1;

endmodule