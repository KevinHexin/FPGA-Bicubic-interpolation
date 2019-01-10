/*
	缩放后像素数据写入DDR缓存模块处理
*/

module scaler_to_ddr(
	input             clk,
	input             rst_n,
	input             dOutValid,           //缩放后的像素数据有效信号
	input             start,               //缩放模块复位信号，一帧复位一次
	input             interlace_flag,      //开启隔行
	input      [23:0] postRGB,             //缩放后的像素数据
	
	input      [10:0] inpix_x,             //写入到DDR的视频流一行的像素点数目
	input      [11:0] VGA_HV_In,
	input      [11:0] VGA_VV_In,
	input      [11:0] VGA_HV_Out,
	input      [11:0] VGA_VV_Out,

	output reg [10:0] DDR_WrRow_Start,     //ddr写入行起始地址
	output reg [10:0] DDR_WrCol_Start,     //ddr写入列起始地址
	output reg        ddr_buf0_wrreq_reg,  //双缓存 FIFO0 写请求
	output reg        ddr_buf1_wrreq_reg,  //双缓存 FIFO1 写请求
	output reg [23:0] source_dat_reg       //写ddr数据
);

always@(*)
begin
	if(VGA_VV_Out >= VGA_VV_In)
		DDR_WrRow_Start = (VGA_VV_Out - VGA_VV_In) >> 1;
	else 
		DDR_WrRow_Start = 0;
end
always@(*)
begin
	if(VGA_HV_Out >= VGA_HV_In)
		DDR_WrCol_Start = (VGA_HV_Out - VGA_HV_In) >> 1;
	else 
		DDR_WrCol_Start = 0;
end

//-------------------------------------------------------------
// 保证写入DDR写缓存FIFO的数据能够被8整除
// 当inpix_x能被8整除时,inpix_x_pixed = inpix_x
// 当inpix_x不能被8整除时,inpix_x_pixed = inpix_x + (8 - inpix_x[2:0])
//-------------------------------------------------------------
reg [10:0] inpix_x_reg;
always@(posedge clk)
begin
	inpix_x_reg <= 8 - inpix_x[2:0];
end

reg [10:0] inpix_x_fixed;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		inpix_x_fixed <= 11'd0;
	end
	else if(inpix_x[2:0] == 3'b000) begin
		inpix_x_fixed <= inpix_x;
	end
	else begin
		inpix_x_fixed <= inpix_x + inpix_x_reg;
	end
end

reg [23:0] postRGB_reg;
always@(posedge clk)
begin
	postRGB_reg <= postRGB;
end

reg dOutValid_fixed;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		dOutValid_fixed <= 1'd0;
	end
	else if(RGB_cnt == inpix_x_fixed - 1) begin
		dOutValid_fixed <= 1'd0;
	end
	else if(dOutValid) begin
		dOutValid_fixed <= 1'd1;
	end
end

//-------------------------------------------------------------
// 双缓存FIFO乒乓写切换
//-------------------------------------------------------------
reg [10:0] RGB_cnt;
reg dOutValid_flag;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		RGB_cnt <= 11'd0;
		dOutValid_flag <=1'd0;
	end
	else if(start) begin
		RGB_cnt <= 11'd0;
		dOutValid_flag <=1'd0;
	end
	else if(RGB_cnt == inpix_x_fixed) begin
		RGB_cnt <= 11'd0;
		dOutValid_flag <= ~dOutValid_flag;
	end
	else if(dOutValid_fixed) begin
		RGB_cnt <= RGB_cnt+11'd1;
	end
end

reg ddr_buf0_wrreq,ddr_buf1_wrreq;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		ddr_buf0_wrreq <=1'd0;
		ddr_buf1_wrreq <=1'd0;
	end
	else if(start) begin
		ddr_buf0_wrreq <=1'd0;
		ddr_buf1_wrreq <=1'd0;
	end
	else if(RGB_cnt == inpix_x_fixed) begin
		ddr_buf0_wrreq <=1'd0;
		ddr_buf1_wrreq <=1'd0;
	end
	else if(dOutValid_fixed) begin
		if(!dOutValid_flag) begin
			ddr_buf0_wrreq <=1'd1 | interlace_flag;
			ddr_buf1_wrreq <=1'd0 | interlace_flag;
		end
		else begin
			ddr_buf0_wrreq <=1'd0 | interlace_flag;
			ddr_buf1_wrreq <=1'd1 | interlace_flag;
		end
	end
	else begin
		ddr_buf0_wrreq <=1'd0;
		ddr_buf1_wrreq <=1'd0;
	end
end

reg [23:0] source_dat_reg_0,source_dat;
reg        ddr_buf0_wrreq_reg_0,ddr_buf1_wrreq_reg_0;
//pipeline
always@(posedge clk)
begin
	source_dat <= postRGB_reg;

	source_dat_reg_0 <= source_dat;
	ddr_buf0_wrreq_reg_0 <= ddr_buf0_wrreq;
	ddr_buf1_wrreq_reg_0 <= ddr_buf1_wrreq;

	source_dat_reg <= source_dat_reg_0;
	ddr_buf0_wrreq_reg <= ddr_buf0_wrreq_reg_0;
	ddr_buf1_wrreq_reg <= ddr_buf1_wrreq_reg_0;
end

(* KEEP = "TRUE" *)reg [10:0] pix_cnt;
	always@(posedge clk)
	begin
		if(!rst_n) begin
			pix_cnt <= 0;
		end
		else if(dOutValid) begin
			pix_cnt <= pix_cnt + 1;
		end
		else begin
			pix_cnt <= 0;
		end
	end

/* ila_0 ila_0_inst (
		.clk(clk), // input wire clk

		.probe0(6'd0), // input wire [5:0]  probe0  
		.probe1(dOutValid), // input wire [0:0]  probe1 
		.probe2(dOutValid_fixed), // input wire [0:0]  probe2 
		.probe3(start), // input wire [0:0]  probe3 
		.probe4({pix_cnt,inpix_x_fixed,ddr_buf0_wrreq,ddr_buf1_wrreq}), // input wire [23:0]  probe4 
		.probe5(1'd0), // input wire [0:0]  probe5 
		.probe6(8'd0), // input wire [7:0]  probe6
		.probe7(8'd0), // input wire [7:0]  probe7 
		.probe8(8'd0), // input wire [7:0]  probe8
		.probe9(8'd0), // input wire [7:0]  probe9
		.probe10({RGB_cnt,13'd0}) // input wire [23:0]  probe10
	); */

//reg [23:0] ram [outpix_x-1:0];

/* always@(posedge clk or negedge rst_n)
begin
	if(rst_n) begin
	
	end
	else if(RGB_cnt == outpix_x) begin
		RGB_cnt <= 11'd0;
		dOutValid_flag <= ~dOutValid_flag;
		ddr_buf0_wrreq <=1'd0;
		ddr_buf1_wrreq <=1'd0;
	end
end */

/* wire [23:0] q_RGB = (dOutValid)?ram[RGB_cnt]:24'd0;
always@(posedge clk)
begin
	if(dOutValid) begin
		ram[RGB_cnt] <= postRGB;
	end
end */

endmodule