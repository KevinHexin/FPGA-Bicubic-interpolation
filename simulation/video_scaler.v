module video_scaler (
//Clock and reset
input wire							  clk,
input wire							  rst,                  //系统复位信号/高有效
input wire							  start,                //本模块复位信号/每帧复位一次/高有效
                                      
//Input                               
input wire [24-1:0]  dIn,                  //输入视频源像素数据
input wire							  dInValid,             //输入视频源像素数据有效
input wire							  dout_Enable,          //缩放使能
                                      
//Output                              
output wire							  din_Enable,           //写入缓存RAM使能
															//缓存RAM满时将停止写入数据
output reg [24-1:0]  dOut,                 //缩放后的像素数据
output reg							  dOutValid,			//缩放后的像素数据有效
output reg                            scaler_done,          //一帧缩放完成标识
                                      
//控制信号                            
input wire [11-1:0]	  inputXRes,			//输入视频流分辨率
input wire [11-1:0]	  inputYRes,
input wire [11-1:0]	  outputXRes,			//输出视频流分辨率
input wire [11-1:0]	  outputYRes,
input wire [18-1:0]			  xScale,				//X轴缩放比例
input wire [18-1:0]			  yScale,				//Y轴缩放比例

//未使用的信号
input wire [8-1:0]	  inputDiscardCnt,	//Number of input pixels to discard 
														//before processing data. Used for clipping
														
input wire [25-1:0]              leftOffset,		//Integer/fraction of input pixel to 
														//offset output data horizontally right.
														//Format Q = OUTPUT_X_RES_WIDTH.SCALE_FRAC_BITS
														
input wire [14-1:0]	  topFracOffset		//Fraction of input pixel to offset
														//data vertically down. Format Q0.SCALE_FRAC_BITS
);
localparam	DATA_WIDTH =			8;		//Width of input/output data
localparam	CHANNELS =				3;		//Number of channels of DATA_WIDTH, for color images
localparam 	DISCARD_CNT_WIDTH =		8;		//Width of inputDiscardCnt
localparam	INPUT_X_RES_WIDTH =		11;		//Widths of input/output resolution control signals
localparam	INPUT_Y_RES_WIDTH =		11;
localparam	OUTPUT_X_RES_WIDTH =	11;
localparam	OUTPUT_Y_RES_WIDTH =	11;
localparam	FRACTION_BITS =			8;		//Number of bits for fractional component of coefficients.

localparam	SCALE_INT_BITS =		4;		//Width of integer component of scaling factor. 
											//The maximum input data width tomultipliers created 
											//will be SCALE_INT_BITS + SCALE_FRAC_BITS. 
											//Typically these values will sum to 18 to match //multipliers available in FPGAs.
localparam	SCALE_FRAC_BITS =		14;		//Width of fractional component of scaling factor
localparam	BUFFER_SIZE =			8;		//Depth of RFIFO
localparam	COEFF_WIDTH =			FRACTION_BITS + 1;
localparam	SCALE_BITS =			SCALE_INT_BITS + SCALE_FRAC_BITS;
localparam  Q_WIDTH = OUTPUT_X_RES_WIDTH + SCALE_FRAC_BITS;
//wide enough to hold value BUFFER_SIZE + 1
localparam	BUFFER_SIZE_WIDTH =		((BUFFER_SIZE+1) <= 2) ? 1 :
									((BUFFER_SIZE+1) <= 4) ? 2 :
									((BUFFER_SIZE+1) <= 8) ? 3 :
									((BUFFER_SIZE+1) <= 16) ? 4 :
									((BUFFER_SIZE+1) <= 32) ? 5 :
									((BUFFER_SIZE+1) <= 64) ? 6 : 7;

reg [COEFF_WIDTH*CHANNELS-1:0]                 dOut_shift;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_sum;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_add;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_sub;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_add_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_add_1;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_sub_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_sub_1;

reg	advanceRead1,advanceRead2,advanceRead3,advanceRead4;

wire [DATA_WIDTH*CHANNELS-1:0]	readData00;
wire [DATA_WIDTH*CHANNELS-1:0]	readData01;
wire [DATA_WIDTH*CHANNELS-1:0]	readData02;
wire [DATA_WIDTH*CHANNELS-1:0]	readData03;
wire [DATA_WIDTH*CHANNELS-1:0]	readData10;
wire [DATA_WIDTH*CHANNELS-1:0]	readData11;
wire [DATA_WIDTH*CHANNELS-1:0]	readData12;
wire [DATA_WIDTH*CHANNELS-1:0]	readData13;
wire [DATA_WIDTH*CHANNELS-1:0]	readData20;
wire [DATA_WIDTH*CHANNELS-1:0]	readData21;
wire [DATA_WIDTH*CHANNELS-1:0]	readData22;
wire [DATA_WIDTH*CHANNELS-1:0]	readData23;
wire [DATA_WIDTH*CHANNELS-1:0]	readData30;
wire [DATA_WIDTH*CHANNELS-1:0]	readData31;
wire [DATA_WIDTH*CHANNELS-1:0]	readData32;
wire [DATA_WIDTH*CHANNELS-1:0]	readData33;

