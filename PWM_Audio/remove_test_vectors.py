from test_vectors import *
from sys import argv

#
# remove_test_vectors
#
# Takes a filename and removes all test vectors from it.  This file assumes
# that test vectors are prefaced by a line starting with "TEST_VECTORS" (case
# insensitive), and that there is nothing useful after it except for an
# "END" statement (the line must begin with "END")
#
# Arguments: filename (file) - The name of the file (relative path) to remove
#               test vectors from
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def remove_test_vectors(filename):
    '''
    Removes test vectors from a file.
    '''
    # Copy the files over
    filename, copyfilename = copy_file(filename)

    # Open the files to copy over
    f = open(filename, 'w')
    f_copy = open(copyfilename, 'r')

    # Copy everything over except the test vectors
    line = f_copy.readline()
    while (line != ''):
        # Skip test vectors
        if line[:12].upper() == 'TEST_VECTORS':
            while (line[:4].upper() != 'END ' and line != ''):
                line = f_copy.readline()

        # Write the line to the new file
        f.write(line)

        # Advance iteration
        line = f_copy.readline()

    # Done, close files
    f.close()
    f_copy.close()

    # Delete the copy
    copypath = os.path.realpath(__file__)
    copypath = '/'.join(copypath.split('/')[:-1])
    os.remove(os.path.join(copypath, copyfilename))

if __name__ == '__main__':
    if (len(argv) < 2):
        print ('usage: python remove_test_vectors.py [filename1] ...')
    # Delete the test vectors
    for i in range(1, len(argv)):
        remove_test_vectors(argv[i])
