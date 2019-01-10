# FPGA-Bicubic-interpolation
refer https://github.com/freecores/video_stream_scaler

use Verilog HDL implemented Bicubic interpolation.
I had tested on Intel/Altera(EP4CE55F23C8) and Xilinx(xc7a100tfgg484-2) FPGA.

Up to now, FMAX = 165MHz  (tested in xilinx xc7a100tfgg484-2 and used DDR3 SDRAM).

In my test, the bicubic-interpolation core could receive input 1920x1080@60Hz video stream and output 1600x1200@60Hz video stream.In theory, interpolation core could receive and output any video resolution that pixel frequency no more than FMAX.

But as we know, design an efficient write&read module between bicubic-interpolation core and DDR SDRAM adapt to high speed data reading and writing is important.

In my design, The module is divided into two main parts, one is bicubic-interpolation, another is data cache.Diagram of bicubic-interpolation module is as follows:

In bicubic-interpolation module, parallel computing is the most important part.So the design need to make the best use of multipliers, deepening pipeline and exchange skew for FMAX.

Diagram of data cache module is as follows:

In data cache module, i used 8 2048x24bit RAMs to control data writing and reading.The number 8 is for bicubic interpolation and 2048 is for the maximum number of pixels per row.

|  module            |  function     |
| --------           |   :----:      |
| video_scaler.v     |  main module  |
| source_to_scaler.v | input data-stream clock domain cross to scaler clock domain |
| scaler_to_ddr.v    | scaler clock domain cross to DDR clock domain   |
| others             | use for data cache and interpolation calculation            |
