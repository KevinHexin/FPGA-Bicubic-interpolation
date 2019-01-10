module cash_ram_rw #(
	parameter DATA_WIDTH = 24,
	parameter ADDRESS_WIDTH = 11,
	parameter BUFFER_SIZE = 8,
	parameter BUFFER_SIZE_WIDTH =	((BUFFER_SIZE+1) <= 2) ? 1 :
									((BUFFER_SIZE+1) <= 4) ? 2 :
									((BUFFER_SIZE+1) <= 8) ? 3 :
									((BUFFER_SIZE+1) <= 16) ? 4 :
									((BUFFER_SIZE+1) <= 32) ? 5 :
									((BUFFER_SIZE+1) <= 64) ? 6 : 7
)(
	input wire 						   clk,
	input wire 						   rst,
	input wire						   advanceRead1,	         //读取一行RAM
	input wire						   advanceRead2,	         //读取两行RAM
	input wire						   advanceRead3,	         //读取三行RAM
	input wire						   advanceRead4,	         //读取四行RAM
	input wire						   advanceWrite,	         //写入一行RAM
	input wire						   advanceWrite_delay,	     //写入一行RAM
	input wire						   forceRead,		         //一帧写入完成标识	
	input wire [ADDRESS_WIDTH-1:0]	   inputXRes,
	input wire [DATA_WIDTH-1:0]		   writeData,
	input wire [ADDRESS_WIDTH-1:0]	   writeAddress,
	input wire						   writeEnable,
	input wire                         allDataWritten,           //一帧所有数据写入完成标识
	output reg [BUFFER_SIZE_WIDTH-1:0] fillCount,                //缓存RAM计数器
	input wire [ADDRESS_WIDTH-1:0]	   readAddress, 
	/* input wire                         First_Outputline,
	input wire                         Last_Outputline, */
									
	output reg [DATA_WIDTH-1:0]	       readData00,
	output reg [DATA_WIDTH-1:0]	       readData01,
	output reg [DATA_WIDTH-1:0]	       readData02,
	output reg [DATA_WIDTH-1:0]	       readData03,
	output reg [DATA_WIDTH-1:0]	       readData10,
	output reg [DATA_WIDTH-1:0]	       readData11,
	output reg [DATA_WIDTH-1:0]	       readData12,
	output reg [DATA_WIDTH-1:0]	       readData13,
	output reg [DATA_WIDTH-1:0]	       readData20,
	output reg [DATA_WIDTH-1:0]	       readData21,
	output reg [DATA_WIDTH-1:0]	       readData22,
	output reg [DATA_WIDTH-1:0]	       readData23,
	output reg [DATA_WIDTH-1:0]	       readData30,
	output reg [DATA_WIDTH-1:0]	       readData31,
	output reg [DATA_WIDTH-1:0]	       readData32,
	output reg [DATA_WIDTH-1:0]	       readData33
);

reg [DATA_WIDTH-1:0]	ramDataOutA_0;
reg [DATA_WIDTH-1:0]	ramDataOutA_1;
reg [DATA_WIDTH-1:0]	ramDataOutA_2;
reg [DATA_WIDTH-1:0]	ramDataOutA_3;
reg [DATA_WIDTH-1:0]	ramDataOutA_4;
reg [DATA_WIDTH-1:0]	ramDataOutA_5;
reg [DATA_WIDTH-1:0]	ramDataOutA_6;
reg [DATA_WIDTH-1:0]	ramDataOutA_7;
reg [DATA_WIDTH-1:0]	ramDataOutB_0;
reg [DATA_WIDTH-1:0]	ramDataOutB_1;
reg [DATA_WIDTH-1:0]	ramDataOutB_2;
reg [DATA_WIDTH-1:0]	ramDataOutB_3;
reg [DATA_WIDTH-1:0]	ramDataOutB_4;
reg [DATA_WIDTH-1:0]	ramDataOutB_5;
reg [DATA_WIDTH-1:0]	ramDataOutB_6;
reg [DATA_WIDTH-1:0]	ramDataOutB_7;
reg [DATA_WIDTH-1:0]	ramDataOutC_0;
reg [DATA_WIDTH-1:0]	ramDataOutC_1;
reg [DATA_WIDTH-1:0]	ramDataOutC_2;
reg [DATA_WIDTH-1:0]	ramDataOutC_3;
reg [DATA_WIDTH-1:0]	ramDataOutC_4;
reg [DATA_WIDTH-1:0]	ramDataOutC_5;
reg [DATA_WIDTH-1:0]	ramDataOutC_6;
reg [DATA_WIDTH-1:0]	ramDataOutC_7;
reg [DATA_WIDTH-1:0]	ramDataOutD_0;
reg [DATA_WIDTH-1:0]	ramDataOutD_1;
reg [DATA_WIDTH-1:0]	ramDataOutD_2;
reg [DATA_WIDTH-1:0]	ramDataOutD_3;
reg [DATA_WIDTH-1:0]	ramDataOutD_4;
reg [DATA_WIDTH-1:0]	ramDataOutD_5;
reg [DATA_WIDTH-1:0]	ramDataOutD_6;
reg [DATA_WIDTH-1:0]	ramDataOutD_7;
reg [DATA_WIDTH-1:0]	readData00_reg;
reg [DATA_WIDTH-1:0]	readData01_reg;
reg [DATA_WIDTH-1:0]	readData02_reg;
reg [DATA_WIDTH-1:0]	readData03_reg;
reg [DATA_WIDTH-1:0]	readData10_reg;
reg [DATA_WIDTH-1:0]	readData11_reg;
reg [DATA_WIDTH-1:0]	readData12_reg;
reg [DATA_WIDTH-1:0]	readData13_reg;
reg [DATA_WIDTH-1:0]	readData20_reg;
reg [DATA_WIDTH-1:0]	readData21_reg;
reg [DATA_WIDTH-1:0]	readData22_reg;
reg [DATA_WIDTH-1:0]	readData23_reg;
reg [DATA_WIDTH-1:0]	readData30_reg;
reg [DATA_WIDTH-1:0]	readData31_reg;
reg [DATA_WIDTH-1:0]	readData32_reg;
reg [DATA_WIDTH-1:0]	readData33_reg;

