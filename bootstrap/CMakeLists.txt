cmake_minimum_required(VERSION 3.28)

# Try to include the SideCMake initialization file
if (NOT DEFINED SIDECMAKE_DIR)
  if (DEFINED ENV{SIDECMAKE_DIR})
      set(SIDECMAKE_DIR $ENV{SIDECMAKE_DIR} CACHE PATH "The root path of SideCMake")
    else()
      set(SIDECMAKE_DIR ${CMAKE_SOURCE_DIR}/SideCMake CACHE PATH "The root path of SideCMake")
  endif()
endif()

include(${SIDECMAKE_DIR}/SCInitVariables.cmake)
include(${SIDECMAKE_DIR}/SCInstall.cmake)


# Set the project profiles 
project(
  ${SC_PROJECT_NAME}
  VERSION ${SC_PROJECT_VERSION}
  DESCRIPTION ${SC_PROJECT_DESCRIPTION}
  HOMEPAGE_URL ${SC_PROJECT_LINK}
  LANGUAGES ${SC_PROJECT_LANGUAGES}
)

  
# Prevent in-source builds
include(${SIDECMAKE_DIR}/SCUtilities.cmake)
sc_assure_out_of_source_builds()

# set the building options and warnings
include(${SIDECMAKE_DIR}/ProjectOptions.cmake)
myproject_setup_options()
myproject_global_options()

# set the dependencies for the entire project
include(Dependencies.cmake)
myproject_setup_dependencies()
myproject_local_options()
add_library(${PROJECT_NAME}::SC_BUILD_OPTIONS ALIAS SC_BUILD_OPTIONS)
add_library(${PROJECT_NAME}::SC_BUILD_WARNINGS ALIAS SC_BUILD_WARNINGS)


# Compile definitions
add_compile_definitions(
    SC_OS_${Z_SC_RUNTIME_OS_NAME}
)

# Adding the src
add_subdirectory(src)

# Installation rules for the entire project
sc_install_project()


# If MSVC is being used, and ASAN is enabled, we need to set the debugger environment
# so that it behaves well with MSVC's debugger, and we can run the target from visual studio
if(MSVC)
  get_all_installable_targets(all_targets)
  message("all_targets=${all_targets}")
  set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "PATH=$(VC_ExecutablePath_${VCVARSALL_ARCH});%PATH%")
endif()

# set the startup project for the "play" button in MSVC
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${SC_PROJECT_NAME})

# Documentation generation
if (SC_ENABLE_DOC)
  sc_generate_doc()
endif()

if (BUILD_TESTING)
  include(CTest)
  add_subdirectory(test)
endif()
# Print a summary of the build configuration
sc_print_summary()


