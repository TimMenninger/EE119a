import copy, os

LINE_LENGTH = 100

###############################################################################
#
# Helper functions/utils
#
#

#
# int_to_binary_list
#
# Takes an integer and returns a list of 0s and 1s representing it in binary,
# with the 0th index containing the MSB.  If val requires more bits than
# num_bits, an error will rise.
#
# Arguments: val (int) - The number to convert
#            num_bits (int) - The number of bits in the result
# Returns:   binary_list (list) - The list of 0s and 1s with 0th index
#               containing the most significant bit
#
# Revisions: 11/09/16 - Tim Menninger: Created
#
def int_to_binary_list(val, num_bits):
    binary_list = []
    # Put in 1s and 0s (will be in reverse order)
    while (val != 0):
        binary_list.append(val & 1)
        val >>= 1

    # Reverse the list before returning it
    binary_list.reverse()

    # Fill in zeroes on the left
    fill_in = [0] * (num_bits - len(binary_list))

    return fill_in + binary_list

#
# binary_list_to_int
#
# Takes a list of 0s and 1s with the 0th index containing the MSB, and returns
# its integer equivalent.  The list is the binary representation of the int.
#
# Arguments: binary_list (list) - The binary representation of the number with
#               the 0th index containing MSB
# Returns:   out (int) - The integer representation of the binary list
#
# Revisions: 11/09/16 - Tim Menninger: Created
#
def binary_list_to_int(binary_list):
    out = 0
    # Add in each bit one at a time
    for bit in binary_list:
        out <<= 1
        out += bit

    return out

#
# next_8bit_lfsr
#
# Takes the current state of an 8-bit lfsr and returns the next value of the
# lfsr.
#
# Arguments: lfsr (list) - Binary representation with 0th index containing MSB
#               of the current lfsr state.
# Returns:   (list) - Next lfsr state with 0th index containing MSB
#
# Revisions: 11/09/16 - Tim Menninger: Created
#
def next_8bit_lfsr(lfsr):
    # If value is all zeroes, we put a 1 in the LSB
    if (lfsr == [0, 0, 0, 0, 0, 0, 0, 0]):
        return [0, 0, 0, 0, 0, 0, 0, 1]

    # Otherwise, shift everything left one bit and load into the LSB the xor
    # of bits 7, 5, 4, and 3 (their values before shifting).  We mod with 2
    # because that gives 1 iff. there are an odd number of 1s and 0 otherwise
    next_bit0 = (lfsr[7-7] + lfsr[7-5] + lfsr[7-4] + lfsr[7-3]) % 2

    return lfsr[1:] + [next_bit0]

#
# increment_counter
#
# Takes a bit list that represents a counter and increments it.  The
# distinction as counter is to imply that when the bit list is all 1s, it
# resets the counter to all 0s.
#
# Arguments: bit_list ([int]) - The counter to increment with the 0th index
#               containing the MSB
#            start (int) - OPTIONAL Start address when wrapping
#            inclusive_end (int) - OPTIONAL End address (inclusive) when wrapping
# Returns:   ([int]) - The incremented counter with the 0th index containing
#               the MSB
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def increment_counter(bit_list, start=0, inclusive_end=float('inf')):
    # Convert to number, increment, wrap if needed, back to list
    num = binary_list_to_int(bit_list)
    num += 1
    # If we incremented it to a number that requires more bits than the length
    # of the list, set it back to zero, i.e., mod it with 2^num_bits
    num %= 2**len(bit_list)

    # If past inclusive end, reset OR if wrapped before start, fastforward
    if (inclusive_end < num or start > num):
        num = start

    bit_list = int_to_binary_list(num, len(bit_list))

    return bit_list

###############################################################################
#
# Code used by any ABEL file using this
#
#

