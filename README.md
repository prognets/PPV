# PPV
Repository for PPV programmable networks project.

## Structure of the repository
The repository contains 2 PPV directory. The ppv directory has the simpler source code, we added a new ppv header. This project emphasizes measuring the bytes/rates of incoming packets in a specific time period. It does not contain any additional functionality for simulating.

The ppv_simulation has additional functionalities to serve simulating the task. It measures the incoming packet rates and add feedback for the user and printing the packet rates. We added four other header fields to serve the simulation. We proposed a register which stores the bytes per packet value and the old byte measurements. In order to store the rates in one register we need to use an offset register. A third register was initialized for storing the time slot.

## Run the simulation
1. Run the make run command under ppv_simulation directory.
1. In the mininet command prompt, run h1 python3 ppv.py

The simulation generates random packet values from 0 to 3 and send the rates back to the terminal.
