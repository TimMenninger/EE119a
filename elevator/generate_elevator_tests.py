# General imported things
import math
from sys import argv

# Module with generic functions to write test vectors to files
from test_vectors import *
from floor_patterns import *

###############################################################################
#
# Implemented to generate the test vectors for the respective ABEL file
#
#

#
# generate_test_vectors
#
# Generates test vectors for the elevator part of HW5 for EE119a.  It will
# test as if the elevator moves up and down, and should show the display change
# at each new "floor".
#
# Arguments: openfile (file) - The file to write test vectors to.
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def generate_test_vectors(openfile):
    '''
    Defines all of the test vectors and comments that will go into the file.
    '''

    # Create the test vector header
    inputs  = ['FastClk', 'In0', 'In1', 'In2', 'In3', 'In4', 'Chg']
    outputs = ['Out0', 'Out1', 'Out2', 'Out3', 'Out4']
    print_test_header(openfile, inputs, outputs)

    # Do the tests as if we're on an elevator.  WLOG, we can stay on each floor
    # for only a few clocks, and assume that if this is right for several
    # consecutive identical inputs, it is also right for millions.
    mux_row = 0 # Starting at first row
    arrays = [ subbasement, basement, floor1, floor2, floor3, floor4 ]

    # Start on floor 1 to show that this can detect when it starts on the first
    # floor.  Then when it leaves and comes back to floor 1, it will be the
    # same as if it had started on a different floor.  We will go up to fourth
    # floor and stay at each floor for several clocks.  Then we will go down
    # to subbasement, back up to fourth floor and back to ground, finishing
    # there.  The order here shows the ground both starting on the second
    # row (first known row, so it displays ground after one clock) and not
    # so it spends some time before knowing it's on the ground floor
    print_comment(openfile,
        'We will start at the ground floor, then move up to floor 4, down to '
      + 'subbasement, up to floor 3, then back to ground.  This will test '
      + 'starting on ground with the mux row NOT a known row, moving to ground '
      + 'from an unknown/searching state, and moving to ground while on a '
      + 'row known to be ground (so it should change immediately).'
    )
    floor_order = [ 2, 3, 4, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 4, 3, 2 ]
    floor_names = [ 'subbasement',
                    'basement',
                    'ground floor',
                    'floor 2',
                    'floor 3',
                    'floor 4' ]
    chg = True
    for f in floor_order:
        print_comment(openfile,
            'Moving to ' + floor_names[f]
        )
        mux_row, chg = on_floor(openfile, arrays[f], mux_row, 60, 3, chg)

    print_comment(openfile,
        'Note that all possible state encodings have a state definition, so '
      + 'we do not need to check or test for invalid states.  Also note that '
      + 'we simply relay the input unless we are in a known state, so there '
      + 'is no such thing as an invalid input.'
    )

    return

###############################################################################
#
# Helper functions for generating test vectors
#
#

#
# on_floor
#
# Generates test vectors as if it is on the floor designated by the light_array
# argument.  It will start on the argued mux_row, and every clocks_per_row,
# it will go on to print a test vector for the next row.  This will run for
# num_clocks iterations.  This will alternate the value of chg between 0 and 1
# on each new row.  It assumes that the argued file is open and ready to be
# written to.  This runs for ceil(num_clocks / clocks_per_row) * clocks_per_row
# iterations so as to not mess up the chg input.
#
# Arguments: openfile (file) - The file to write test vectors to
#            light_array ([[int]]) - Designates the light patterns for each row
#               where each value is a 0 or a 1
#            mux_row (int) - The row to start on
#            num_clocks (int) - The number of clocks to run for
#            clocks_per_row (int) - The number of clocks spent displaying each
#               row
#            chg (bool) - The beginning value of chg (this is alternated
#               immediately)
# Returns:   mux_row (int) - The ending row being displayed
#            chg (bool) - The ending value of chg
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def on_floor(openfile, light_array, mux_row, num_clocks, clocks_per_row, chg):
    '''
    Simulates the elevator being on a particular floor (designated by the light
    array) for some number of clocks.  Outputs which row of mux it is on.
    The number of clocks per row determines at what frequency to change the
    row.  This will run for ceil(num_clocks / clocks_per_row) * clocks_per_row
    iterations.  If we are on the first floor, then we will detect that when
    the mux is on row 2.  At that point, we will begin displaying the ground
    symbol on the second clock at row 2.
    '''
    # Different case if on ground floor
    on_floor_1 = False
    if (light_array == floor1):
        on_floor_1 = True

    # Light array out is initially the same as the input array
    light_array_out = light_array

    num_clocks = math.ceil(num_clocks / clocks_per_row) * clocks_per_row
    # Counts clocks since last row change
    clocks = 0

    # Display rows for as long as arguments specify
    for i in range(num_clocks):
        # If on floor 1 and we recognize that, output array is now ground
        if (on_floor_1 and mux_row == 1):
            light_array_out = ground

        # Row has changed when clocks since last row change is 0
        if (clocks == 0):
            chg = not chg

        # Define left and right sides of test vector
        inputs = ['.C.'] + light_array[mux_row] + [ int(chg) ]
        outputs = light_array_out[mux_row]
        print_test_vector(openfile, inputs, outputs)

        # Update mux row and clocks since row change
        clocks = (clocks + 1) % clocks_per_row
        mux_row += (clocks == 0)
        mux_row %= 7 # 7 rows in 5x7 display

    return mux_row, chg

###############################################################################
#
# Main loop for generating test vectors
#
#

if __name__ == '__main__':
    if (len(argv) != 2):
        print ('usage: python remove_test_vectors.py [filename]')
    # Insert test vectors into file
    insert_test_vectors(argv[1], generate_test_vectors)