reg [DATA_WIDTH-1:0]	readData00_reg_0;
reg [DATA_WIDTH-1:0]	readData01_reg_0;
reg [DATA_WIDTH-1:0]	readData02_reg_0;
reg [DATA_WIDTH-1:0]	readData03_reg_0;
reg [DATA_WIDTH-1:0]	readData10_reg_0;
reg [DATA_WIDTH-1:0]	readData11_reg_0;
reg [DATA_WIDTH-1:0]	readData12_reg_0;
reg [DATA_WIDTH-1:0]	readData13_reg_0;
reg [DATA_WIDTH-1:0]	readData20_reg_0;
reg [DATA_WIDTH-1:0]	readData21_reg_0;
reg [DATA_WIDTH-1:0]	readData22_reg_0;
reg [DATA_WIDTH-1:0]	readData23_reg_0;
reg [DATA_WIDTH-1:0]	readData30_reg_0;
reg [DATA_WIDTH-1:0]	readData31_reg_0;
reg [DATA_WIDTH-1:0]	readData32_reg_0;
reg [DATA_WIDTH-1:0]	readData33_reg_0;

(* keep = "true" *) reg [ADDRESS_WIDTH-1:0]	writeAddress0_dump0,writeAddress0_dump1,writeAddress0_dump2,writeAddress0_dump3,writeAddress0_dump4,writeAddress0_dump5,writeAddress0_dump6,writeAddress0_dump7;

(* keep = "true" *) reg [ADDRESS_WIDTH-1:0]	writeAddress1_dump0,writeAddress1_dump1,writeAddress1_dump2,writeAddress1_dump3,writeAddress1_dump4,writeAddress1_dump5,writeAddress1_dump6,writeAddress1_dump7;

(* keep = "true" *) reg [DATA_WIDTH-1:0]	writeData_dump0,writeData_dump1,writeData_dump2,writeData_dump3,writeData_dump4,writeData_dump5,writeData_dump6,writeData_dump7;

