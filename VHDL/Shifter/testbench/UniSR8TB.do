#
#  Simulation macro file for Homework #8, Problem #2
#                                              8-Bit Universal Shift Register
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
# the filename will need to be changed to match the name of your file
vcom "$DSN\src\UnivSR8.vhd"
# compile the testbench
vcom "$DSN\src\TestBench\UniversalSR8_TB.vhd"
# simulate the testbench (TESTBENCH_FOR_UniversalSR8)
vsim TESTBENCH_FOR_UniversalSR8
# signals to display in the simulation
wave
wave D
wave LSer
wave RSer
wave Mode
wave CLR
wave CLK
wave Q
# run the simulation
run 13.6 us
