# Traffic Wing examples

This example is designed to show two different state machines for using the Traffic Wing add on board.

The pinout of the add on board is as follows:

// P4 = CAR1 | P6 = CAR3 | P9 = CAR4 | P10 = CAR2
// LANE13 is cars 1 & 2
// LANE24 is cars 2 & 4
// LANE1 Lights P11 = RED | P12 = YELLOW | P13 = GREEN
// LANE2 Lights P20 = RED | P19 = YELLOW | P18 = GREEN 
// LANE3 Lights P25 = RED | P23 = YELLOW | P21 = GREEN 
// LANE4 Lights P42 = RED | P38 = YELLOW | P37 = GREEN

     3.3V -o|
CAR1 - P4 -o|
      GND -o|
CAR3 - P6 -o|
CAR4 - P9 -o|
CAR2 -P10 -o|
RED1 -P11 -o|
YLW1 -P12 -o|
GRN1 -P13 -o|
GRN2 -P18 -o|
YLW2 -P19 -o|
RED2 -P20 -o|
GRN3 -P21 -o|               |o- P42- RED4
YLW3 -P23 -o|               |o- P38- YLW4
RED3 -P25 -o|               |o- P37- GRN4
             ---------------

## What they do: ##

### Timed Light Example ###

The timed light example takes a 32 bit counter which helps us divide down the 48MHz HFOSC (high frequency oscillator) into smaller time divisions.
We can control the rate at which the intersection changes. The further into the counter you get, the slower the change will be (i.e., `counter[31]` will be slower than `counter[29]`).

### how to build Timed Light:

To build, make sure you have the tools installed properly (you can follow the instructions on the main README).
Then run `make build_timed` If the tools are installer properly, you should see a `car_waiting.bin` in the project directory.

After building, you can do `make prog_timed` and it will program the flash on the IcyBlue Feather.

### Cars waiting example ###

The timed light example takes a 32 bit counter which helps us divide down the 48MHz HFOSC (high frequency oscillator) into smaller time divisions.
We can control the rate at which the intersection changes. The further into the counter you get, the slower the change will be (i.e., `counter[31]` will be slower than `counter[29]`).

In addition to this, the example takes into account the buttons which represent cars. Button presses are registered with timing requirements to determine when to change the signal.

### how to build Car Waiting:

To build, make sure you have the tools installed properly (you can follow the instructions on the main README).
Then run `make build_cars` If the tools are installer properly, you should see a `car_waiting.bin` in the project directory.

After building, you can do `make prog_cars` and it will program the flash on the IcyBlue Feather.