#
#  Simulation macro file for Homework #9, Problem #2 - RLL Encoder
#  EE 119a
#
#  Glen George
#
#  Revision History
#      4/12/00   Initial revision
#      4/16/02   Updated comments
#      4/18/04   Updated comments
#     11/21/05   Updated comments
#
#
# compile the solution source code, probably will need to change filename
vcom "$DSN\src\rllenc.vhd"
# compile the testbench
vcom "$DSN\src\TestBench\RLLEncoder_TB.vhd" 
# simulate the testbench (TESTBENCH_FOR_RLLEncoder)
vsim rllencoder_tb 
# setup the waveform display for the simulation
wave  
wave CLK
wave Reset
wave DataIn
wave RLLOut
# run the actual simulation
run 21.9 us
