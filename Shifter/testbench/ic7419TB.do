#
#  Simulation macro file for Homework #8, Problem #2 - 74194 shift register
#  EE 119a
#
#  Glen George
#
#  Revision History
#      4/4/00    Initial revision
#      4/6/04    Updated comments
#     11/20/05   Updated comments
#     11/22/07   Updated comments
#
#
# this compiles the file with the VHDL for the solution
# the filename will probably need to be changed
vcom "$DSN\src\ic74194.vhd"
# this compiles the testbench
vcom "$DSN\src\TestBench\ic74194_TB.vhd"
# simulate the testbench (TESTBENCH_FOR_ic74194)
vsim TESTBENCH_FOR_ic74194
# signals to display in the simulation
wave
wave DI
wave LSI
wave RSI
wave S
wave CLR
wave CLK
wave DO
# run the simulation
run 1.7 us
