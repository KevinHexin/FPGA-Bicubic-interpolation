# FPGA-Bicubic-interpolation
refer https://github.com/freecores/video_stream_scaler

use Verilog HDL implemented Bicubic interpolation.
I had test on Intel/Altera(EP4CE55F23C8) and Xilinx(xc7a100tfgg484-2) FPGA.

Up to now, FMAX = 165MHz (test in xilinx xc7a100tfgg484-2 and use DDR3 SDRAM).

In my test, the bicubic-interpolation core could receive input 1920x1080@60Hz video stream and output 1600x1200@60Hz video stream.But as we know, you need design an efficient write&read module between bicubic-interpolation core and DDR SDRAM adapt to high speed data reading and writing.

In my design, The module is divided into two main parts, one is bicubic-interpolation, another is data cache.Diagram is as follows:

In bicubic-interpolation module, parallel computing is the most important part.So the design need to make the best use of multipliers, deepening pipeline and exchange skew for FMAX.

In data cache module, i used 8 2048x24bit RAMs to control data writing and reading.The number 8 is for bicubic interpolation and 2048 is for the maximum number of pixels per row.
