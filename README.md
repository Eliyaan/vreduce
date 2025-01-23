## Vreduce

Takes a file, a command and a pattern to reproduce and tries to make the minimal reproductible example out of it. I use it (with default command/pattern) to make MREs for C errors and then report them in V's issues.

# How to use

Clone the repo, do `v run main.v` in the vreduce folder and follow the instructions (enter the file to reduce, the command, the error message) and when the program finished it will have produced a `rpdc.v` file that contains the reduced code.
