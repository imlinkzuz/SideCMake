

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(myproject_setup_dependencies)
  cmake_policy(SET CMP0167 NEW) # ENABLE CMP0167: Prefer CONFIG mode for all find_package calls. 
  cmake_policy(SET CMP0144 NEW) # DISABLE CMP0144: Allow use of <Package>_ROOT variables to specify package locations.
  # For each dependency, see if it's
  # already been provided to us by a parent project

  include(${SIDECMAKE_DIR}/SCFindPackage.cmake)

# Use sc_find_package to find and configure dependencies
# you can add your own dependencies here:
#  sc_find_package(
#    TARGET 
#      fmt::fmt 
#    PKG_OPTIONS 
#      REQUIRED CONFIG
#  )  

#  add_compile_definitions(SPDLOG_FMT_EXTERNAL)
#  sc_find_package(
#    TARGET 
#      spdlog::spdlog 
#    OPTIONS 
#      REQUIRED CONFIG
#  )


endfunction()
