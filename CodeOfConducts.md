# Code of Conduct

## Variable Naming Conventions

### Function/Macro Arguments
* Positional arguments for macros or functions should begin with `arg_`.
* Arguments parsed by `cmake_parse_arguments()` should begin with `ARG_` or `_ARG_`.

### Function/Macro Variables
* Variables defined within functions or macros should begin with `_`.

### Cached Variables
* Public cached variables should begin with `SC_`.
* Internal cached variables should begin with `Z_SC_`.