#
# print_comment
#
# Prints a comment to the file.  This will wrap comments such that no line is
# longer than LINE_LENGTH characters.  It will wrap entire words, as opposed
# to cutting them off.  It will put a space after the beginning " character
# and before the start of that line.  It prefaces the comment with one line
# of whitespace.
#
# Arguments: openfile (file_descriptor) - The file to write to
#            comment (string) - The comment to write
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def print_comment(openfile, comment):
    '''
    Formats and prints a comment in the file, breaking it up into lines no
    longer than LINE_LENGTH characters.
    '''
    words = comment.split()
    # Comment begins with one double quote, and a space separating it form the
    # comment itself.  Also start with whitespace before the comment.
    line = '\n" '
    num_characters = 0
    # Print each word into the file.
    for word in words:
        # Flush the buffer if it is too long
        if len(line) + len(word) > LINE_LENGTH:
            openfile.write(line + '\n')
            line = '" '

        # Add the next word to the buffer
        line += word + " "

    # Flush the last line
    openfile.write(line + '\n')

#
# print_test_header
#
# Takes a list of inputs and outputs (all strings) that correspond to the names
# of variables in the ABEL file.  It prints the header to the ABEL file in the
# correct format (with parentheses, brackets and an arrow).  It also prints
# "TEST_VECTORS" to the file before the header containing signal names.
#
# Arguments: openfile (file_descriptor) - File to write to
#            inputs ([string]) - Input signal names
#            outputs ([string]) - Output signal names
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
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

#
# print_test_vector
#
# Prints a test vector to the file in its correct syntax.  The inputs and
# outputs are retrieved from arguments.
#
# Arguments: openfile (file_descriptor) - The file to write to
#            inputs ([union]) - List of values to print as inputs
#            outputs ([union]) - List of values to print as outputs
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
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

#
# copy_file
#
# Copies the file at filename (relative path) to a file with the same name and
# "copy" appended to the end.
#
# Arguments: filename (string) - Relative path to file to create
# Returns:   (string) - The filename of the original file
#            (string) - The filename of the copy file
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def copy_file(filename):
    '''
    Copies all contents of original file to copy file.
    '''
    # Create the copy file
    origfile = open(filename, 'r')
    copyfile = open(filename + 'copy', 'w')

    # Copy contents over
    line = origfile.readline()
    while (line != ''):
        copyfile.write(line)
        line = origfile.readline()

    # Close the files
    origfile.close()
    copyfile.close()
    return filename, filename + 'copy'

#
# insert_test_vectors
#
# Inserts test vectors into the file at the argued relative path.  A temporary
# copy of the original file is created in the process, but in the end, the
# only remaining file is the one with the original name and test vectors
# inside of it.
#
# Arguments: filename (string) - Relative path to file to write to
#            generate_test_vectors (function(file_descriptor)) - The function
#               that will create test vectors and insert them into the argued
#               file
# Returns:   Nothing
#
# Revisions: 11/03/16 - Tim Menninger: Created
#
def insert_test_vectors(filename, generate_test_vectors):
    '''
    Inserts test vectors into the ABEL file.
    '''
    # Create a copy of the file to refer to when inserting vectors
    filename, copyfilename = copy_file(filename)

    # Open the files for inserting vectors
    origfile = open(copyfilename, 'r')
    newfile = open(filename, 'w')

    # Copy every line over until we get to the end of the file.  Then, we
    # write the test vectors.  Then we end the file.
    line = origfile.readline()
    while(line != ''):
        # Overwrite last test vectors
        if line[:12].upper() == 'TEST_VECTORS':
            while (line[:4].upper() != 'END ' and line != ''):
                line = origfile.readline()
        # If we are at the end, start writing test vectors
        if line[:4].upper() == 'END ' or line == '':
            # Insert test vectors
            generate_test_vectors(newfile)

            # Put white space between vectors and end of file
            newfile.write('\n\n\n')

        # Write next line of original file to new file
        newfile.write(line)

        # Read next line
        if (line != ''):
            line = origfile.readline()

    # Close the files
    origfile.close()
    newfile.close()

    # Get the path to the copy file that we are deleting and delete the file
    copypath = os.path.realpath(__file__)
    copypath = '/'.join(copypath.split('/')[:-1])
    os.remove(os.path.join(copypath, copyfilename))

    return
