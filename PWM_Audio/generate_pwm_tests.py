from sys import argv
from test_vectors import *

# Values for SW1 - SW4 inputs for valid buttonpresses or no buttonpress
button_codes    = [ [ 0, 0, 0, 0 ],  # NoSW
                    [ 1, 0, 0, 0 ],  # SW1
                    [ 0, 1, 0, 0 ],  # SW2
                    [ 0, 0, 1, 0 ],  # SW3
                    [ 0, 0, 0, 1 ] ] # SW4
NoSW = button_codes[0]
SW1  = button_codes[1]
SW2  = button_codes[2]
SW3  = button_codes[3]
SW4  = button_codes[4]

# State machine bit encodings for each buttonpress
machine_bits    = [   None,
                    [ 0, 1 ],  # SW1
                    [ 1, 0 ],  # SW2
                    [ 1, 1 ],  # SW3
                    [ 0, 0 ] ] # SW4

# Start and end (inclusive) addresses for each buttonpress, in binary
start_addresses = [   None,
                    [ 1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],  # SW1 0x7C000
                    [ 1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],  # SW2 0x58000
                    [ 1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],  # SW3 0x48000
                    [ 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ] ] # SW4 0x40000
end_addresses   = [  None,
                    [ 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ],  # SW1 0x7FFFF
                    [ 1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ],  # SW2 0x7BFFF
                    [ 1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ],  # SW3 0x57FFF
                    [ 1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ] ] # SW4 0x47FFF

#
# test_lfsr
#
# Goes through every state on an 8bit LFSR, starting at the zeroed state to
# ensure that it can successfully and safely exit it.  It wraps around to
# demonstrate that it cycles.
#
# Arguments: openfile (file) - The file to write the test vectors to
# Returns:   Nothing
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_lfsr(openfile):
    '''
    Goes through every value of the LFSR, starting at the (invalid) zero state.
    '''
    lfsr = [0] * 8 # Initial lfsr in zero state
    inc = 0 # Value of low bit in AddrClock, which is initially 0 until there
            # is an increment
    PWM_cycle = 0

    print_comment(openfile,
        'Preload registers with zeroed LFSR state, then go through every ' +
        'state once, including a wrap around back to the first nonzero ' +
        'state.  We show that a cycle increments the address counter, but ' +
        'leave it to other tests to show that the address counter itself ' +
        'works.  We also show that PWM cycle is true for only one clock: ' +
        'the one when the lfsr state is about to reset, or when its value ' +
        'is 10000000B.'
    )

    # Preload registers
    # Input format:
    #   Clock
    #   Switches
    #   Run, PWMCycle, AddrInc
    #   State bits
    #   AudioAddr
    #   AudioData
    #   AddrClock
    #   PWMCount
    inputs = [ 'P' ] + \
             [ 'X' ] + \
             [ 'X', 0, 'X' ] + \
             [ 'X' ] + \
             [ 'X' ] + \
             [ 'X' ] + \
             [ 0 ] + \
             [ str(lfsr) ]
    # Output format:
    #   State bits
    #   PWM out, Run, PWMCycle, AddrInc
    #   AddrClock
    #   lfsr value
    #   Data bits
    #   Address registers
    outputs = [ 'X' ]
    print_test_vector(openfile, inputs, outputs)

    # Can now iterate on normal clocks.  Iterate 2^8+1 times to get wrap around
    # (plus 1 because we start at all-zero state)
    for i in range(2**8 + 1):
        inputs = [ 'C' ] + \
                 [ str(NoSW) ] + \
                 [ 'X' ] * 7
        # We increment the AddrClock from 0000 to 0001 on a PWM_cycle (which
        # is AddrClock's CLK)
        inc = int(inc or PWM_cycle)
        # PWM cycle true on last iteration (1000 0000B)
        PWM_cycle = int(lfsr == [1,0,0,0,0,0,0,0])
        # Update lfsr
        lfsr = next_8bit_lfsr(lfsr)
        outputs = [ 'X' ] + \
                  [ 'X', 'X', PWM_cycle, 'X' ] + \
                  [ inc ] + \
                  [ str(lfsr) ] + \
                  [ 'X' ] + \
                  [ 'X' ]
        # Print
        print_test_vector(openfile, inputs, outputs)

