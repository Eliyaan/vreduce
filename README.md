## Vreduce (outdated, use `v reduce` instead)

Takes a file, a command and a pattern to reproduce and tries to make the minimal reproductible example out of it. I use it (with default command/pattern) to make MREs for C errors and then report them in V's issues.

# How to use

Clone the repo, do `v run main.v -f path_to_the_file_to_reduce -c command_to_use -e ErrorMessage_To_Reproduce` in the vreduce folder and when the program finished it will have produced a `rpdc.v` file that contains the reduced code. You can use `-h` or `--help` to show help about the flags.