reg [INPUT_X_RES_WIDTH-1:0]	    readAddress;

reg 							readyForRead;		//Indicates four full lines have been put into the buffer
(* keep = "true" *)reg [SCALE_BITS-1:0]	        outputLine;			//which output video line we're on
(* keep = "true" *)reg [SCALE_BITS-1:0]	        outputLine_dump;  //outputLine dump register
reg [SCALE_BITS-1:0]		    outputColumn;		//which output video column we're on
reg [SCALE_BITS-1:0]		    outputColumn_reg;
reg [2*SCALE_BITS-1:0]          xScaleAmount;		//Fractional and integer components of input pixel select (multiply result)
reg [2*SCALE_BITS-1:0]          yScaleAmount;		//Fractional and integer components of input pixel select (multiply result)
reg [2*SCALE_BITS-1:0]          yScaleAmountNext;	//Fractional and integer components of input pixel select (multiply result)
wire [BUFFER_SIZE_WIDTH-1:0] 	fillCount;			//Numbers used rams in the ram fifo
reg                 			lineSwitchOutputDisable; //On the end of an output line, disable the output for one cycle to let the RAM data become valid
reg								dOutValidInt;

reg [COEFF_WIDTH-1:0]			xBlend;             //the length of u
reg [COEFF_WIDTH-1:0]			yBlend;             //the length or v

wire [INPUT_X_RES_WIDTH-1:0]	xPixLow = xScaleAmount[INPUT_X_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];

wire 							allDataWritten;		//Indicates that one frame from input has been read in
reg 							readState;
reg                             state_m_comb;

reg [INPUT_Y_RES_WIDTH-1:0]	yPixLow;
always @ (posedge clk)
begin
	yPixLow <= yScaleAmount[INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];
end

reg [INPUT_Y_RES_WIDTH-1:0]	yPixLowNext;
always @ (posedge clk)
begin
	yPixLowNext <= yScaleAmountNext[INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];
end

//States for read state machine
localparam RS_START = 0;
localparam RS_READ_LINE = 1;

