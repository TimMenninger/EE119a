#
#  Simulation macro file for Homework #8, Problem #1 - BCD to Binary Converter
#  EE 119a
#
#  Glen George
#
#  Revision History
#      4/2/00    Initial revision
#      4/6/04    Updated comments
#     11/20/05   Updated comments
#     11/22/07   Updated comments
#
#
# compile the two files that are the solution VHDL files
# the names will need to be changed to the names of your files
vcom "$DSN\src\adder.vhd"
vcom "$DSN\src\BCD2Bin.vhd"
# compile the test bench
vcom "$DSN\src\TestBench\BCD2Binary8_TB.vhd"
# simulate the testbench (TESTBENCH_FOR_BCD2Binary8)
vsim TESTBENCH_FOR_BCD2Binary8
# signals to display in the simulation
wave
wave BCD
wave B
# run the simulation
run 3000. ns
