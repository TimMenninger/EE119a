from sys import argv
from test_vectors import *

#
# generate_test_vectors
#
# Generates test vectors for audio PWM.
#
# Arguments: openfile (file) - The file to write test vectors to
# Returns:   Nothing.
#
# Revisions: 11/08/16 - Tim Menninger: Created
#
def generate_test_vectors(openfile):
    '''
    Defines the test vectors to test audio PWM.
    '''
    # The header contains inputs and outputs of our test vectors
    inputs  = ['CLK32', 'SW1', 'SW2', 'SW3', 'SW4',
               'AudioData7', 'AudioData6', 'AudioData5', 'AudioData4',
               'AudioData3', 'AudioData2', 'AudioData1', 'AudioData0' ]
    outputs = ['AudioPWMOut', 'Run', 'PWMCycle', 'AddrInc',
               'AddrClock3', 'AddrClock2', 'AddrClock1', 'AddrClock0',
               'PWMCount7', 'PWMCount6', 'PWMCount5', 'PWMCount4',
               'PWMCount3', 'PWMCount2', 'PWMCount1', 'PWMCount0',
               'DataBit7', 'DataBit6', 'DataBit5', 'DataBit4',
               'DataBit3', 'DataBit2', 'DataBit1', 'DataBit0',
                              'AudioAddr18', 'AudioAddr17', 'AudioAddr16',
               'AudioAddr15', 'AudioAddr14', 'AudioAddr13', 'AudioAddr12',
               'AudioAddr11', 'AudioAddr10', 'AudioAddr9',  'AudioAddr8',
               'AudioAddr7',  'AudioAddr6',  'AudioAddr5',  'AudioAddr4',
               'AudioAddr3',  'AudioAddr2',  'AudioAddr1',  'AudioAddr0']
    print_test_header(openfile, inputs, outputs)

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