#
# test_pwm_cycle_counter
#
# Tests the counter that waits for 16 PWM cycles.  This counter is important
# because other signals are clocked off of it.
#
# Arguments: openfile (file) - The file to write test vectors to
# Returns:   Nothing
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_pwm_cycle_counter(openfile):
    '''
    Simulates a running PWM counter and shows that it counts 16 times then
    resets.
    '''
    print_comment(openfile,
        'Simulates a running PWM counter, showing that it counts 16 times ' +
        'then resets.  This tests AddrClock, PWMCycle and AddrInc.  Start ' +
        'each by presetting the lfsr to immediately before wraparound so ' +
        'the increments happen without us writing hundreds of test vectors.'
    )

    # Counter is what we are testing
    counter    = [0, 0, 0, 0]

    # Count 17 times to demonstrate all values and wraparound.  Because this
    # counter is clocked on a divided clock, we preset on each iteration so
    # as to avoid writing 4096 test vectors per increment.
    for i in range(17):
        # We start so that the first clock brings the LFSR to the last state
        # before wraparound.  This is because we clock the counter signal on the
        # last state (which is 10000000) before wraparaound

        # Start lfsr immediately before reset with only high bit set: 1000 0000
        # Preset the registers
        # Input format:
        #   Clocks
        #   Switch values
        #   Data in
        inputs  = [ 'P' ] + \
                  NoSW + \
                  [ 0 ] * 8
        # Output format
        #   State bits
        #   PWM out, Run
        #   PWMCycle, AddrInc
        #   AddrClock
        #   lfsr value
        #   Data bits
        #   Address registers
        outputs = [ 'X' ] * 2 + \
                  [ 'X' ] * 2 + \
                  [ 0 ] + [ 0 ] + \
                  counter + \
                  [ 1, 0, 0, 0, 0, 0, 0, 0 ] + \
                  [ 'X' ] * 8 + \
                  [ 'X' ] * 19
        print_test_vector(openfile, inputs, outputs)

        # Update lfsr from 1000 0000 ==> 0000 0001

        # Increment PWM counter.  Counter state implies PWM cycle.
        inputs  = [ 'C' ] + \
                  NoSW + \
                  [ 0 ] * 8
        outputs = [ 'X' ] * 2 + \
                  [ 'X' ] * 2 + \
                  [ 1 ] + [ 0 ] + \
                  counter + \
                  [ 0, 0, 0, 0, 0, 0, 0, 1 ] + \
                  [ 'X' ] * 8 + \
                  [ 'X' ] * 19
        print_test_vector(openfile, inputs, outputs)

        # Update lfsr from 0000 0001 ==> 0000 0010
        # AddrInc is set when PWMCycle is 1 and address counter = 1111
        AddrInc = int(counter == [1, 1, 1, 1])
        # When AddrInc is active, the address counter increments
        counter = increment_counter(counter)
        # Increment PWM counter
        inputs  = [ 'C' ] + \
                  NoSW + \
                  [ 0 ] * 8
        outputs = [ 'X' ] * 2 + \
                  [ 'X' ] * 2 + \
                  [ 0 ] + [ AddrInc ] + \
                  counter + \
                  [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
                  [ 'X' ] * 8 + \
                  [ 'X' ] * 19
        print_test_vector(openfile, inputs, outputs)

    return

#
# test_pwm_out
#
# Tests that the PWM outputs are as expected for the argued PWM value.  The
# ABEL file is written such that the state machine is clocked every 16 PWM
# cycles.  Therefore, we can "trick" the machine into thinking a button was
# pressed by setting the data, and not worry about it resetting the data
# because we will only run one PWM cycle.  Thus, there will not be a clock
# for the machine to reset the data.
#
# Arguments: openfile (file) - The file to write test vectors to
#            pwm (int) - PWM value (must be 0-255)
# Returns:   Nothing.
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_pwm_out(openfile, pwm):
    '''
    Tests the PWM output functionality.
    '''
    print_comment(openfile,
        'Testing PWM cycle for width = %d.  The state machine ' %pwm +
        'clocks when AddrClock = 1111, and AddrClock increments once per ' +
        'lfsr cycle.  We start with AddrClock = 0000 and only run one lfsr ' +
        'cycle, so we dont have to worry about the machine resetting the data.'
    )
    pwm_list = int_to_binary_list(pwm, 8)
    # Set the lfsr to 0 and the data bits to the pwm value
    lfsr = [0] * 8 # Initial lfsr in zero state
    # Preload registers
    # Input format:
    #   Clocks
    #   Switch values
    #   Data in
    inputs  = [ 'P' ] + \
              NoSW + \
              [ 0 ] * 8
    # Output format
    #   State bits
    #   PWM out, Run, PWMCycle, AddrInc
    #   AddrClock
    #   lfsr value
    #   Data bits
    #   Address registers
    outputs = [ 'X' ] * 2 + \
              [ 0 ] + [ 'X' ] * 3 + \
              [ 0 ] * 4 + \
              lfsr + \
              pwm_list + \
              [ 'X' ] * 19
    print_test_vector(openfile, inputs, outputs)

    # Run through an entire 256 PWM lfsr cycle and output 1s when necessary
    for i in range(256):
        # The PWM out is true if current lfsr is less than data
        PWM_out = int(binary_list_to_int(lfsr) < pwm)
        # Update lfsr
        lfsr = next_8bit_lfsr(lfsr)

        inputs  = [ 'C' ] + \
                  NoSW + \
                  [ 0 ] * 8
        outputs = [ 'X' ] * 2 + \
                  [ PWM_out ] + [ 'X' ] * 3 + \
                  [ 'X' ] * 4 + \
                  lfsr + \
                  pwm_list + \
                  [ 'X' ] * 19
        print_test_vector(openfile, inputs, outputs)

#
# test_switch_release
#
# Tests system response when inputs go from valid buttonpush to no buttons
# being pressed.
#
# Arguments: openfile (file) - The file to write test vectors to
#            initial_sw (int) - Index of the switch being pushed originally
# Returns:   Nothing
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_switch_release(openfile, initial_sw):
    '''
    Tests for the environment being set appropriately when the system goes from
    a valid buttonpress to no buttons being active.
    '''
    print_comment(openfile,
        'Testing for system response when switch %d is released.' %initial_sw
    )
    # Input format:
    #   Clock, switches
    #   Data in
    inputs  = [ 'P' ] + button_codes[initial_sw] + \
              [ 1 ] * 8
    # Output format:
    #   State bits
    #   PWM out, Run, PWMCycle, AddrInc
    #   AddrClock
    #   lfsr value
    #   Data bits
    #   Address registers
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 0, 0] + \
              [ 1 ] * 4 + \
              [ 0, 1, 0, 0, 0, 0, 0, 0 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # Release the switch.  Outputs clocked on AddrInc shouldn't change yet
    inputs  = [ 'C' ] + NoSW + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 0, 0] + \
              [ 1 ] * 4 + \
              [ 1, 0, 0, 0, 0, 0, 0, 0 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc is now in the process of being clocked
    inputs  = [ 'C' ] + NoSW + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 1, 0] + \
              [ 1 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 0, 1 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc now high, next clock should see data be zeroed
    inputs  = [ 'C' ] + NoSW + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 0, 1] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc now high, next clock should see data be zeroed and address
    # incremented, but the state should stay the same.
    inputs  = [ 'C' ] + NoSW + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 0, 0, 0] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
              [ 0 ] * 8 + \
              [ 0 ] * 18 + [ 1 ]
    print_test_vector(openfile, inputs, outputs)

