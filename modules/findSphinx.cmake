# Look for sphinx-build executable
find_program(SPHINX_EXECUTABLE 
             NAMES isphinx-build 
             DOC "Path to the Sphinx executable")
include(FindPackageHandleStandardArgs)
# Handle standard arguments to find_package like REQUIRED and QUIET
find_package_handle_standard_args(Sphinx 
                                  "Failed to find sphinx-build executable" 
                                  SPHINX_EXECUTABLE)