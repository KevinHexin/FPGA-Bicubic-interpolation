/*
	testbench for video_scaler
*/
`timescale 1ns/1ns

//Input file. 24bit-BMP data format, 54bit header. 8 bits per pixel, 3 color channels.
`define INPUT_PIC			"pure_color.bmp"
//Output file. Raw data format, no header. 8 bits per pixel, 3 color channels.
`define OUTPUT_PIC			"output640x480to1024x768BiCubic.raw"

module video_scaler_tb;

wire  done;

scalerTest #(
	.INPUT_X_RES ( 640-1 ),
	.INPUT_Y_RES ( 480-1 ),
	.OUTPUT_X_RES ( 1024-1 ),       //Output resolution - 1
	.OUTPUT_Y_RES ( 768-1 ),        //Output resolution - 1

	.CHANNELS (3),
	.DATA_WIDTH ( 8 ),
	.DISCARD_CNT_WIDTH ( 8 ),
	.INPUT_X_RES_WIDTH ( 11 ),
	.INPUT_Y_RES_WIDTH ( 11 ),
	.OUTPUT_X_RES_WIDTH ( 11 ),
	.OUTPUT_Y_RES_WIDTH ( 11 ),
	.BUFFER_SIZE ( 8 )				//Number of RAMs in RAM ring buffer
	) scalerTest_inst (
	.inputFilename( `INPUT_PIC ),
	.outputFilename( `OUTPUT_PIC ),

	//Control
	.inputDiscardCnt( 18 ),		   //Number of input pixels to discard before processing data. Used for clipping
	.leftOffset( 0 ),
	.topFracOffset( 0 ),
	.done ( done )
);
	
initial
begin
	#10
	while(done != 1'b1)
		#10
		;
	$stop;
end
 
endmodule


module scalerTest #(
	parameter INPUT_X_RES = 640-1,
	parameter INPUT_Y_RES = 480-1,
	parameter OUTPUT_X_RES = 640-1,         //Output resolution - 1
	parameter OUTPUT_Y_RES = 480-1,         //Output resolution - 1
	parameter X_SCALE = 32'h4000 * (INPUT_X_RES) / (OUTPUT_X_RES)-1,
	parameter Y_SCALE = 32'h4000 * (INPUT_Y_RES) / (OUTPUT_Y_RES)-1,
	
	parameter DATA_WIDTH = 8,
	parameter CHANNELS = 3,
	parameter DISCARD_CNT_WIDTH = 8,
	parameter INPUT_X_RES_WIDTH = 11,
	parameter INPUT_Y_RES_WIDTH = 11,
	parameter OUTPUT_X_RES_WIDTH = 11,
	parameter OUTPUT_Y_RES_WIDTH = 11,
	parameter BUFFER_SIZE = 8				//Number of RAMs in RAM ring buffer
)(
input wire [50*8:0] inputFilename, outputFilename,

//Control
input wire [DISCARD_CNT_WIDTH-1:0]	inputDiscardCnt,
input wire [INPUT_X_RES_WIDTH+14-1:0] leftOffset,
input wire [14-1:0]	topFracOffset,

output reg done
);


reg clk;
reg rst_n;

//3*8=24bit
reg [DATA_WIDTH*CHANNELS-1:0] dIn;
reg		dInValid;
wire	nextDin;
reg		start;

//3*8=24bit
wire [DATA_WIDTH*CHANNELS-1:0] dOut;
wire	dOutValid;
reg		nextDout;

integer r, rfile, wfile;

initial   // Clock generator  100MHz
  begin
    #10   //Delay to allow filename to get here
    clk = 0;
    #5 forever #5 clk = !clk;
  end

initial	// Reset
  begin
	done = 0;
    #10 //Delay to allow filename to get here
    rst_n = 0;
    #20 rst_n = 1;
    #20 rst_n = 0;
   // #50000 $stop;
  end

reg eof;
//3*8=24bit
reg [DATA_WIDTH*CHANNELS-1:0] readMem [0:0];
initial                // Input file read, generates dIn data
begin
  #10                  //Delay to allow filename to get here
	rfile = $fopen(inputFilename, "rb");
	
	dIn = 0;
	dInValid = 0;

	#10
	start = 0;

	#80
	r = $fread(readMem, rfile);
	dIn = readMem[0];
	
	while(! $feof(rfile))
	begin
		dInValid = 1;
		
		#10          //After dInValid signal be vaild one cycle,data transfer begin.
		if(nextDin)  //if the buffer RAMs in scaler module is not full yet.
		begin
			r = $fread(readMem, rfile);
			dIn = readMem[0];    //Write 24bit data every clock cycle.
		end
	end

  $fclose(rfile);
end

//Generate nextDout request signal
initial
begin
  #10 //Delay to match filename arrival delay
	nextDout = 0;
	#140000
	forever
	begin
		#(10*(OUTPUT_X_RES+1))
		nextDout = 1;
		
	end
end

//Read dOut and write to file
integer dOutCount;
initial
begin
  #10 //Delay to allow filename to get here
	wfile = $fopen(outputFilename, "wb");
	nextDout = 0;
	dOutCount = 0;
	while(dOutCount < (OUTPUT_X_RES+1) * (OUTPUT_Y_RES+1))
	begin
		#10
		if(dOutValid == 1)
		begin
			$fwrite(wfile, "%c", dOut[23:16]);   //R
			$fwrite(wfile, "%c", dOut[15:8]);    //G
			$fwrite(wfile, "%c", dOut[7:0]);     //B
			dOutCount = dOutCount + 1;
		end
	end
	$fclose(wfile);
	done = 1;
end

reg [23:0] dIn_0;
reg dInValid_0;
always@(posedge clk)
begin
	dIn_0 <= dIn;
	dInValid_0 <= dInValid;
end

video_scaler video_scaler_inst(
.clk( clk ),                                //100MHz
.rst( rst_n ),

.dIn( dIn_0 ),
.dInValid( dInValid_0 ),
.din_Enable( nextDin ),
.start( start ),

.scaler_done(),

.dOut( dOut ),
.dOutValid( dOutValid ),
.dout_Enable( nextDout ),

//Control
.inputDiscardCnt( inputDiscardCnt ),		//Number of input pixels to discard before processing data. Used for clipping
.inputXRes( INPUT_X_RES ),				    //Input data number of pixels per line
.inputYRes( INPUT_Y_RES ),

.outputXRes( OUTPUT_X_RES ),				//Resolution of output data
.outputYRes( OUTPUT_Y_RES ),
.xScale( X_SCALE ),					        //Scaling factors. Input resolution scaled by 1/xScale. Format Q4.14
.yScale( Y_SCALE ),					        //Scaling factors. Input resolution scaled by 1/yScale. Format Q4.14

.leftOffset( leftOffset ),
.topFracOffset( topFracOffset )
);

endmodule