#
# test_switch_edge
#
# Tests for when the system goes from no buttons being pushed to a buttonpress.
#
# Arguments: openfile (file) - The file to write test vectors to
#            sw (int) - The index of the switch whose edge is being tested.
#            initial_state ([int]) - The state machine bit encoding when no
#               buttonpress present
# Returns:   Nothing
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_switch_edge(openfile, sw, initial_state):
    '''
    Tests for the environment being set appropriately when the system goes from
    no buttons being pressed to a valid buttonpress.
    '''
    print_comment(openfile,
        'Tests the system response when it goes from no active button ' +
        'pressed to switch %d pressed. ' %sw +
        'It is starting with the state encoding [ %d, %d ].'
        %(initial_state[0], initial_state[1])
    )
    # Input format:
    #   Clock, switches
    #   Data in
    inputs  = [ 'P' ] + NoSW + \
              [ 1 ] * 8
    # Output format:
    #   State bits
    #   PWM out, Run, PWMCycle, AddrInc
    #   AddrClock
    #   lfsr value
    #   Data bits
    #   Address registers
    outputs = initial_state + \
              [ 'X', 1, 0, 0] + \
              [ 1 ] * 4 + \
              [ 0, 1, 0, 0, 0, 0, 0, 0 ] + \
              [ 0 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # Simulate switch being pushed. Registers clocked on AddrInc shouldn't
    # change.
    inputs  = [ 'C' ] + button_codes[sw] + \
              [ 1 ] * 8
    outputs = initial_state + \
              [ 'X', 1, 0, 0] + \
              [ 1 ] * 4 + \
              [ 1, 0, 0, 0, 0, 0, 0, 0 ] + \
              [ 0 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc is about to go high
    inputs  = [ 'C' ] + button_codes[sw] + \
              [ 1 ] * 8
    outputs = initial_state + \
              [ 'X', 1, 1, 0] + \
              [ 1 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 0, 1 ] + \
              [ 0 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc now high, next clock should see transition with initial address
    # and data relayed to output
    inputs  = [ 'C' ] + button_codes[sw] + \
              [ 1 ] * 8
    outputs = initial_state + \
              [ 'X', 1, 0, 1] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
              [ 0 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # Should now have message address and data zeroed.  Data is zeroed because
    # before the first read, we don't know what to play.
    inputs  = [ 'C' ] + button_codes[sw] + \
              [ 1 ] * 8
    outputs = machine_bits[sw] + \
              [ 'X', 1, 0, 0] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 1, 0, 0 ] + \
              [ 0 ] * 8 + \
              start_addresses[sw]
    print_test_vector(openfile, inputs, outputs)

#
# test_switches
#
# Tests a switch press.  IIf multiple buttons are pressed, the system plays
# the switch whose index is closest to 1.
#
# Arguments: openfile (file) - The file to write test vectors to.
#            switches ([int]) - The switches that are pressed.
#            addr ([int]) - The address to start incrementing from.
#            clocks (int) - OPTIONAL The number of times the address should be
#               incremented before returning.  The default value will go
#               through the message once with a wrap around for one address
#               read.
# Returns:   Nothing.
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_switches(openfile, sws, addr=None, clocks=None):
    '''
    Tests that the system reacts as expected when switches are pressed.  This
    works such that the switch whose number is closest to 1 is the one that is
    recognized as being pushed. It will also show that the data is properly
    registered, but not until the correct clock edge.  It does not test the
    switch trigger or release.
    '''
    # Figure out which switch we are emulating
    sw_idx = 4
    if (sws[0] == 1):
        sw_idx = 1
    elif (sws[1] == 1):
        sw_idx = 2
    elif (sws[2] == 1):
        sw_idx = 3

    # State machine bit encoding
    state = machine_bits[sw_idx]
    # Start address of the recording
    start_addr = start_addresses[sw_idx]
    # End address (inclusive) of the recording
    end_addr = end_addresses[sw_idx]

    start_addr_int = binary_list_to_int(start_addr)
    end_addr_int = binary_list_to_int(end_addr)
    # Registered data (clocked on AddrInc)
    data_reg = [ 0 ] * 8
    # Input data from pins
    data_in = [ 0 ] * 8

    if (clocks == None):
        clocks = end_addr_int - start_addr_int
    if (addr == None):
        addr = start_addr

    print_comment(openfile,
        'Tests when the logical switch configuration [SW1,SW2,SW3,SW4], ' +
        '[%d,%d,%d,%d]. ' %(sws[0], sws[1], sws[2], sws[3]) +
        'It starts at address %d (decimal) ' %binary_list_to_int(addr) +
        'and reads for %d total iterations.' %clocks
    )

    for i in range(clocks):
        # Preset registers to the time when we will see address be clocked on
        # the next 32MHz clock

        # We change data early to show that it waits until the time is right
        # to update
        data_in = increment_counter(data_in)

        # Input format:
        #   Clock, switches
        #   Data in
        inputs  = [ 'P' ] + sws + \
                  data_in
        # Output format:
        #   State bits
        #   PWM out, Run, PWMCycle, AddrInc
        #   AddrClock
        #   lfsr value
        #   Data bits
        #   Address registers
        outputs = state + \
                  [ 'X', 1, 1, 0] + \
                  [ 1 ] * 4 + \
                  [ 0, 0, 0, 0, 0, 0, 0, 1 ] + \
                  data_reg + \
                  addr
        print_test_vector(openfile, inputs, outputs)

        inputs  = [ 'C' ] + sws + \
                  data_in
        outputs = state + \
                  [ 'X', 1, 0, 1] + \
                  [ 0 ] * 4 + \
                  [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
                  data_reg + \
                  addr
        print_test_vector(openfile, inputs, outputs)

        # Update data in registers and the address
        addr = increment_counter(addr, start=start_addr_int,
            inclusive_end=end_addr_int)
        data_reg = data_in
        inputs  = [ 'C' ] + sws + \
                  data_in
        outputs = state + \
                  [ 'X', 1, 0, 0] + \
                  [ 0 ] * 4 + \
                  [ 0, 0, 0, 0, 0, 1, 0, 0 ] + \
                  data_reg + \
                  addr
        print_test_vector(openfile, inputs, outputs)

#
# test_button_change
#
# Tests when the system goes from one valid buttonpress to another valid
# buttonpress without going to no buttons pressed in between.
#
# Arguments: openfile (file) - The file to write test vectors to
#            initial_sw (int) - The index of the switch initially pressed
#            final_sw (int) - The index of the switch pressed next
# Returns:   Nothing
#
# Revisions: 11/10/16 - Tim Menninger: Created
#
def test_button_change(openfile, initial_sw, final_sw):
    '''
    Shows that going from one switch to the next plays the second without
    stopping or blowing up.
    '''
    print_comment(openfile,
        'Tests for system response when switch %d ' %initial_sw +
        'is being pressed, then switch %d is pressed ' %final_sw +
        'and switch %d is released without there ever being ' %initial_sw +
        'a time during which no switches are pressed.'
    )

    # Input format:
    #   Clock
    #   Switches
    #   Run, PWMCycle, AddrInc
    #   State bits
    #   AudioAddr
    #   AudioData
    #   AddrClock
    #   PWMCount
    inputs  = [ 'P' ] + \
              str(button_codes[initial_sw]) + \
              [ 'X', 1, 0 ] + \
              str(machine_bits[initial_sw]) + \
              [ 0 ] + \
              [ 255 ] + \
              [ 15 ] + \
              [ '[0,1,0,0,0,0,0,0]' ]
    # Output format:
    #   State bits
    #   PWM out, Run, PWMCycle, AddrInc
    #   AddrClock
    #   lfsr value
    #   Data bits
    #   Address registers
    outputs = [ 'X' ]
    print_test_vector(openfile, inputs, outputs)

    # Simulate change in switch (from one valid to another valid push). No
    # change in AddrInc clocked values yet
    inputs  = [ 'C' ] + button_codes[final_sw] + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 0, 0] + \
              [ 1 ] * 4 + \
              [ 1, 0, 0, 0, 0, 0, 0, 0 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc is now in the process of being clocked
    inputs  = [ 'C' ] + button_codes[final_sw] + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 1, 0] + \
              [ 1 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 0, 1 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc now high, next clock should see system move to start playing
    # other switch
    inputs  = [ 'C' ] + button_codes[final_sw] + \
              [ 1 ] * 8
    outputs = machine_bits[initial_sw] + \
              [ 'X', 1, 0, 1] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
              [ 1 ] * 8 + \
              [ 0 ] * 19
    print_test_vector(openfile, inputs, outputs)

    # AddrInc now high, next clock should see data be zeroed and address
    # incremented, but the state should stay the same.
    inputs  = [ 'C' ] + button_codes[final_sw] + \
              [ 1 ] * 8
    outputs = machine_bits[final_sw] + \
              [ 'X', 1, 0, 0] + \
              [ 0 ] * 4 + \
              [ 0, 0, 0, 0, 0, 0, 1, 0 ] + \
              [ 1 ] * 8 + \
              start_addresses[final_sw]
    print_test_vector(openfile, inputs, outputs)

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
    inputs  = [ 'CLK32', 'SW1', 'SW2', 'SW3', 'SW4',
               'Run', 'PWMCycle', 'AddrInc', 'AddrBits',
               'AudioAddr', 'AudioData', 'AddrClock', 'PWMCount' ]
    outputs = [ 'AddrBits', 'AudioPWMOut', 'Run', 'PWMCycle', 'AddrInc',
               'AddrClock', 'PWMCount', 'AudioData', 'AudioAddr' ]
    print_test_header(openfile, inputs, outputs)

    # Test the LFSR
    test_lfsr(openfile)
    return
    # Test the PWM counter and the address counter
    test_pwm_cycle_counter(openfile)

    # Test the PWM output
    test_pwm_out(openfile, 0)
    test_pwm_out(openfile, 100)
    test_pwm_out(openfile, 255)

    # Test the four switches being pressed individually. Trying to do all of
    # the possible addresses crashed the computer.  So we will do a few at
    # the end to show it can (1) increment properly and (2) wrap around
    # properly
    addr = int_to_binary_list(binary_list_to_int(end_addresses[1]) - 10, 19)
    test_switches(openfile, SW1, clocks=20)
    addr = int_to_binary_list(binary_list_to_int(end_addresses[2]) - 10, 19)
    test_switches(openfile, SW2, clocks=20)
    addr = int_to_binary_list(binary_list_to_int(end_addresses[3]) - 10, 19)
    test_switches(openfile, SW3, clocks=20)
    addr = int_to_binary_list(binary_list_to_int(end_addresses[4]) - 10, 19)
    test_switches(openfile, SW4, clocks=20)

    # Test a few clocks of each combination of any nonzero number of buttons
    # pressed, to ensure that they go to the right state.
    for i in range(1, 16):
        sws = int_to_binary_list(i, 4)
        test_switches(openfile, sws, clocks=5)

    # Test possible buttonchanges
    for i in range(1, 5):
        for j in range(1, 5):
            if (i == j):
                continue
            test_button_change(openfile, i, j)

    # Test rising edges of buttons, when they are pressed from no buttons.
    # Test each combination of button and start state
    for i in range(1, 5):
        for j in range(1, 5):
            test_switch_edge(openfile, i, machine_bits[j])

    # Test falling edges of buttons, when they are released.  Test each
    # individual button.
    for i in range(1, 5):
        test_switch_release(openfile, i)

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
