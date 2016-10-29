import copy

def binary_list_to_int(binary):
    '''
    Takes a list of 1's and 0's and converts it to an integer.
    '''
    out = 0
    for idx, i in enumerate(range(len(binary)-1, -1, -1)):
        out += 2**i * binary[idx]
    return out

def rotate_bits(order, initial_state):
    '''
    Helper function to rotate bits in a list in the order specified by the
    order argument.
    '''
    # Copy the input so we don't worry about overwriting bits
    output = copy.deepcopy(initial_state)

    # Rotate bits by copying in specified order
    for i in range(len(order)-1, -1, -1):
        idx = (i-1) % len(order)
        output[order[i]-1] = initial_state[order[idx]-1]

    return output

def int_to_binary_list(number, listsize):
    '''
    Takes a number and converts it to a binary list, where the LSB is at the
    rightmost place.
    '''
    out = [0] * listsize
    for i in range(listsize-1, -1, -1):
        out[i] = number & 1
        number >>= 1
    return out

def set_indices(indices, values, outlength):
    '''
    Takes a list of 1-indexed indices, and values to put at those indices,
    and the lenght of the output list, and puts the specified values at each
    index.  All other indices will have 0.
    '''
    out = [0] * outlength
    # Fill the specified indices
    for i, elem in enumerate(indices):
        out[elem-1] = values[i]
    return out

def test_white_button(openfile, initial_state):
    '''
    Takes an initial state and updates it as if the white button were pressed.
    When the white button is pressed, the middle hexagon has all of its bits
    inverted.  These are outs 10,  8, 15,  4,  6, 12.
    '''
    # The bits to invert
    bits = [10,  8, 15,  4,  6, 12]

    # Define the input state
    input_state = ['.C.', 0, 0, 0, 0, 1]

    # Copy the input to be our output
    output = copy.deepcopy(initial_state)

    # Invert bits
    for bit in bits:
        output[bit-1] = int(not output[bit-1])

    # Print the test vector
    print_test_vector(openfile, input_state, output + [1])

    # Return the result
    return output

def test_black_button(openfile, initial_state):
    '''
    Takes an initial state and updates it as if the black button were pressed.
    When the blue button is pressed, the right hexagon is rotated
    clockwise, with 2,  8,  9, 14,  5,  4  being the order.
    '''
    # The order of input movement
    order = [2,  8,  9, 14,  5,  4]

    # Define the input state
    input_state = ['.C.', 1, 0, 0, 0, 0]

    # Rotate outputs
    output = rotate_bits(order, initial_state)

    # Print the test vector
    print_test_vector(openfile, input_state, output + [1])

    return output

def test_red_button(openfile, initial_state):
    '''
    Takes an initial state and updates it as if the red button were pressed.
    When the blue button is pressed, the upper triangle is rotated
    clockwise, with 1,  8, 15,  5,  4,  6,  7, 12, 10 being the order.
    '''
    # The order of input movement
    order = [1,  8, 15,  5,  4,  6,  7, 12, 10]

    # Define the input state
    input_state = ['.C.', 0, 0, 0, 1, 0]

    # Rotate outputs
    output = rotate_bits(order, initial_state)

    # Print the test vector
    print_test_vector(openfile, input_state, output + [1])

    return output

def test_blue_button(openfile, initial_state):
    '''
    Takes an initial state and updates it as if the blue button were pressed.
    When the blue button is pressed, the left hexagon is rotated counter
    clockwise, with 11, 10,  2,  6,  7, 13 being the order.
    '''
    # The order of input movement
    order = [11, 10,  2,  6,  7, 13]

    # Define the input state
    input_state = ['.C.', 0, 1, 0, 0, 0]

    # Rotate outputs
    output = rotate_bits(order, initial_state)

    # Print the test vector
    print_test_vector(openfile, input_state, output + [1])

    return output

def test_green_button(openfile, initial_state):
    '''
    Takes an initial state and updates it as if the green button were pressed.
    When the green button is pressed, the lower triangle rotates counter
    clockwise, with 3,  6, 12, 11, 10,  8,  9, 15,  4 being the order.
    '''
    # The order of input movement
    order = [3,  6, 12, 11, 10,  8,  9, 15,  4]

    # Define the input state
    input_state = ['.C.', 0, 0, 1, 0, 0]

    # Rotate outputs
    output = rotate_bits(order, initial_state)

    # Print the associated test vector
    print_test_vector(openfile, input_state, output + [1])

    return output

