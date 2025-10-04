

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(myproject_setup_dependencies)
  cmake_policy(SET CMP0144 OLD)
  cmake_policy(SET CMP0072 NEW) # ENABLE  CMP0072: FindOpenGL prefers GLVND by default when available.
  # For each dependency, see if it's
  # already been provided to us by a parent project

  include(${SIDECMAKE_DIR}/SCFindPackage.cmake)

# Use sc_find_package to find and configure dependencies
# you can add your own dependencies here:
#  sc_find_package(PKG_TARGET fmt::fmt 
#    PKG_OPTIONS 
#      REQUIRED CONFIG
#  )  

#  add_compile_definitions(SPDLOG_FMT_EXTERNAL)
#  sc_find_package(PKG_TARGET spdlog::spdlog 
#    PKG_OPTIONS 
#      REQUIRED CONFIG
#  )


endfunction()