//Read state machine
//Controls the RFIFO(ram FIFO) readout and generates output data valid signals
always @ (posedge clk or posedge rst or posedge start)
begin
	if(rst | start)
	begin
		outputLine_dump <= 0;
		outputLine <= 0;
		outputColumn <= 0;
		outputColumn_reg <= 1;
		xScaleAmount <= 0;
		yScaleAmount <= 0;
		readState <= RS_START;
		dOutValidInt <= 0;
		lineSwitchOutputDisable <= 0;
		advanceRead1 <= 0;
		advanceRead2 <= 0;
		advanceRead3 <= 0;
		advanceRead4 <= 0;
	end
	else
	begin
		case (readState)  
			RS_START:
			begin
				//X、Y坐标初始化
				xScaleAmount <= leftOffset;
				yScaleAmount <= {{INPUT_Y_RES_WIDTH{1'b0}}, topFracOffset};
				if(readyForRead)     //如果已经缓存了4行及以上的视频数据，触发读操作
				begin
					readState <= RS_READ_LINE;
					dOutValidInt <= 1;
				end
			end

			RS_READ_LINE:
			begin
				//每次计算得到一行新的数据，需要取出4行源图像的数据
				if(dout_Enable && dOutValidInt)  //如果外部读请求nextDout有效
				begin
					if(outputColumn[10:0] == outputXRes)  //如果处理到了一行的最后一个像素
					begin
						//如果待读的原图像下一行与当前行的值只相差1行
						//则在计算下一个输出行时，只需要取出源图像的1行
						if(yPixLowNext == (yPixLow + 1))
						begin
							//当advanceRead1=1时
							//表示输出图像的计算只需要一行旧数据和一行新数据(每次读需要两行的数据)
							advanceRead1 <= 1;
							//如果ram缓存的数据小于3行，无效读控制信号
							//因为上一行的计算用掉了两行，这一行的计算需要一行旧数据和一行新数据
							//所以起码要已经缓存了3行数据
							if(fillCount < 5)		
								dOutValidInt <= 0;
						end
						//如果待读的原图像下一行与当前行的值相差大于1
						//则在计算下一个输出行时，需要取出源图像的两行
						if(yPixLowNext == (yPixLow + 2))
						begin
							advanceRead2 <= 1;
							//如果ram缓存的数据小于4行，无效读控制信号
							//因为上一行的计算用掉了两行，这一行的计算需要两行新数据
							//所以起码要已经缓存了4行数据(这时所有的ram已经用完了)
							if(fillCount < 6)
								dOutValidInt <= 0;
						end					
						if(yPixLowNext == (yPixLow + 3))
						begin
							advanceRead3 <= 1;
							//如果ram缓存的数据小于4行，无效读控制信号
							//因为上一行的计算用掉了两行，这一行的计算需要两行新数据
							//所以起码要已经缓存了4行数据(这时所有的ram已经用完了)
							if(fillCount < 7)
								dOutValidInt <= 0;
						end
						if(yPixLowNext > (yPixLow + 3))
						begin
							advanceRead4 <= 1;
							//如果ram缓存的数据小于4行，无效读控制信号
							//因为上一行的计算用掉了两行，这一行的计算需要两行新数据
							//所以起码要已经缓存了4行数据(这时所有的ram已经用完了)
							if(fillCount < 8)
								dOutValidInt <= 0;
						end
						outputColumn <= 0;                //处理下一行，变量初始化
						outputColumn_reg <= 1;
						xScaleAmount <= leftOffset;       //处理下一行，变量初始化
						outputLine <= outputLine + 1;     //下一行(对应输出图像)
						outputLine_dump <= outputLine_dump + 1;
						yScaleAmount <= yScaleAmountNext; //处理下一行，变量更新
						lineSwitchOutputDisable <= 1;
					end
					else
					begin
						if(lineSwitchOutputDisable == 0)
						begin
							outputColumn <= outputColumn + 1;    //输出图像X坐标一次加1
							outputColumn_reg <= outputColumn_reg + 1;
							xScaleAmount <= outputColumn_reg * xScale; //将输出图像X点坐标换算成在输入图像上的X点坐标。
						end
						advanceRead1 <= 0;
						advanceRead2 <= 0;
						advanceRead3 <= 0;
						advanceRead4 <= 0;
						lineSwitchOutputDisable <= 0;
					end
				end
				else //else from if(dout_Enable && dOutValidInt)
				begin
					advanceRead1 <= 0;
					advanceRead2 <= 0;
					advanceRead3 <= 0;
					advanceRead4 <= 0;
					lineSwitchOutputDisable <= 0;
				end
				
				//当dOutValidInt无效(在上面的读操作中，如果检测到ram缓存的行不够，将停止读操作)
				//且如果fillCount大于等于4行，即已经通过写操作缓存了4行数据，将有效读控制信号
				//或者一帧写操作完成(allDataWritten==1)后，也将有效读控制信号
				if(fillCount >= 4 && dOutValidInt == 0 || allDataWritten)
				begin
					if( state_m_comb )
					begin
						dOutValidInt <= 1;
						lineSwitchOutputDisable <= 0;
					end
				end
			end
		endcase
	end
end

reg  [7:0] state_vaild_cnt;
//在RAM缓存数量无法满足下一行输出时,拓宽state_m_comb无效信号
//以保证不会误触发dOutValidInt使能信号
always@(posedge clk)
begin
	if(rst | start) begin
		state_vaild_cnt <= 1'd0;
		state_m_comb <= 1'd1;
	end
	else if(state_vaild_cnt > 0) begin
		state_vaild_cnt <= state_vaild_cnt + 1;
		if(state_vaild_cnt == 8'd30) begin
			state_m_comb <= 1'd1;
			state_vaild_cnt <= 1'd0;
		end
	end
	else if(outputColumn[10:0] == outputXRes) begin
		state_m_comb <= 1'd0;
		state_vaild_cnt <= state_vaild_cnt + 1;
	end
end

reg [SCALE_BITS-1:0] outputLine_reg;
//将输出图像Y点坐标换算成输入图像上的Y点坐标。
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		yScaleAmountNext <= 0;
		outputLine_reg <= 0;
	end
	else begin
		outputLine_reg <= outputLine + 1;
		yScaleAmountNext <= outputLine_reg * yScale;
	end
end

//一帧数据缩放处理完毕后，scaler_done有效一个周期
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		scaler_done <= 0;
	end
	else
	begin
		scaler_done <= (outputLine_dump == outputYRes) && (outputColumn[10:0] == outputXRes);
	end
end

//读地址等于换算后的原图像X轴坐标
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		readAddress <= 0;
	end
	else begin
		readAddress <= xPixLow;
	end
end

reg [26:0] dOutValid_reg;
//在读请求n个时钟周期后，图像输出数据有效
always @(posedge clk or posedge rst or posedge start)
begin
	if(rst | start)
	begin
		dOutValid_reg <= 0;
		dOutValid <= 0;
	end
	else
	begin
		//！lineSwitchOutputDisable(注意这个信号只在切换下一行时拉高一个周期)
		//插值计算有26个周期的延时
		dOutValid_reg <= {dOutValid_reg[25:0],(dout_Enable && dOutValidInt && !lineSwitchOutputDisable)};
		dOutValid <= dOutValid_reg[26];
	end
end

always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		xBlend <= 0;
		yBlend <= 0;
	end
	else begin
		//求出u\v
		xBlend <= {1'b0, xScaleAmount[SCALE_FRAC_BITS-1:SCALE_FRAC_BITS-FRACTION_BITS]};
		yBlend <= {1'b0, yScaleAmount[SCALE_FRAC_BITS-1:SCALE_FRAC_BITS-FRACTION_BITS]};
	end
end

wire [COEFF_WIDTH-1:0]	coeff00_0;
wire [COEFF_WIDTH-1:0]	coeff01_0;
wire [COEFF_WIDTH-1:0]	coeff02_0;
wire [COEFF_WIDTH-1:0]	coeff03_0;
wire [COEFF_WIDTH-1:0]	coeff10_0;
wire [COEFF_WIDTH-1:0]	coeff11_0;
wire [COEFF_WIDTH-1:0]	coeff12_0;
wire [COEFF_WIDTH-1:0]	coeff13_0;
wire [COEFF_WIDTH-1:0]	coeff20_0;
wire [COEFF_WIDTH-1:0]	coeff21_0;
wire [COEFF_WIDTH-1:0]	coeff22_0;
wire [COEFF_WIDTH-1:0]	coeff23_0;
wire [COEFF_WIDTH-1:0]	coeff30_0;
wire [COEFF_WIDTH-1:0]	coeff31_0;
wire [COEFF_WIDTH-1:0]	coeff32_0;
wire [COEFF_WIDTH-1:0]	coeff33_0;

reg [COEFF_WIDTH-1:0]	coeff00_1;
reg [COEFF_WIDTH-1:0]	coeff01_1;
reg [COEFF_WIDTH-1:0]	coeff02_1;
reg [COEFF_WIDTH-1:0]	coeff03_1;
reg [COEFF_WIDTH-1:0]	coeff10_1;
reg [COEFF_WIDTH-1:0]	coeff11_1;
reg [COEFF_WIDTH-1:0]	coeff12_1;
reg [COEFF_WIDTH-1:0]	coeff13_1;
reg [COEFF_WIDTH-1:0]	coeff20_1;
reg [COEFF_WIDTH-1:0]	coeff21_1;
reg [COEFF_WIDTH-1:0]	coeff22_1;
reg [COEFF_WIDTH-1:0]	coeff23_1;
reg [COEFF_WIDTH-1:0]	coeff30_1;
reg [COEFF_WIDTH-1:0]	coeff31_1;
reg [COEFF_WIDTH-1:0]	coeff32_1;
reg [COEFF_WIDTH-1:0]	coeff33_1;

wire [COEFF_WIDTH-1:0]	bi_y0;
wire [COEFF_WIDTH-1:0]	bi_y1;
wire [COEFF_WIDTH-1:0]	bi_y2;
wire [COEFF_WIDTH-1:0]	bi_y3;
wire [COEFF_WIDTH-1:0]	bi_x0;
wire [COEFF_WIDTH-1:0]	bi_x1;
wire [COEFF_WIDTH-1:0]	bi_x2;
wire [COEFF_WIDTH-1:0]	bi_x3;

//边长(1<<8)
wire [COEFF_WIDTH-1:0]	coeffOne  = {1'b1, {(COEFF_WIDTH-1){1'b0}}};
//边长的一半(0.5<<8)
wire [COEFF_WIDTH-1:0]	coeffHalf = {2'b01, {(COEFF_WIDTH-2){1'b0}}};
//BiCubic函数a值(0.5<<8)
wire [COEFF_WIDTH-1:0]  bi_a      = {2'b01, {(COEFF_WIDTH-2){1'b0}}};

