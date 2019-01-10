/*
	原始像素数据跨时钟域处理(AD9888_DCLK >>> SCALER_CLK)
*/

module source_to_scaler(
	input             rst_n,            //系统复位
	input [10:0]      inpix_x,            
	
	output            ddr_wraddr_reset, //DDR写地址复位使能
	input             scaler_enable,    //是否使用缩放功能

    //vga source interface
	input             source_clk,       //AD9888采样时钟
	input             source_en,        //原始像素数据有效(跨时钟域前)
	input             scaler_reset,     //原始视频帧起始信号(边沿检测/复位缩放模块)
	input [23:0]      source_db,        //原始像素数据(跨时钟域前)

	//scaler interface
	input             clk,	            //缩放模块时钟
	input             nextDin,          //缩放模块缓存RAM空满标识,缓存RAM满时将停止写入数据
	input             scaler_done,      //一帧缩放完成标识
	output reg        dInValid,         //输入视频源像素数据有效(跨时钟域后)
	output reg        start,            //缩放模块复位使能
	output reg        nextDout,         //缩放模块缩放使能
	output reg [23:0] preRGB            //输入视频源像素数据(跨时钟域后)
);

	wire [23:0] preRGB_q;
	reg  [10:0] rd_data_cnt;
	wire [10:0] fifo_used;
	reg  [4:0]  fall_t;
	reg         fall_reg;
	reg  [4:0]  rise_t;
	reg         rise_reg;
	reg         dInValid_tmp;
	reg         rw_fifo_rdreq;
	reg         wr_fifo_reset;
	reg  [4:0]  wr_fifo_reset_cnt;

	assign ddr_wraddr_reset = wr_fifo_reset;
	
	//-------------------------------------------------------------
	// 异步复位信号下降沿/上升沿检测
	// 多级寄存器判断可以实现更稳定的边沿检测
	//-------------------------------------------------------------
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)  begin
			fall_t <= 5'd0;
			rise_t <= 5'd0;
		end 
		else begin
			fall_t <= {fall_t[3:0],scaler_reset};
			rise_t <= {rise_t[3:0],scaler_reset};
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)  begin
			fall_reg <= 1'd0;
			rise_reg <= 1'd0;
		end 
		else begin
			if(fall_t[4] & fall_t[3] & (~fall_t[2]) & (~fall_t[1])) begin
				fall_reg <= 1'd1;
			end
			else begin
				fall_reg <= 1'd0;
			end
			if((~rise_t[4]) & (~rise_t[3]) & rise_t[2] & rise_t[1]) begin
				rise_reg <= 1'd1;
			end
			else begin
				rise_reg <= 1'd0;
			end
		end
	end

	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)  begin
			start <= 1'd0;
		end 
		else if(fall_reg | rise_reg) begin
			start <= 1'd1;
		end
		else begin
			start <= 1'd0;
		end
	end
	
	//缩放模块缩放使能
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			nextDout<=1'b1;
		end
		else if(scaler_enable == 1'd0) begin
			nextDout<=1'b0;
		end
		else if(start) begin
			nextDout<=1'b1;
		end
		else if(scaler_done) begin
			nextDout<=1'b0;
		end
	end

	//输出数据有效
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			dInValid_tmp<=1'b0;
		end
		else if(rw_fifo_rdreq) begin
			dInValid_tmp<=1'b1;
		end
		else begin
			dInValid_tmp<=1'b0;
		end
	end

	//寄存延时
	always@(posedge clk)
	begin
		dInValid <= dInValid_tmp;
		preRGB <= preRGB_q;
	end

	reg fifo_rd_con;
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)begin
			fifo_rd_con <= 1'd0;
		end
		else if(scaler_enable) begin
			//如果允许开启缩放功能且nextDin有效
			if(nextDin) begin
				fifo_rd_con <= 1'd1;
			end
			else begin
				fifo_rd_con <= 1'd0;
			end
		end
		//如果不允许开启缩放功能
		else begin
			fifo_rd_con <= 1'd1;
		end
	end
	
	//-------------------------------------------------------------
	// fifo读请求
	//-------------------------------------------------------------
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			rd_data_cnt <= 11'd0;
		end
		else if((wr_fifo_reset) || (rd_data_cnt == inpix_x)) begin
			rd_data_cnt <= 11'd0;
		end
		else if(rd_data_cnt > 11'd0) begin
			rd_data_cnt <= rd_data_cnt+11'd1;
		end
		else if((fifo_used >= inpix_x) && (fifo_rd_con == 1'd1)) begin
			rd_data_cnt <= rd_data_cnt+11'd1;
		end
		else begin
			rd_data_cnt <= 11'd0;
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			rw_fifo_rdreq <= 1'd0;
		end
		else if((wr_fifo_reset) || (rd_data_cnt == inpix_x)) begin
			rw_fifo_rdreq <= 1'd0;
		end
		else if(rd_data_cnt > 11'd0) begin
			rw_fifo_rdreq <= 1'd1;
		end
		else if((fifo_used >= inpix_x) && (fifo_rd_con == 1'd1)) begin
			rw_fifo_rdreq <= 1'd1;
		end
		else begin
			rw_fifo_rdreq <= 1'd0;
		end
	end

	//FIFO复位使能(延长异步复位信号)
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			wr_fifo_reset <= 1'd0;
			wr_fifo_reset_cnt <= 0;
		end
		else if((wr_fifo_reset_cnt <= 5'd20) && (wr_fifo_reset)) begin
			wr_fifo_reset_cnt <= wr_fifo_reset_cnt + 5'd1;
		end
		else if(start) begin
			wr_fifo_reset <= 1'd1;
		end
		else begin
			wr_fifo_reset <= 1'd0;
			wr_fifo_reset_cnt <= 0;
		end
	end

	//24bit|source_clk >>>>>> 24bit|clk
	scaler_rw_fifo scaler_rw_fifo_inst (
		.rst(wr_fifo_reset),             // input wire rst
		.wr_clk(source_clk),             // input wire wr_clk
		.rd_clk(clk),                    // input wire rd_clk
		.din(source_db),                 // input wire [23 : 0] din
		.wr_en(source_en),               // input wire wr_en
		.rd_en(rw_fifo_rdreq),           // input wire rd_en
		.dout(preRGB_q),                 // output wire [23 : 0] dout
		.full(),                         // output wire full
		.empty(),                        // output wire empty
		.rd_data_count(fifo_used),       // output wire [10 : 0] rd_data_count
		.wr_rst_busy(),                  // output wire wr_rst_busy
		.rd_rst_busy()                   // output wire rd_rst_busy
	);
	
endmodule