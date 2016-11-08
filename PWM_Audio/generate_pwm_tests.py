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
    return

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