//Compute the BiCubic
BiCubic BiCubic_inst(
	.clk        (clk),
	.rst_n      (!rst | !start),
	.coeffHalf  (coeffHalf),
	.coeffOne   (coeffOne),
	.yBlend     (yBlend),
	.bi_a       (bi_a),
	.xBlend     (xBlend),
	.bi_y0      (bi_y0),
	.bi_y1      (bi_y1),
	.bi_y2      (bi_y2),
	.bi_y3      (bi_y3),
	.bi_x0      (bi_x0),
	.bi_x1      (bi_x1),
	.bi_x2      (bi_x2),
	.bi_x3      (bi_x3)
);

//Compute the coefficients
coefficient #(
	.FRACTION_BITS  (FRACTION_BITS),
	.COEFF_WIDTH    (COEFF_WIDTH)
)coefficient_inst(
	.clk        (clk),
	.rst_n      (!rst | !start),
	.coeffHalf  (coeffHalf),
	.bi_y0      (bi_y0),
	.bi_y1      (bi_y1),
	.bi_y2      (bi_y2),
	.bi_y3      (bi_y3),
	.bi_x0      (bi_x0),
	.bi_x1      (bi_x1),
	.bi_x2      (bi_x2),
	.bi_x3      (bi_x3),
	.coeff00    (coeff00_0),
	.coeff01    (coeff01_0),
	.coeff02    (coeff02_0),
	.coeff03    (coeff03_0),
	.coeff10    (coeff10_0),
	.coeff11    (coeff11_0),
	.coeff12    (coeff12_0),
	.coeff13    (coeff13_0),
	.coeff20    (coeff20_0),
	.coeff21    (coeff21_0),
	.coeff22    (coeff22_0),
	.coeff23    (coeff23_0),
	.coeff30    (coeff30_0),
	.coeff31    (coeff31_0),
	.coeff32    (coeff32_0),
	.coeff33    (coeff33_0)
);