def test_manual_reset(openfile, initial_state, final_state):
    '''
    Takes an initial state and a desired final state and simulates a manual
    reset, printing all of the vectors along the way, until the system reaches
    the final state.  The final state is returned.
    '''
    # The order of inputs isn't 1-15, rather, a user-friendly order:
    order = [1, 11, 10, 8, 9, 13, 12, 2, 15, 14, 7, 6, 4, 5, 3]

    # Must start with the manual reset input, which is an active green and
    # white switch.
    input_state = ['.C.', 0, 0, 1, 0, 1]
    output = copy.deepcopy(initial_state) # Nothing changes yet
    print_test_vector(openfile, input_state, output + [0])

    # Start feeding in bits based on desired final state.
    for i in range(14, -1, -1):
        idx = order[i]
        # Decide whether the blue or black button should be pressed to shift in
        # a 0 or a 1, respectively
        blue = int(final_state[idx-1] == 0)
        black = int(final_state[idx-1] == 1)

        # Define the input state respectively
        input_state = ['.C.', black, blue, 1, 0, 1]

        # Shift everything in output and insert new bit into Out1
        for j in range(13, -1, -1):
            output[order[j+1]-1] = output[order[j]-1]
        output[0] = final_state[idx-1]

        # Print the test vector
        print_test_vector(openfile, input_state, output + [1])

        # Let go of the button
        input_state = ['.C.', 0, 0, 1, 0, 1]
        print_test_vector(openfile, input_state, output + [0])

    # Ideally output is equal to the argued final_state
    return output

def test_random_reset(openfile, initial_state, iterations):
    '''
    Takes an initial state and a number of iterations (or number of clocks)
    and creates a test vector for each state.  This simulates random reset
    by computing the LFSR outputs for each clock given a previous state.
    '''
    # Run the 15-bit LFSR, which uses the highest two bits as feedback bits.
    # This assumes that the initial state given has the lowest bit first.
    for i in range(iterations):
        input_state = ['.C.', 0, 0, 0, 0, 0]
        output = copy.deepcopy(initial_state)
        output[0] = output[13] ^ output[14] + (sum(output) == 0)
        for j in range(len(output)-1):
            output[j+1] = initial_state[j]
        print_test_vector(openfile, input_state, output + [0])
        initial_state = copy.deepcopy(output)

    # Will be useful to know the final state for continuing testing
    return output

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

def print_test_header(openfile):
    '''
    Prints the test vector header that defines the order of the signals in each
    test vector.
    '''
    header = 'TEST_VECTORS\n'
    header += '([Clock,BlackSw,BlueSw,GreenSw,RedSw,WhiteSw]->['
    # Put all Out signals
    for i in range(1, 16):
        header += 'Out' + str(i) + ','
    header += 'ClkOut])\n'

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

def insert_test_vectors(origfile, newfile):
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

