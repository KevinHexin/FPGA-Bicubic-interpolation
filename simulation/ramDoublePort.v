/*
	4个双口缓存ram
	4个ram最多缓存512*4=2048个24bit像素数据
*/
module ramDoublePort #(
	parameter DATA_WIDTH = 24,
	parameter ADDRESS_WIDTH = 11
)(
	input wire [(DATA_WIDTH-1):0] data_in,
	input wire [(ADDRESS_WIDTH-1):0] addrA_in, addrB_in, addrC_in, addrD_in,
	input wire we_in,clk,
	output reg [(DATA_WIDTH-1):0] qA, qB, qC, qD
);

	reg [(DATA_WIDTH-1):0] data;
	reg [(ADDRESS_WIDTH-1):0] addrA, addrB, addrC, addrD;
	reg we;
	always@(posedge clk)
	begin
		we <= we_in;
		data <= data_in;
		addrA <= addrA_in;
		addrB <= addrB_in;
		addrC <= addrC_in;
		addrD <= addrD_in;
	end

	reg	[8:0]  address_00,address_01,address_10,address_11;
	reg	       wren00,wren01,wren10,wren11;
	reg  [(DATA_WIDTH-1):0] data_reg;
	wire [(DATA_WIDTH-1):0] q00,q01,q10,q11;
	
	//depth 512  width 24bit
	ram_00 ram_00_inst(
		.address       (address_00),
		.clock     (clk),
		.data       (data_reg),
		.wren      (wren00),
		.q    (q00)
	);
	ram_00 ram_01_inst(
		.address       (address_01),
		.clock     (clk),
		.data       (data_reg),
		.wren      (wren01),
		.q    (q01)
	);
	ram_00 ram_10_inst(
		.address       (address_10),
		.clock     (clk),
		.data       (data_reg),
		.wren      (wren10),
		.q    (q10)
	);
	ram_00 ram_11_inst(
		.address       (address_11),
		.clock     (clk),
		.data       (data_reg),
		.wren      (wren11),
		.q    (q11)
	);
	
reg q00_flag,q01_flag,q10_flag,q11_flag;
always @ (posedge clk)
begin
	//写 根据addrB[1:0]的不同轮流缓存到4个ram中(交替缓存像素点)
	if (we)
	begin
		case (addrB[1:0])
			2'b00:begin
				wren00 <= we;
				wren01 <= 0;
				wren10 <= 0;
				wren11 <= 0;
			end
			2'b01:begin
				wren01 <= we;
				wren00 <= 0;
				wren10 <= 0;
				wren11 <= 0;
			end
			2'b10:begin
				wren10 <= we;
				wren00 <= 0;
				wren01 <= 0;
				wren11 <= 0;
			end
			2'b11:begin
				wren11 <= we;
				wren00 <= 0;
				wren01 <= 0;
				wren10 <= 0;
			end
		endcase
		data_reg   <= data;
		address_00 <= addrB[10:2];
		address_01 <= addrB[10:2];
		address_10 <= addrB[10:2];
		address_11 <= addrB[10:2];
	end
	//读 一次读出4个24bit像素数据
	else
	begin
		case (addrB[1:0])
			2'b00:begin
				q00_flag <= 1'b1;
				q01_flag <= 1'b0;
				q10_flag <= 1'b0;
				q11_flag <= 1'b0;
				address_00 <= addrB[10:2];
				address_01 <= addrC[10:2];
				address_10 <= addrD[10:2];
				address_11 <= addrA[10:2];
			end
			2'b01:begin
				q00_flag <= 1'b0;
				q01_flag <= 1'b1;
				q10_flag <= 1'b0;
				q11_flag <= 1'b0;
				address_00 <= addrA[10:2];
				address_01 <= addrB[10:2];
				address_10 <= addrC[10:2];
				address_11 <= addrD[10:2];
			end
			2'b10:begin
				q00_flag <= 1'b0;
				q01_flag <= 1'b0;
				q10_flag <= 1'b1;
				q11_flag <= 1'b0;
				address_00 <= addrD[10:2];
				address_01 <= addrA[10:2];
				address_10 <= addrB[10:2];
				address_11 <= addrC[10:2];
			end
			2'b11:begin
				q00_flag <= 1'b0;
				q01_flag <= 1'b0;
				q10_flag <= 1'b0;
				q11_flag <= 1'b1;
				address_00 <= addrC[10:2];
				address_01 <= addrD[10:2];
				address_10 <= addrA[10:2];
				address_11 <= addrB[10:2];
			end
		endcase
		wren00 <= 0;
		wren01 <= 0;
		wren10 <= 0;
		wren11 <= 0;
	end
end

reg q00_flag_r,q01_flag_r,q10_flag_r,q11_flag_r;
reg q00_flag_d,q01_flag_d,q10_flag_d,q11_flag_d;
//2级延时
always@(posedge clk)
begin
	q00_flag_r <= q00_flag;
	q01_flag_r <= q01_flag;
	q10_flag_r <= q10_flag;
	q11_flag_r <= q11_flag;
	
	q00_flag_d <= q00_flag_r;
	q01_flag_d <= q01_flag_r;
	q10_flag_d <= q10_flag_r;
	q11_flag_d <= q11_flag_r;
end

reg [(DATA_WIDTH-1):0] qA_0,qB_0,qC_0,qD_0;
always@(posedge clk)
begin
	if(q00_flag_d) begin
		qA_0 <= q11;
		qB_0 <= q00;
		qC_0 <= q01;
		qD_0 <= q10;
	end
	if(q01_flag_d) begin
		qA_0 <= q00;
		qB_0 <= q01;
		qC_0 <= q10;
		qD_0 <= q11;
	end
	if(q10_flag_d) begin
		qA_0 <= q01;
		qB_0 <= q10;
		qC_0 <= q11;
		qD_0 <= q00;
	end
	if(q11_flag_d) begin
		qA_0 <= q10;
		qB_0 <= q11;
		qC_0 <= q00;
		qD_0 <= q01;
	end
end

//寄存延时
always@(posedge clk)
begin
	qA <= qA_0;
	qB <= qB_0;
	qC <= qC_0;
	qD <= qD_0;
end

endmodule