reg [COEFF_WIDTH-1:0]	coeff00_reg0;
reg [COEFF_WIDTH-1:0]	coeff01_reg0;
reg [COEFF_WIDTH-1:0]	coeff02_reg0;
reg [COEFF_WIDTH-1:0]	coeff03_reg0;
reg [COEFF_WIDTH-1:0]	coeff10_reg0;
reg [COEFF_WIDTH-1:0]	coeff11_reg0;
reg [COEFF_WIDTH-1:0]	coeff12_reg0;
reg [COEFF_WIDTH-1:0]	coeff13_reg0;
reg [COEFF_WIDTH-1:0]	coeff20_reg0;
reg [COEFF_WIDTH-1:0]	coeff21_reg0;
reg [COEFF_WIDTH-1:0]	coeff22_reg0;
reg [COEFF_WIDTH-1:0]	coeff23_reg0;
reg [COEFF_WIDTH-1:0]	coeff30_reg0;
reg [COEFF_WIDTH-1:0]	coeff31_reg0;
reg [COEFF_WIDTH-1:0]	coeff32_reg0;
reg [COEFF_WIDTH-1:0]	coeff33_reg0;

reg [COEFF_WIDTH-1:0]	coeff00_reg1;
reg [COEFF_WIDTH-1:0]	coeff01_reg1;
reg [COEFF_WIDTH-1:0]	coeff02_reg1;
reg [COEFF_WIDTH-1:0]	coeff03_reg1;
reg [COEFF_WIDTH-1:0]	coeff10_reg1;
reg [COEFF_WIDTH-1:0]	coeff11_reg1;
reg [COEFF_WIDTH-1:0]	coeff12_reg1;
reg [COEFF_WIDTH-1:0]	coeff13_reg1;
reg [COEFF_WIDTH-1:0]	coeff20_reg1;
reg [COEFF_WIDTH-1:0]	coeff21_reg1;
reg [COEFF_WIDTH-1:0]	coeff22_reg1;
reg [COEFF_WIDTH-1:0]	coeff23_reg1;
reg [COEFF_WIDTH-1:0]	coeff30_reg1;
reg [COEFF_WIDTH-1:0]	coeff31_reg1;
reg [COEFF_WIDTH-1:0]	coeff32_reg1;
reg [COEFF_WIDTH-1:0]	coeff33_reg1;

//寄存延时
always@(posedge clk)
begin
	coeff00_reg0 <= coeff00_0;
	coeff01_reg0 <= coeff01_0;
	coeff02_reg0 <= coeff02_0;
	coeff03_reg0 <= coeff03_0;
	coeff10_reg0 <= coeff10_0;
	coeff11_reg0 <= coeff11_0;
	coeff12_reg0 <= coeff12_0;
	coeff13_reg0 <= coeff13_0;
	coeff20_reg0 <= coeff20_0;
	coeff21_reg0 <= coeff21_0;
	coeff22_reg0 <= coeff22_0;
	coeff23_reg0 <= coeff23_0;
	coeff30_reg0 <= coeff30_0;
	coeff31_reg0 <= coeff31_0;
	coeff32_reg0 <= coeff32_0;
	coeff33_reg0 <= coeff33_0;
	
	coeff00_reg1 <= coeff00_reg0;
	coeff01_reg1 <= coeff01_reg0;
	coeff02_reg1 <= coeff02_reg0;
	coeff03_reg1 <= coeff03_reg0;
	coeff10_reg1 <= coeff10_reg0;
	coeff11_reg1 <= coeff11_reg0;
	coeff12_reg1 <= coeff12_reg0;
	coeff13_reg1 <= coeff13_reg0;
	coeff20_reg1 <= coeff20_reg0;
	coeff21_reg1 <= coeff21_reg0;
	coeff22_reg1 <= coeff22_reg0;
	coeff23_reg1 <= coeff23_reg0;
	coeff30_reg1 <= coeff30_reg0;
	coeff31_reg1 <= coeff31_reg0;
	coeff32_reg1 <= coeff32_reg0;
	coeff33_reg1 <= coeff33_reg0;
end

reg [COEFF_WIDTH-1:0]	coeff00;
reg [COEFF_WIDTH-1:0]	coeff01;
reg [COEFF_WIDTH-1:0]	coeff02;
reg [COEFF_WIDTH-1:0]	coeff03;
reg [COEFF_WIDTH-1:0]	coeff10;
reg [COEFF_WIDTH-1:0]	coeff11;
reg [COEFF_WIDTH-1:0]	coeff12;
reg [COEFF_WIDTH-1:0]	coeff13;
reg [COEFF_WIDTH-1:0]	coeff20;
reg [COEFF_WIDTH-1:0]	coeff21;
reg [COEFF_WIDTH-1:0]	coeff22;
reg [COEFF_WIDTH-1:0]	coeff23;
reg [COEFF_WIDTH-1:0]	coeff30;
reg [COEFF_WIDTH-1:0]	coeff31;
reg [COEFF_WIDTH-1:0]	coeff32;
reg [COEFF_WIDTH-1:0]	coeff33;
//寄存延时
always@(posedge clk)
begin
	coeff00 <= coeff00_reg1;
	coeff01 <= coeff01_reg1;
	coeff02 <= coeff02_reg1;
	coeff03 <= coeff03_reg1;
	coeff10 <= coeff10_reg1;
	coeff11 <= coeff11_reg1;
	coeff12 <= coeff12_reg1;
	coeff13 <= coeff13_reg1;
	coeff20 <= coeff20_reg1;
	coeff21 <= coeff21_reg1;
	coeff22 <= coeff22_reg1;
	coeff23 <= coeff23_reg1;
	coeff30 <= coeff30_reg1;
	coeff31 <= coeff31_reg1;
	coeff32 <= coeff32_reg1;
	coeff33 <= coeff33_reg1;