def generate_test_vectors(openfile):
    '''
    Defines all of the test vectors and comments that will go into the file.
    '''
    # The initial state is presumed to be all zeroes.
    state = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    print_test_header(openfile)

    # Test a random reset
    print_comment(openfile,
        'Test the functionality of our random reset, and also randomly reset '
      + 'the system.'
    )
    state = test_random_reset(newfile, state, 10)

    # Test a few manual resets
    print_comment(openfile,
        'Test the functionality of our manual reset, and also randomly reset '
      + 'the system.  We are trying to reset the state to'
      + '[0,0,0,0,0,0,0,0,0,0,0,0,0,1,1].'
    )
    state = test_manual_reset(newfile, state, [0,0,0,0,0,0,0,0,0,0,0,0,0,1,1])

    # Test that LFSR wraps around properly
    print_comment(openfile,
        'Test that the LFSR wraps around properly'
    )
    state = test_random_reset(newfile, state, 3)

    # Test buttons
    print_comment(openfile,
        'Testing buttonpushes for general functionality.  Testing black, '
      + 'blue, green, red then white, in that order, 3 times over.'
    )
    for i in range(3):
        state = test_black_button(openfile, state)
        state = test_blue_button(openfile, state)
        state = test_green_button(openfile, state)
        state = test_red_button(openfile, state)
        state = test_white_button(openfile, state)

    # For each combination of middle hexagon, try a white buttonpush
    print_comment(openfile,
        'Testing a white buttonpush on every combination of light pattern '
      + 'within the white hexagon.'
    )
    # 2^n - 1 values in set of all subsets
    for i in range(2**6):
        set_bits = int_to_binary_list(i, 6)
        white_order = [10,  8, 15,  4,  6, 12]
        set_bits = set_indices(white_order, set_bits, 15)
        # Set state to desired light pattern
        state = test_manual_reset(openfile, state, set_bits)
        # Test the pattern
        state = test_white_button(openfile, state)

    # For each combination of right hexagon, try a black buttonpush
    print_comment(openfile,
        'Testing a black buttonpush on every combination of light pattern '
      + 'within the black hexagon.'
    )
    # 2^n - 1 values in set of all subsets
    tested = [0] * 2**6
    for i in range(2**6):
        if tested[i] == 1:
            continue
        set_bits = int_to_binary_list(i, 6)
        black_order = [2,  8,  9, 14,  5,  4]
        set_bits = set_indices(black_order, set_bits, 15)
        # Set state to desired light pattern
        state = test_manual_reset(openfile, state, set_bits)
        # Test the pattern
        # Rotate completely through, so we can take care of 6 without
        # having to reset
        for j in range(6):
            val = [state[1], state[7], state[8], state[13], state[4], 
                   state[3]]
            tested[binary_list_to_int(val)] = 1
            state = test_black_button(openfile, state)

    # For each combination of left hexagon, try a blue buttonpush
    print_comment(openfile,
        'Testing a blue buttonpush on every combination of light pattern '
      + 'within the blue hexagon.'
    )
    # 2^n - 1 values in set of all subsets
    tested = [0] * 2**6
    for i in range(2**6):
        if tested[i] == 1:
            continue
        set_bits = int_to_binary_list(i, 6)
        blue_order = [11, 10,  2,  6,  7, 13]
        set_bits = set_indices(blue_order, set_bits, 15)
        # Set state to desired light pattern
        state = test_manual_reset(openfile, state, set_bits)
        # Test the pattern
        # Rotate completely through, so we can take care of 6 without
        # having to reset
        for j in range(6):
            val = [state[10], state[9], state[1], state[5], state[6], 
                   state[12]]
            tested[binary_list_to_int(val)] = 1
            state = test_blue_button(openfile, state)

    # For each combination of upper triangle, try a red buttonpush
    print_comment(openfile,
        'Testing a red buttonpush on every combination of light pattern '
      + 'within the red triangle.'
    )
    # 2^n - 1 values in set of all subsets
    tested = [0] * 2**9
    for i in range(2**9):
        if tested[i] == 1:
            continue
        set_bits = int_to_binary_list(i, 9)
        red_order = [1,  8, 15,  5,  4,  6,  7, 12, 10]
        set_bits = set_indices(red_order, set_bits, 15)
        # Set state to desired light pattern
        state = test_manual_reset(openfile, state, set_bits)
        # Test the pattern
        # Rotate completely through, so we can take care of 9 without
        # having to reset
        for j in range(9):
            val = [state[0], state[7], state[14], state[4], state[3], 
                   state[5], state[6], state[11], state[9]]
            tested[binary_list_to_int(val)] = 1
            state = test_red_button(openfile, state)

    # For each combination of upper triangle, try a red buttonpush
    print_comment(openfile,
        'Testing a green buttonpush on every combination of light pattern '
      + 'within the green triangle.'
    )
    # 2^n - 1 values in set of all subsets
    tested = [0] * 2**9
    for i in range(2**9):
        if tested[i] == 1:
            continue
        set_bits = int_to_binary_list(i, 9)
        green_order = [3,  6, 12, 11, 10,  8,  9, 15,  4]
        set_bits = set_indices(green_order, set_bits, 15)
        # Set state to desired light pattern
        state = test_manual_reset(openfile, state, set_bits)
        # Test the pattern
        # Rotate completely through, so we can take care of 9 without
        # having to reset
        for j in range(9):
            val = [state[2], state[5], state[11], state[10], state[9], 
                   state[7], state[8], state[14], state[3]]
            tested[binary_list_to_int(val)] = 1
            state = test_green_button(openfile, state)

    print_comment(openfile,
        'Testing bad buttonpush combinations.'
    )
    # Get all subsets of buttonpush combinations, but only test invalid ones.
    # To do this, start with a list of valid combinations.
    # [ Black, Blue, Green, Red, White ]
    valid_combinations = [ [0, 0, 0, 0, 0],
                           [1, 0, 0, 0, 0],
                           [0, 1, 0, 0, 0],
                           [0, 0, 1, 0, 0],
                           [0, 0, 0, 1, 0],
                           [0, 0, 0, 0, 1],
                           [0, 0, 1, 0, 1],
                           [1, 0, 1, 0, 1],
                           [0, 1, 1, 0, 1] ]
    test_bits = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
    for i in range(2**5):
        state = test_manual_reset(openfile, state, test_bits)
        set_bits = int_to_binary_list(i, 5)
        if set_bits not in valid_combinations:
            print_test_vector(openfile, ['.C.'] + set_bits, test_bits + [1])

    return

if __name__ == '__main__':
    origfile = open('hexer.abl', 'r')
    newfile = open('hexer_w_vecs.abl', 'w')
    insert_test_vectors(origfile, newfile)
    origfile.close()
    newfile.close()
