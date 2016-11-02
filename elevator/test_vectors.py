import copy

###############################################################################
#
# Code used by any ABEL file using this
#
#

def print_comment(openfile, comment):
    '''
    Formats and prints a comment in the file, breaking it up into lines no
    longer than 150 characters.
    '''
    words = comment.split()
    # Comment begins with one double quote, and a space separating it form the
    # comment itself.  Also start with whitespace before the comment.
    line = '\n" '
    num_characters = 0
    # Print each word into the file.
    for word in words:
        # Flush the buffer if it is too long
        if len(line) + len(word) > 150:
            openfile.write(line + '\n')
            line = '" '

        # Add the next word to the buffer
        line += word + " "

    # Flush the last line
    openfile.write(line + '\n')

def print_test_header(openfile, inputs, outputs):
    '''
    Prints the test vector header that defines the order of the signals in each
    test vector.
    '''
    header = 'TEST_VECTORS\n'
    header += '(['
    for i in inputs:
        header += str(i) + ','
    # Remove last comma and put arrow to next list
    header = header[:-1] + ']->['

    # Put all Out signals
    for i in outputs:
        header += str(i) + ','
    # Remove last comma and finish line
    header = header[:-1] + '])\n'

    # Add the header to the file
    openfile.write(header)

def print_test_vector(openfile, inputs, outputs):
    '''
    Takes a file, an input list and an output list and prints an ABEL test
    vector reflecting the inputs and desired outputs.
    '''
    # Create input list
    test_vector = '['
    for i in inputs:
        test_vector += str(i)
        test_vector += ','
    # Remove last comma to put end bracket
    test_vector = test_vector[:-1]
    test_vector += ']->['

    # Create output list
    for i in outputs:
        test_vector += str(i)
        test_vector += ','
    # Remove last comma to put end bracket
    test_vector = test_vector[:-1]
    test_vector += '];\n'

    # Add the test vector to the file
    openfile.write(test_vector)

def copy_file(origfile, copyfile):
    '''
    Copies all contents of original file to copy file.
    '''
    line = origfile.readline()
    while (line != ''):
        copyfile.write(line)
        line = origfile.readline()
    return

def insert_test_vectors(origfile, newfile, generate_test_vectors):
    '''
    Inserts test vectors into the ABEL file.
    '''
    # Copy every line over until we get to the end of the file.  Then, we
    # write the test vectors.  Then we end the file.
    line = origfile.readline()
    while(line != ''):
        # Overwrite last test vectors
        if line[:12].upper() == 'TEST_VECTORS':
            while (line[:4].upper() != 'END '):
                line = origfile.readline()
        # If we are at the end, start writing test vectors
        if line[:4].upper() == 'END ':
            # Insert test vectors
            generate_test_vectors(newfile)

            # Put white space between vectors and end of file
            newfile.write('\n\n\n')

        # Write next line of original file to new file
        newfile.write(line)

        # Read next line
        line = origfile.readline()