end

//Generate the blending multipliers
reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0]	product00, product01, product02, product03,product10, product11, product12, product13,product20, product21, product22, product23,product30, product31, product32, product33;
generate
genvar channel;
	for(channel = 0; channel < CHANNELS; channel = channel + 1)
		begin : blend_mult_generate
			always @(posedge clk or posedge rst)
			begin
				if(rst)
				begin
					//productxx[channel] <= 0;
					product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
					dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;				
					dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
					dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= 0;
					dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= 0;
					
				end
				else
				begin
					/* 
					                       >>>>>>>>>>列地址>>>>>>>>>>>
					           -------------------------------------------------
					  第0行   |readData00  | readData01 | readData02 |readData03|
	                ----------|------------|------------|------------|----------|
					  第1行   |readData10  | readData11 | readData12 |readData13|
					----------|------------|------------|------------|----------|
					  第2行	  |readData20  | readData21 | readData22 |readData23|
					----------|------------|------------|------------|----------|
					  第3行	  |readData30  | readData31 | readData32 |readData33|
							   -------------------------------------------------  
					*/
					//coeff*_latency=14
					//readData*_latency=14
					//productxx[channel] <= readDataxx[channel] * coeffxx
					product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData00[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff00;
					product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData01[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff01;
					product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData02[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff02;
					product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData03[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff03;
					product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData10[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff10;
					product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData11[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff11;
					product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData12[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff12;
					product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData13[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff13;
					product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData20[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff20;
					product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData21[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff21;
					product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData22[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff22;
					product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData23[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff23;
					product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData30[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff30;
					product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData31[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff31;
					product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData32[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff32;
					product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= readData33[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff33;
					
					dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
					
					//计算正数部分和
					dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
							
					//计算负数部分和
					dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
					
					//计算加权和(正数部分和 - 负数部分和)
					dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= (dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >= dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ]) ? dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] : dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ];
					
					//加权和结果移位 9+8+4=21
					dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= (dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >> 8) & ({ {(DATA_WIDTH+4){1'b0}}, {COEFF_WIDTH{1'b1}} });
					
					//最终结果异常判断(判断是否大于255,否则取低八位)
					dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= (dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel] > 9'd255)? 8'd255 : dOut_shift[ COEFF_WIDTH*(channel+1)-2 : COEFF_WIDTH*channel];
				end
			end
		end
endgenerate


//***************************Data write logic*******************************

reg [INPUT_Y_RES_WIDTH-1:0]		writeNextValidLine;	//下一个有效行数
reg [INPUT_Y_RES_WIDTH-1:0]		writeNextPlusOne;	//writeNextPlusOne=writeNextValidLine+1
reg [INPUT_Y_RES_WIDTH-1:0]		writeNextPlusTwo;	//writeNextPlusTwo=writeNextValidLine+2
reg [INPUT_Y_RES_WIDTH-1:0]		writeRowCount;		//已经缓存的行数
reg [OUTPUT_Y_RES_WIDTH-1:0]	writeOutputLine;    //输出对应输入图像的行数
reg								getNextPlusOne;     //控制信号

always @(posedge clk or posedge rst or posedge start)
begin
	if(rst | start)
	begin
		writeOutputLine <= 0;
		writeNextValidLine <= 0;
		writeNextPlusOne <= 1;
		writeNextPlusTwo <= 2;
		getNextPlusOne <= 1;
	end
	else
	begin
		if(writeRowCount >= writeNextValidLine)
		begin
			if(getNextPlusOne)
			begin
				//writeNextPlusOne的目的是每次可以缓存有效行和有效行的下一行，即一次可以缓存相邻两行数据
				writeNextPlusOne <= writeNextValidLine + 1;
				writeNextPlusTwo <= writeNextValidLine + 1;
			end
			getNextPlusOne <= 0;
			//相对于输入行的输出行数
			writeOutputLine <= writeOutputLine + 1 /* + interlace_flag */;
			//因为不是输入帧的每一行都是有效行，所以此处计算出有效行来缓存，丢弃无效行
			writeNextValidLine <= ((writeOutputLine*yScale + {{(OUTPUT_Y_RES_WIDTH + SCALE_INT_BITS){1'b0}}, topFracOffset}) >> SCALE_FRAC_BITS) & {{SCALE_BITS{1'b0}}, {OUTPUT_Y_RES_WIDTH{1'b1}}};
		end
		else
		begin
			getNextPlusOne <= 1;
		end
	end
end

reg			discardInput;   //discardInput写控制信号 0有效
reg [DISCARD_CNT_WIDTH-1:0] discardCountReg;

reg [1:0]	writeState;

(* keep = "true" *)  reg [INPUT_X_RES_WIDTH-1:0] writeColCount;
(* keep = "true" *)  reg [INPUT_X_RES_WIDTH-1:0] writeColCount_dump;
reg			enableNextDin;
reg			forceRead;

//Write state machine
//Controls writing scaler input data into the RRB

localparam	WS_START = 0;
localparam	WS_DISCARD = 1;
localparam	WS_READ = 2;
localparam	WS_DONE = 3;

//Control write and address signals to write data into ram FIFO
always @ (posedge clk)
begin
	if(rst)
	begin
		writeState <= WS_START;
		enableNextDin <= 0;
		discardInput <= 0;
		readyForRead <= 0;
		writeRowCount <= 0;
		writeColCount <= 0;
		writeColCount_dump <= 0;
		discardCountReg <= 0;
		forceRead <= 0;
	end
	else
	begin
		case (writeState)
		
			WS_START:
			begin
				discardCountReg <= inputDiscardCnt;
				if(inputDiscardCnt > 0)
				begin
					discardInput <= 1;
					enableNextDin <= 1;
					writeState <= WS_DISCARD;
				end
				else
				begin
					discardInput <= 0;
					enableNextDin <= 1;
					writeState <= WS_READ;
				end
				discardInput <= (inputDiscardCnt > 0) ? 1'b1 : 1'b0;
			end
			
			WS_DISCARD:	//Discard pixels from input data
			begin
				if(dInValid)
				begin
					discardCountReg <= discardCountReg - 1;
					if((discardCountReg - 1) == 0)
					begin
						discardInput <= 0;
						writeState <= WS_READ;
					end
				end
			end
			
			WS_READ:
			begin
				//dInValid 写入RAM数据有效
				//din_Enable 缓存RAM未满
				if(dInValid & din_Enable)
				begin
					//如果已经缓存到了一行的最后一个像素
					if(writeColCount == inputXRes)
					begin
						if((writeNextValidLine == writeRowCount + 1) ||
						    (writeNextValidLine == writeRowCount + 2) ||
							(writeNextPlusOne == writeRowCount + 1) ||
							(writeNextPlusTwo == writeRowCount + 2))
						begin 
							discardInput <= 0;  //下一行有效
						end
						else
						begin	//Next line is not valid, discard
							discardInput <= 1;
						end
						
						//只要缓存的行数等于4之后，readyForRead一直有效直到下一帧
						if(writeRowCount[2])
							readyForRead <= 1;
						
						if(writeRowCount == inputYRes)	//当输入的一帧画面全部处理完，停止写操作
						begin
							writeState <= WS_DONE;
							enableNextDin <= 0;
							forceRead <= 1;
						end
						
						writeColCount <= 0;   //列计数清零
						writeColCount_dump <= 0;
						writeRowCount <= writeRowCount + 1;   //行计数加1
					end
					else if(fillCount == BUFFER_SIZE) begin
						writeColCount <= 0;   //列计数清零
						writeColCount_dump <= 0;
					end
					else
					begin
						writeColCount <= writeColCount + 1;   //列计数加1
						writeColCount_dump <= writeColCount_dump + 1;   //列计数加1
					end
				end
			end
			
			WS_DONE:
			begin
				//do nothing, wait for reset
			end
			
		endcase
	end
end

//BUFFER_SIZE=8
//当缓存RAM未满(fillCount < 8),nextDin有效
//当缓存RAM已满,禁止写入数据
reg nextDin_Reg;
always@(posedge clk)
begin
	if(rst | start) begin
		nextDin_Reg <= 0;
	end
	else if((fillCount < BUFFER_SIZE) & enableNextDin) begin
		nextDin_Reg <= 1;
	end
	else begin
		nextDin_Reg <= 0;
	end
end
//assign din_Enable = nextDin_Reg;
assign din_Enable = (fillCount < BUFFER_SIZE) & enableNextDin;

//当写到一行的最后一位且输入数据有效且fillCount小于8时,advanceWrite拉高一个周期
//如果已经缓存了8个ram(fillCount==8),将不再允许写入数据
reg advanceWrite;
reg advanceWrite_delay;
always@(posedge clk)
begin
	if(rst | start) begin
		advanceWrite <= 0;
		advanceWrite_delay <= 0;
	end
	else if((writeColCount == inputXRes - 3) & (discardInput == 0) & dInValid & din_Enable) begin
		advanceWrite <= 1;
	end
	else if((writeColCount == inputXRes) & (discardInput == 0) & dInValid & din_Enable) begin
		advanceWrite_delay <= 1;
	end
	else begin
		advanceWrite <= 0;
		advanceWrite_delay <= 0;
	end
end
assign allDataWritten = (writeState == WS_DONE);

reg [5:0] First_Outputline_cnt;
reg First_Outputline;
//标记缩放的第一行(用作第一行的边缘处理)
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		First_Outputline_cnt <= 0;
	end
	else if(outputLine_dump == 0) begin
		First_Outputline_cnt <= 0;
	end
	else begin
		First_Outputline_cnt <= First_Outputline_cnt + 1;
	end
end

always@(posedge clk or posedge rst)
begin
	if(rst) begin
		First_Outputline <= 0;
	end
	else if(outputLine_dump == 0) begin
		First_Outputline <= 0;
	end
	else if(First_Outputline_cnt == 6'd17) begin
		First_Outputline <= 1;
	end
end

reg Last_Outputline;
reg [5:0] Last_Outputline_cnt;
//标记缩放的最后有效行(用作最后一行的边缘处理)
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		Last_Outputline_cnt <= 0;
	end
	else if(Last_Outputline) begin
		if(Last_Outputline_cnt == 6'd31) begin
			Last_Outputline_cnt <= 0;
		end
		else if(outputLine_dump == outputYRes+1) begin
			Last_Outputline_cnt <= Last_Outputline_cnt + 1;
		end
	end
	else if(outputLine_dump == outputYRes) begin
		Last_Outputline_cnt <= Last_Outputline_cnt + 1;
	end
end

always@(posedge clk or posedge rst)
begin
	if(rst) begin
		Last_Outputline <= 0;
	end
	else if(Last_Outputline) begin
		if(Last_Outputline_cnt == 6'd31) begin
			Last_Outputline <= 0;
		end
	end
	else if(Last_Outputline_cnt == 6'd15) begin
		Last_Outputline <= 1;
	end
end

reg writeEnable_reg_0,writeEnable_reg_1;
reg [INPUT_X_RES_WIDTH-1:0] writeColCount_reg;
reg forceRead_reg;
reg forceRead_dump;
reg advanceWrite_reg0,advanceWrite_reg1;
reg	[13:0] advanceRead1_ram,advanceRead2_ram,advanceRead3_ram,advanceRead4_ram;
reg [DATA_WIDTH*CHANNELS-1:0]  dIn_reg_0,dIn_reg_1;
reg Last_Outputline_reg,First_Outputline_reg;
//读ram缓存有效信号寄存n个时钟周期
always@(posedge clk)
begin
	dIn_reg_0 <= dIn;
	dIn_reg_1 <= dIn_reg_0;
	writeEnable_reg_0 <= dInValid & din_Enable & enableNextDin & ~discardInput;
	writeEnable_reg_1 <= writeEnable_reg_0;
	writeColCount_reg <= writeColCount_dump;
	forceRead_reg <= forceRead;
	advanceWrite_reg0 <= advanceWrite;
	advanceWrite_reg1 <= advanceWrite_reg0;
	advanceRead1_ram <= {advanceRead1_ram[12:0],advanceRead1};
	advanceRead2_ram <= {advanceRead2_ram[12:0],advanceRead2};
	advanceRead3_ram <= {advanceRead3_ram[12:0],advanceRead3};
	advanceRead4_ram <= {advanceRead4_ram[12:0],advanceRead4};
	Last_Outputline_reg <= Last_Outputline;
	First_Outputline_reg <= First_Outputline;
end

//缓存ram读写控制
cash_ram_rw #(
	.DATA_WIDTH( DATA_WIDTH*CHANNELS ),
	.ADDRESS_WIDTH( INPUT_X_RES_WIDTH ),
	.BUFFER_SIZE( BUFFER_SIZE )		        //ram数：8个
) cash_ram_rw_inst (
	.clk( clk ),
	.rst( rst | start ),
	.advanceRead1( advanceRead1_ram[13] ),
	.advanceRead2( advanceRead2_ram[13] ),
	.advanceRead3( advanceRead3_ram[13] ),
	.advanceRead4( advanceRead4_ram[13] ),
	.readAddress( readAddress ),
	.forceRead( forceRead_reg ),

	.inputXRes(inputXRes),
	.advanceWrite( advanceWrite_reg1 ),
	.advanceWrite_delay (advanceWrite_delay),
	.writeData( dIn_reg_1 ),
	.writeAddress( writeColCount_reg ),
	.writeEnable( writeEnable_reg_1 ),
	.fillCount( fillCount ),
	.First_Outputline(First_Outputline_reg),
	.Last_Outputline(Last_Outputline_reg),
	.allDataWritten(allDataWritten),
	.readData00 (readData00),
	.readData01 (readData01),
	.readData02 (readData02),
	.readData03 (readData03),
	.readData10 (readData10),
	.readData11 (readData11),
	.readData12 (readData12),
	.readData13 (readData13),
	.readData20 (readData20),
	.readData21 (readData21),
	.readData22 (readData22),
	.readData23 (readData23),
	.readData30 (readData30),
	.readData31 (readData31),
	.readData32 (readData32),
	.readData33 (readData33)
);

endmodule