(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump0, readAddr_B_dump0, readAddr_C_dump0, readAddr_D_dump0;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump1, readAddr_B_dump1, readAddr_C_dump1, readAddr_D_dump1;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump2, readAddr_B_dump2, readAddr_C_dump2, readAddr_D_dump2;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump3, readAddr_B_dump3, readAddr_C_dump3, readAddr_D_dump3;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump4, readAddr_B_dump4, readAddr_C_dump4, readAddr_D_dump4;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump5, readAddr_B_dump5, readAddr_C_dump5, readAddr_D_dump5;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump6, readAddr_B_dump6, readAddr_C_dump6, readAddr_D_dump6;
(* keep = "true" *)reg [(ADDRESS_WIDTH-1):0] readAddr_A_dump7, readAddr_B_dump7, readAddr_C_dump7, readAddr_D_dump7;

//写地址寄存
always@(posedge clk)
begin
	writeAddress0_dump0 <= writeAddress;
	writeAddress0_dump1 <= writeAddress;
	writeAddress0_dump2 <= writeAddress;
	writeAddress0_dump3 <= writeAddress;
	writeAddress0_dump4 <= writeAddress;
	writeAddress0_dump5 <= writeAddress;
	writeAddress0_dump6 <= writeAddress;
	writeAddress0_dump7 <= writeAddress;
	
	writeAddress1_dump0 <= writeAddress0_dump0;
	writeAddress1_dump1 <= writeAddress0_dump1;
	writeAddress1_dump2 <= writeAddress0_dump2;
	writeAddress1_dump3 <= writeAddress0_dump3;
	writeAddress1_dump4 <= writeAddress0_dump4;
	writeAddress1_dump5 <= writeAddress0_dump5;
	writeAddress1_dump6 <= writeAddress0_dump6;
	writeAddress1_dump7 <= writeAddress0_dump7;
end

//写数据寄存
always@(posedge clk)
begin
	writeData_dump0 <= writeData;
	writeData_dump1 <= writeData;
	writeData_dump2 <= writeData;
	writeData_dump3 <= writeData;
	writeData_dump4 <= writeData;
	writeData_dump5 <= writeData;
	writeData_dump6 <= writeData;
	writeData_dump7 <= writeData;
end

//-------------------------------------------------------------
// 生成8个缓存RAM可使用个数标识
//-------------------------------------------------------------
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		fillCount <= 0;
	end
	else
	begin
		if(advanceWrite)             //每写入一行,缓存RAM标识fillCount+1
		begin
			if(advanceRead1)
				fillCount <= fillCount;
			else if(advanceRead2)
				fillCount <= fillCount - 1;
			else if(advanceRead3)
				fillCount <= fillCount - 2;
			else if(advanceRead4)
				fillCount <= fillCount - 3;
			else
				fillCount <= fillCount + 1;
		end
		else
		begin
			if(advanceRead1)         //每读出一行,缓存RAM标识fillCount-1
				fillCount <= fillCount - 1;
			else if(advanceRead2)    //每读出两行,缓存RAM标识fillCount-2
				fillCount <= fillCount - 2;
			else if(advanceRead3)    //每读出三行,缓存RAM标识fillCount-3
				fillCount <= fillCount - 3;
			else if(advanceRead4)    //每读出四行,缓存RAM标识fillCount-4
				fillCount <= fillCount - 4;
			else
				fillCount <= fillCount;
		end
	end
end

//-------------------------------------------------------------
// 相邻读地址生成和寄存器逻辑复制
//-------------------------------------------------------------

reg [ADDRESS_WIDTH-1:0] readAddress_reg [8:0];
//读地址寄存n个时钟周期
always @(posedge clk)
begin
	readAddress_reg[0] <= readAddress;
	readAddress_reg[1] <= readAddress_reg[0];
	readAddress_reg[2] <= readAddress_reg[1];
	readAddress_reg[3] <= readAddress_reg[2];
	readAddress_reg[4] <= readAddress_reg[3];
	readAddress_reg[5] <= readAddress_reg[4];
	readAddress_reg[6] <= readAddress_reg[5];
	readAddress_reg[7] <= readAddress_reg[6];
	readAddress_reg[8] <= readAddress_reg[7];
end
//主地址
wire [ADDRESS_WIDTH-1:0] readAddr = readAddress_reg[8];

reg [(ADDRESS_WIDTH-1):0] readAddr_A, readAddr_B, readAddr_C, readAddr_D;
//生成四个相邻读地址
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		readAddr_A <= 0;
		readAddr_B <= 0;
		readAddr_C <= 0;
		readAddr_D <= 0;
	end
	else begin
		//处理左边缘
		if(readAddr == 0) begin
			readAddr_A <= 0;
		end
		else begin
			readAddr_A <= readAddr - 1;
		end
		//处理右边缘
		if(readAddr >= inputXRes) begin
			readAddr_D <= readAddr;
			readAddr_C <= readAddr;
		end
		else begin
			readAddr_D <= readAddr + 2;
			readAddr_C <= readAddr + 1;
		end
		readAddr_B <= readAddr;
	end
end

//读地址寄存和寄存器逻辑复制
always@(posedge clk)
begin
	readAddr_A_dump0 <= readAddr_A;
	readAddr_A_dump1 <= readAddr_A;
	readAddr_A_dump2 <= readAddr_A;
	readAddr_A_dump3 <= readAddr_A;
	readAddr_A_dump4 <= readAddr_A;
	readAddr_A_dump5 <= readAddr_A;
	readAddr_A_dump6 <= readAddr_A;
	readAddr_A_dump7 <= readAddr_A;
	
	readAddr_B_dump0 <= readAddr_B;
	readAddr_B_dump1 <= readAddr_B;
	readAddr_B_dump2 <= readAddr_B;
	readAddr_B_dump3 <= readAddr_B;
	readAddr_B_dump4 <= readAddr_B;
	readAddr_B_dump5 <= readAddr_B;
	readAddr_B_dump6 <= readAddr_B;
	readAddr_B_dump7 <= readAddr_B;
	
	readAddr_C_dump0 <= readAddr_C;
	readAddr_C_dump1 <= readAddr_C;
	readAddr_C_dump2 <= readAddr_C;
	readAddr_C_dump3 <= readAddr_C;
	readAddr_C_dump4 <= readAddr_C;
	readAddr_C_dump5 <= readAddr_C;
	readAddr_C_dump6 <= readAddr_C;
	readAddr_C_dump7 <= readAddr_C;
	
	readAddr_D_dump0 <= readAddr_D;
	readAddr_D_dump1 <= readAddr_D;
	readAddr_D_dump2 <= readAddr_D;
	readAddr_D_dump3 <= readAddr_D;
	readAddr_D_dump4 <= readAddr_D;
	readAddr_D_dump5 <= readAddr_D;
	readAddr_D_dump6 <= readAddr_D;
	readAddr_D_dump7 <= readAddr_D;
end

//-------------------------------------------------------------
// 读写指针切换(切换指向8个不同的RAM)
// 读写不能同时操作同一个RAM
//-------------------------------------------------------------
reg [BUFFER_SIZE-1:0]		writeSelect;
reg [BUFFER_SIZE-1:0]		readSelect;

reg [3:0] read_select_case;
always@(posedge clk)
begin
	read_select_case <=  {advanceRead4,advanceRead3,advanceRead2,advanceRead1};
end

//读指针切换
always @(posedge clk or posedge rst)
begin
	if(rst)
		readSelect <= 2;
	else if((allDataWritten) && (fillCount <= 4)) begin
		readSelect <= readSelect;
	end
	else begin
		case (read_select_case)
			4'b0001: begin
				readSelect <= {readSelect[BUFFER_SIZE-2 : 0], readSelect[BUFFER_SIZE-1]};
			end
			4'b0010: begin
				readSelect <= {readSelect[BUFFER_SIZE-3 : 0], readSelect[BUFFER_SIZE-1:BUFFER_SIZE-2]};
			end
			4'b0100: begin
				readSelect <= {readSelect[BUFFER_SIZE-4 : 0], readSelect[BUFFER_SIZE-1:BUFFER_SIZE-3]};
			end
			4'b1000: begin
				readSelect <= {readSelect[BUFFER_SIZE-5 : 0], readSelect[BUFFER_SIZE-1:BUFFER_SIZE-4]};
			end
			default: ;
		endcase
	end
end

reg [BUFFER_SIZE-1:0]		writeSelect_reg;
//写指针切换
always @(posedge clk or posedge rst)
begin
	if(rst)
		writeSelect <= 1;
	else
	begin
		if(advanceWrite_delay)   //每次advanceWrite有效时,将换下一个ram来存储下一行数据
		begin
			writeSelect <= {writeSelect[BUFFER_SIZE-2 : 0], writeSelect[BUFFER_SIZE-1]};
		end
		writeSelect_reg <= writeSelect;
	end
end

//-------------------------------------------------------------
// 8行RAM缓存数据读写控制
//-------------------------------------------------------------

reg wr_enable0,wr_enable1,wr_enable2,wr_enable3,wr_enable4,wr_enable5,wr_enable6,wr_enable7;
//生成8个缓存RAM写使能
always@(posedge clk or posedge rst)
begin
	if(rst) begin
		wr_enable0 <= 0;
		wr_enable1 <= 0;
		wr_enable2 <= 0;
		wr_enable3 <= 0;
		wr_enable4 <= 0;
		wr_enable5 <= 0;
		wr_enable6 <= 0;
		wr_enable7 <= 0;
	end
	else if((!forceRead) & writeEnable) begin
		case (writeSelect_reg)
			8'b00000001: begin 
				wr_enable0 <= 1;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b00000010: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 1;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b00000100: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 1;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b00001000: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 1;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b00010000: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 1;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b00100000: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 1;
			    wr_enable6 <= 0;
			    wr_enable7 <= 0;
			end
			8'b01000000: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 1;
			    wr_enable7 <= 0;
			end
			8'b10000000: begin 
				wr_enable0 <= 0;
				wr_enable1 <= 0;
			    wr_enable2 <= 0;
			    wr_enable3 <= 0;
			    wr_enable4 <= 0;
			    wr_enable5 <= 0;
			    wr_enable6 <= 0;
			    wr_enable7 <= 1;
			end
			default: ;
		endcase
	end
	else begin
		wr_enable0 <= 0;
		wr_enable1 <= 0;
		wr_enable2 <= 0;
		wr_enable3 <= 0;
		wr_enable4 <= 0;
		wr_enable5 <= 0;
		wr_enable6 <= 0;
		wr_enable7 <= 0;
	end
end

/*

	***| ramDataOutA[0] | ramDataOutB[0] | ramDataOutC[0] | ramDataOutD[0] |***
	***| ramDataOutA[1] | ramDataOutB[1] | ramDataOutC[1] | ramDataOutD[1] |***
	...... 							  ......						     ......
	***| ramDataOutA[6] | ramDataOutB[6] | ramDataOutC[6] | ramDataOutD[6] |***
	***| ramDataOutA[7] | ramDataOutB[7] | ramDataOutC[7] | ramDataOutD[7] |***
*/
wire [DATA_WIDTH-1:0] ramDataOutA [2**BUFFER_SIZE-1:0];
wire [DATA_WIDTH-1:0] ramDataOutB [2**BUFFER_SIZE-1:0];
wire [DATA_WIDTH-1:0] ramDataOutC [2**BUFFER_SIZE-1:0];
wire [DATA_WIDTH-1:0] ramDataOutD [2**BUFFER_SIZE-1:0];

 ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst0(
	.clk( clk ),

	.addrB_in( (wr_enable0) ? writeAddress1_dump0 : readAddr_B_dump0 ),
	.data_in( writeData_dump0 ),									
	.we_in(wr_enable0),
	.qB( ramDataOutB[1] ),

	.addrC_in( readAddr_C_dump0 ),
	.qC( ramDataOutC[1] ),

	.addrD_in( readAddr_D_dump0 ),
	.qD( ramDataOutD[1] ),

	.addrA_in( readAddr_A_dump0 ),
	.qA( ramDataOutA[1] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst1(
	.clk( clk ),

	.addrB_in( (wr_enable1) ? writeAddress1_dump1 : readAddr_B_dump1 ),
	.data_in( writeData_dump1 ),									
	.we_in(wr_enable1),
	.qB( ramDataOutB[2] ),

	.addrC_in( readAddr_C_dump1 ),
	.qC( ramDataOutC[2] ),

	.addrD_in( readAddr_D_dump1 ),
	.qD( ramDataOutD[2] ),

	.addrA_in( readAddr_A_dump1 ),
	.qA( ramDataOutA[2] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst2(
	.clk( clk ),

	.addrB_in( (wr_enable2) ? writeAddress1_dump2 : readAddr_B_dump2 ),
	.data_in( writeData_dump2 ),									
	.we_in(wr_enable2),
	.qB( ramDataOutB[4] ),

	.addrC_in( readAddr_C_dump2 ),
	.qC( ramDataOutC[4] ),

	.addrD_in( readAddr_D_dump2 ),
	.qD( ramDataOutD[4] ),

	.addrA_in( readAddr_A_dump2 ),
	.qA( ramDataOutA[4] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst3(
	.clk( clk ),

	.addrB_in( (wr_enable3) ? writeAddress1_dump3 : readAddr_B_dump3 ),
	.data_in( writeData_dump3 ),									
	.we_in(wr_enable3),
	.qB( ramDataOutB[8] ),

	.addrC_in( readAddr_C_dump3 ),
	.qC( ramDataOutC[8] ),

	.addrD_in( readAddr_D_dump3 ),
	.qD( ramDataOutD[8] ),

	.addrA_in( readAddr_A_dump3 ),
	.qA( ramDataOutA[8] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst4(
	.clk( clk ),

	.addrB_in( (wr_enable4) ? writeAddress1_dump4 : readAddr_B_dump4 ),
	.data_in( writeData_dump4 ),									
	.we_in(wr_enable4),
	.qB( ramDataOutB[16] ),

	.addrC_in( readAddr_C_dump4 ),
	.qC( ramDataOutC[16] ),

	.addrD_in( readAddr_D_dump4 ),
	.qD( ramDataOutD[16] ),

	.addrA_in( readAddr_A_dump4 ),
	.qA( ramDataOutA[16] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst5(
	.clk( clk ),

	.addrB_in( (wr_enable5) ? writeAddress1_dump5 : readAddr_B_dump5 ),
	.data_in( writeData_dump5 ),									
	.we_in(wr_enable5),
	.qB( ramDataOutB[32] ),
	
	.addrC_in( readAddr_C_dump5 ),
	.qC( ramDataOutC[32] ),

	.addrD_in( readAddr_D_dump5 ),
	.qD( ramDataOutD[32] ),

	.addrA_in( readAddr_A_dump5 ),
	.qA( ramDataOutA[32] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst6(
	.clk( clk ),

	.addrB_in( (wr_enable6) ? writeAddress1_dump6 : readAddr_B_dump6 ),
	.data_in( writeData_dump6 ),									
	.we_in(wr_enable6),
	.qB( ramDataOutB[64] ),

	.addrC_in( readAddr_C_dump6 ),
	.qC( ramDataOutC[64] ),

	.addrD_in( readAddr_D_dump6 ),
	.qD( ramDataOutD[64] ),

	.addrA_in( readAddr_A_dump6 ),
	.qA( ramDataOutA[64] )
);

ramDoublePort #(
	.DATA_WIDTH( DATA_WIDTH ),
	.ADDRESS_WIDTH( ADDRESS_WIDTH )
) ramDoublePort_inst7(
	.clk( clk ),

	.addrB_in( (wr_enable7) ? writeAddress1_dump7 : readAddr_B_dump7 ),
	.data_in( writeData_dump7 ),
	.we_in(wr_enable7),
	.qB( ramDataOutB[128] ),

	.addrC_in( readAddr_C_dump7 ),
	.qC( ramDataOutC[128] ),

	.addrD_in( readAddr_D_dump7 ),
	.qD( ramDataOutD[128] ),

	.addrA_in( readAddr_A_dump7 ),
	.qA( ramDataOutA[128] )
);

//-------------------------------------------------------------
// 缓存RAM数据读取
//-------------------------------------------------------------
/*
	readSelect0   第一行
	readSelect1   第二行
	readSelect2   第三行
	readSelect3   第四行
*/
reg [BUFFER_SIZE-1:0] readSelect1;
reg [BUFFER_SIZE-1:0] readSelect2;
reg [BUFFER_SIZE-1:0] readSelect3;
reg [BUFFER_SIZE-1:0] readSelect0;
//生成相邻四行标识
always@(posedge clk)
begin
	readSelect1 <= readSelect;
	//readSelect2是在readSelect的基础上左移动1位，如果readSelect最高位为1，则1移动到最低位
	readSelect2 <= (readSelect << 1) | readSelect[BUFFER_SIZE-1];
	//readSelect3是在readSelect的基础上左移动2位
	readSelect3 <= (readSelect << 2) | {readSelect[BUFFER_SIZE-1],readSelect[BUFFER_SIZE-2]};
	//readSelect0是在readSelect的基础上右移动1位
	readSelect0 <= (readSelect>>1) | ({readSelect[0],7'd0});
end

reg [BUFFER_SIZE-1:0] readSelect1_reg0,readSelect2_reg0,readSelect3_reg0,readSelect0_reg0;
reg [BUFFER_SIZE-1:0] readSelect1_reg1,readSelect2_reg1,readSelect3_reg1,readSelect0_reg1;
(* keep = "true" *)reg [BUFFER_SIZE-1:0] readSelect1_dump0,readSelect2_dump0,readSelect3_dump0,readSelect0_dump0;
(* keep = "true" *)reg [BUFFER_SIZE-1:0] readSelect1_dump1,readSelect2_dump1,readSelect3_dump1,readSelect0_dump1;
(* keep = "true" *)reg [BUFFER_SIZE-1:0] readSelect1_dump2,readSelect2_dump2,readSelect3_dump2,readSelect0_dump2;
(* keep = "true" *)reg [BUFFER_SIZE-1:0] readSelect1_dump3,readSelect2_dump3,readSelect3_dump3,readSelect0_dump3;

//寄存延时和寄存器逻辑复制
always@(posedge clk)
begin
	readSelect1_reg0 <= readSelect1;
	readSelect2_reg0 <= readSelect2;
	readSelect3_reg0 <= readSelect3;
	readSelect0_reg0 <= readSelect0;
	
	readSelect1_dump0 <= readSelect1_reg0;
	readSelect2_dump0 <= readSelect2_reg0;
	readSelect3_dump0 <= readSelect3_reg0;
	readSelect0_dump0 <= readSelect0_reg0;
	                           
	readSelect1_dump1 <= readSelect1_reg0;
	readSelect2_dump1 <= readSelect2_reg0;
	readSelect3_dump1 <= readSelect3_reg0;
	readSelect0_dump1 <= readSelect0_reg0;
	                           
	readSelect1_dump2 <= readSelect1_reg0;
	readSelect2_dump2 <= readSelect2_reg0;
	readSelect3_dump2 <= readSelect3_reg0;
	readSelect0_dump2 <= readSelect0_reg0;
	                                
	readSelect1_dump3 <= readSelect1_reg0;
	readSelect2_dump3 <= readSelect2_reg0;
	readSelect3_dump3 <= readSelect3_reg0;
	readSelect0_dump3 <= readSelect0_reg0;
end

//选择8行缓存ram中的相邻4行
always@(posedge clk)
begin
	ramDataOutA_0 <= ramDataOutA[1];
	ramDataOutA_1 <= ramDataOutA[2];
	ramDataOutA_2 <= ramDataOutA[4];
	ramDataOutA_3 <= ramDataOutA[8];
	ramDataOutA_4 <= ramDataOutA[16];
	ramDataOutA_5 <= ramDataOutA[32];
	ramDataOutA_6 <= ramDataOutA[64];
	ramDataOutA_7 <= ramDataOutA[128];
	ramDataOutB_0 <= ramDataOutB[1];
	ramDataOutB_1 <= ramDataOutB[2];
	ramDataOutB_2 <= ramDataOutB[4];
	ramDataOutB_3 <= ramDataOutB[8];
	ramDataOutB_4 <= ramDataOutB[16];
	ramDataOutB_5 <= ramDataOutB[32];
	ramDataOutB_6 <= ramDataOutB[64];
	ramDataOutB_7 <= ramDataOutB[128];
	ramDataOutC_0 <= ramDataOutC[1];
	ramDataOutC_1 <= ramDataOutC[2];
	ramDataOutC_2 <= ramDataOutC[4];
	ramDataOutC_3 <= ramDataOutC[8];
	ramDataOutC_4 <= ramDataOutC[16];
	ramDataOutC_5 <= ramDataOutC[32];
	ramDataOutC_6 <= ramDataOutC[64];
	ramDataOutC_7 <= ramDataOutC[128];
	ramDataOutD_0 <= ramDataOutD[1];
	ramDataOutD_1 <= ramDataOutD[2];
	ramDataOutD_2 <= ramDataOutD[4];
	ramDataOutD_3 <= ramDataOutD[8];
	ramDataOutD_4 <= ramDataOutD[16];
	ramDataOutD_5 <= ramDataOutD[32];
	ramDataOutD_6 <= ramDataOutD[64];
	ramDataOutD_7 <= ramDataOutD[128];
end

//选取缓存数据
always@(posedge clk)
begin
	case (readSelect0_dump0) 
		8'd1: begin
			readData00_reg <= ramDataOutA_0;
		end
		8'd2:begin
			readData00_reg <= ramDataOutA_1;
		end			
		8'd4:begin
			readData00_reg <= ramDataOutA_2;
		end			
		8'd8:begin
			readData00_reg <= ramDataOutA_3;
		end	
		8'd16:begin
			readData00_reg <= ramDataOutA_4;
		end		
		8'd32:begin
			readData00_reg <= ramDataOutA_5;
		end		
		8'd64:begin
			readData00_reg <= ramDataOutA_6;
		end
		8'd128:begin
			readData00_reg <= ramDataOutA_7;
		end
		default: ;
	endcase
	case (readSelect0_dump1) 
		8'd1: begin
			readData01_reg <= ramDataOutB_0;
		end
		8'd2:begin
			readData01_reg <= ramDataOutB_1;
		end			
		8'd4:begin
			readData01_reg <= ramDataOutB_2;
		end			
		8'd8:begin
			readData01_reg <= ramDataOutB_3;
		end	
		8'd16:begin
			readData01_reg <= ramDataOutB_4;
		end		
		8'd32:begin
			readData01_reg <= ramDataOutB_5;
		end		
		8'd64:begin
			readData01_reg <= ramDataOutB_6;
		end
		8'd128:begin
			readData01_reg <= ramDataOutB_7;
		end
		default: ;
	endcase
	case (readSelect0_dump2)
		8'd1: begin
			readData02_reg <= ramDataOutC_0;
		end
		8'd2:begin
			readData02_reg <= ramDataOutC_1;
		end			
		8'd4:begin
			readData02_reg <= ramDataOutC_2;
		end			
		8'd8:begin
			readData02_reg <= ramDataOutC_3;
		end	
		8'd16:begin
			readData02_reg <= ramDataOutC_4;
		end		
		8'd32:begin
			readData02_reg <= ramDataOutC_5;
		end		
		8'd64:begin
			readData02_reg <= ramDataOutC_6;
		end
		8'd128:begin
			readData02_reg <= ramDataOutC_7;
		end
		default: ;
	endcase
	case (readSelect0_dump3)
		8'd1: begin
			readData03_reg <= ramDataOutD_0;
		end
		8'd2:begin
			readData03_reg <= ramDataOutD_1;
		end			
		8'd4:begin
			readData03_reg <= ramDataOutD_2;
		end			
		8'd8:begin
			readData03_reg <= ramDataOutD_3;
		end	
		8'd16:begin
			readData03_reg <= ramDataOutD_4;
		end		
		8'd32:begin
			readData03_reg <= ramDataOutD_5;
		end		
		8'd64:begin
			readData03_reg <= ramDataOutD_6;
		end
		8'd128:begin
			readData03_reg <= ramDataOutD_7;
		end
		default: ;
	endcase
end

always@(posedge clk)
begin
	case (readSelect1_dump0) 
		8'd1: begin
			readData10_reg <= ramDataOutA_0;
		end
		8'd2:begin
			readData10_reg <= ramDataOutA_1;
		end			
		8'd4:begin
			readData10_reg <= ramDataOutA_2;
		end			
		8'd8:begin
			readData10_reg <= ramDataOutA_3;
		end		
		8'd16:begin
			readData10_reg <= ramDataOutA_4;
		end		
		8'd32:begin
			readData10_reg <= ramDataOutA_5;
		end		
		8'd64:begin
			readData10_reg <= ramDataOutA_6;
		end
		8'd128:begin
			readData10_reg <= ramDataOutA_7;
		end
		default: ;
	endcase
	case (readSelect1_dump1) 
		8'd1: begin
			readData11_reg <= ramDataOutB_0;
		end
		8'd2:begin
			readData11_reg <= ramDataOutB_1;
		end			
		8'd4:begin
			readData11_reg <= ramDataOutB_2;
		end			
		8'd8:begin
			readData11_reg <= ramDataOutB_3;
		end		
		8'd16:begin
			readData11_reg <= ramDataOutB_4;
		end		
		8'd32:begin
			readData11_reg <= ramDataOutB_5;
		end		
		8'd64:begin
			readData11_reg <= ramDataOutB_6;
		end
		8'd128:begin
			readData11_reg <= ramDataOutB_7;
		end
		default: ;
	endcase
	case (readSelect1_dump2) 
		8'd1: begin
			readData12_reg <= ramDataOutC_0;
		end
		8'd2:begin
			readData12_reg <= ramDataOutC_1;
		end			
		8'd4:begin
			readData12_reg <= ramDataOutC_2;
		end			
		8'd8:begin
			readData12_reg <= ramDataOutC_3;
		end		
		8'd16:begin
			readData12_reg <= ramDataOutC_4;
		end		
		8'd32:begin
			readData12_reg <= ramDataOutC_5;
		end		
		8'd64:begin
			readData12_reg <= ramDataOutC_6;
		end
		8'd128:begin
			readData12_reg <= ramDataOutC_7;
		end
		default: ;
	endcase
	case (readSelect1_dump3) 
		8'd1: begin
			readData13_reg <= ramDataOutD_0;
		end
		8'd2:begin
			readData13_reg <= ramDataOutD_1;
		end			
		8'd4:begin
			readData13_reg <= ramDataOutD_2;
		end			
		8'd8:begin
			readData13_reg <= ramDataOutD_3;
		end		
		8'd16:begin
			readData13_reg <= ramDataOutD_4;
		end		
		8'd32:begin
			readData13_reg <= ramDataOutD_5;
		end		
		8'd64:begin
			readData13_reg <= ramDataOutD_6;
		end
		8'd128:begin
			readData13_reg <= ramDataOutD_7;
		end
		default: ;
	endcase
end

always@(posedge clk)
begin
	case (readSelect2_dump0) 
		8'd1: begin
			readData20_reg <= ramDataOutA_0;
		end
		8'd2:begin
			readData20_reg <= ramDataOutA_1;
		end			
		8'd4:begin
			readData20_reg <= ramDataOutA_2;
		end			
		8'd8:begin
			readData20_reg <= ramDataOutA_3;
		end		
		8'd16:begin
			readData20_reg <= ramDataOutA_4;
		end		
		8'd32:begin
			readData20_reg <= ramDataOutA_5;
		end		
		8'd64:begin
			readData20_reg <= ramDataOutA_6;
		end
		8'd128:begin
			readData20_reg <= ramDataOutA_7;
		end
		default: ;
	endcase
	case (readSelect2_dump1) 
		8'd1: begin
			readData21_reg <= ramDataOutB_0;
		end
		8'd2:begin
			readData21_reg <= ramDataOutB_1;
		end			
		8'd4:begin
			readData21_reg <= ramDataOutB_2;
		end			
		8'd8:begin
			readData21_reg <= ramDataOutB_3;
		end		
		8'd16:begin
			readData21_reg <= ramDataOutB_4;
		end		
		8'd32:begin
			readData21_reg <= ramDataOutB_5;
		end		
		8'd64:begin
			readData21_reg <= ramDataOutB_6;
		end
		8'd128:begin
			readData21_reg <= ramDataOutB_7;
		end
		default: ;
	endcase
	case (readSelect2_dump2) 
		8'd1: begin
			readData22_reg <= ramDataOutC_0;
		end
		8'd2:begin
			readData22_reg <= ramDataOutC_1;
		end			
		8'd4:begin
			readData22_reg <= ramDataOutC_2;
		end			
		8'd8:begin
			readData22_reg <= ramDataOutC_3;
		end		
		8'd16:begin
			readData22_reg <= ramDataOutC_4;
		end		
		8'd32:begin
			readData22_reg <= ramDataOutC_5;
		end		
		8'd64:begin
			readData22_reg <= ramDataOutC_6;
		end
		8'd128:begin
			readData22_reg <= ramDataOutC_7;
		end
		default: ;
	endcase
	case (readSelect2_dump3) 
		8'd1: begin
			readData23_reg <= ramDataOutD_0;
		end
		8'd2:begin
			readData23_reg <= ramDataOutD_1;
		end			
		8'd4:begin
			readData23_reg <= ramDataOutD_2;
		end			
		8'd8:begin
			readData23_reg <= ramDataOutD_3;
		end		
		8'd16:begin
			readData23_reg <= ramDataOutD_4;
		end		
		8'd32:begin
			readData23_reg <= ramDataOutD_5;
		end		
		8'd64:begin
			readData23_reg <= ramDataOutD_6;
		end
		8'd128:begin
			readData23_reg <= ramDataOutD_7;
		end
		default: ;
	endcase
end

always@(posedge clk)
begin
	case (readSelect3_dump0) 
		8'd1: begin
			readData30_reg <= ramDataOutA_0;
		end
		8'd2:begin
			readData30_reg <= ramDataOutA_1;
		end			
		8'd4:begin
			readData30_reg <= ramDataOutA_2;
		end			
		8'd8:begin
			readData30_reg <= ramDataOutA_3;
		end		
		8'd16:begin
			readData30_reg <= ramDataOutA_4;
		end		
		8'd32:begin
			readData30_reg <= ramDataOutA_5;
		end		
		8'd64:begin
			readData30_reg <= ramDataOutA_6;
		end
		8'd128:begin
			readData30_reg <= ramDataOutA_7;
		end
		default: ;
	endcase
	case (readSelect3_dump1) 
		8'd1: begin
			readData31_reg <= ramDataOutB_0;
		end
		8'd2:begin
			readData31_reg <= ramDataOutB_1;
		end			
		8'd4:begin
			readData31_reg <= ramDataOutB_2;
		end			
		8'd8:begin
			readData31_reg <= ramDataOutB_3;
		end		
		8'd16:begin
			readData31_reg <= ramDataOutB_4;
		end		
		8'd32:begin
			readData31_reg <= ramDataOutB_5;
		end		
		8'd64:begin
			readData31_reg <= ramDataOutB_6;
		end
		8'd128:begin
			readData31_reg <= ramDataOutB_7;
		end
		default: ;
	endcase
	case (readSelect3_dump2) 
		8'd1: begin
			readData32_reg <= ramDataOutC_0;
		end
		8'd2:begin
			readData32_reg <= ramDataOutC_1;
		end			
		8'd4:begin
			readData32_reg <= ramDataOutC_2;
		end			
		8'd8:begin
			readData32_reg <= ramDataOutC_3;
		end		
		8'd16:begin
			readData32_reg <= ramDataOutC_4;
		end		
		8'd32:begin
			readData32_reg <= ramDataOutC_5;
		end		
		8'd64:begin
			readData32_reg <= ramDataOutC_6;
		end
		8'd128:begin
			readData32_reg <= ramDataOutC_7;
		end
		default: ;
	endcase
	case (readSelect3_dump3) 
		8'd1: begin
			readData33_reg <= ramDataOutD_0;
		end
		8'd2:begin
			readData33_reg <= ramDataOutD_1;
		end			
		8'd4:begin
			readData33_reg <= ramDataOutD_2;
		end			
		8'd8:begin
			readData33_reg <= ramDataOutD_3;
		end		
		8'd16:begin
			readData33_reg <= ramDataOutD_4;
		end		
		8'd32:begin
			readData33_reg <= ramDataOutD_5;
		end		
		8'd64:begin
			readData33_reg <= ramDataOutD_6;
		end
		8'd128:begin
			readData33_reg <= ramDataOutD_7;
		end
		default: ;
	endcase
end

//寄存延时
always@(posedge clk)
begin
	readData00_reg_0 <= readData00_reg;
	readData01_reg_0 <= readData01_reg;
	readData02_reg_0 <= readData02_reg;
	readData03_reg_0 <= readData03_reg;
	readData10_reg_0 <= readData10_reg;
	readData11_reg_0 <= readData11_reg;
	readData12_reg_0 <= readData12_reg;
	readData13_reg_0 <= readData13_reg;
	readData20_reg_0 <= readData20_reg;
	readData21_reg_0 <= readData21_reg;
	readData22_reg_0 <= readData22_reg;
	readData23_reg_0 <= readData23_reg;
	readData30_reg_0 <= readData30_reg;
	readData31_reg_0 <= readData31_reg;
	readData32_reg_0 <= readData32_reg;
	readData33_reg_0 <= readData33_reg;
end

//最终16点像素数据输出
always@(posedge clk)
begin
	/* if(First_Outputline == 0) begin
		readData00 <= readData00_reg_0;
		readData01 <= readData01_reg_0;
		readData02 <= readData02_reg_0;
		readData03 <= readData03_reg_0;
		readData10 <= readData00_reg_0;
		readData11 <= readData01_reg_0;
		readData12 <= readData02_reg_0;
		readData13 <= readData03_reg_0;
		readData20 <= readData20_reg_0;
		readData21 <= readData21_reg_0;
		readData22 <= readData22_reg_0;
		readData23 <= readData23_reg_0;
		readData30 <= readData30_reg_0;
		readData31 <= readData31_reg_0;
		readData32 <= readData32_reg_0;
		readData33 <= readData33_reg_0;
	end
	else if(Last_Outputline == 1) begin
		readData00 <= readData00_reg_0;
		readData01 <= readData01_reg_0;
		readData02 <= readData02_reg_0;
		readData03 <= readData03_reg_0;
		readData10 <= readData30_reg_0;
		readData11 <= readData31_reg_0;
		readData12 <= readData32_reg_0;
		readData13 <= readData33_reg_0;
		readData20 <= readData30_reg_0;
		readData21 <= readData31_reg_0;
		readData22 <= readData32_reg_0;
		readData23 <= readData33_reg_0;
		readData30 <= readData30_reg_0;
		readData31 <= readData31_reg_0;
		readData32 <= readData32_reg_0;
		readData33 <= readData33_reg_0;
	end
	else  */begin
		readData00 <= readData00_reg_0;
		readData01 <= readData01_reg_0;
		readData02 <= readData02_reg_0;
		readData03 <= readData03_reg_0;
		readData10 <= readData10_reg_0;
		readData11 <= readData11_reg_0;
		readData12 <= readData12_reg_0;
		readData13 <= readData13_reg_0;
		readData20 <= readData20_reg_0;
		readData21 <= readData21_reg_0;
		readData22 <= readData22_reg_0;
		readData23 <= readData23_reg_0;
		readData30 <= readData30_reg_0;
		readData31 <= readData31_reg_0;
		readData32 <= readData32_reg_0;
		readData33 <= readData33_reg_0;
	end
end

endmodule