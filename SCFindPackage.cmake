include(${SIDECMAKE_DIR}/SCUtilities.cmake)

#[[
@brief Registers a project dependency for later use and tracking.
@details The function appends the dependency information to an internal cache variable for project-wide access.
@param _ARG_PKG_NAME The name of the package or dependency.
@param _ARG_TARGET The CMake target associated with the package.
@param _ARG_PKG_VERSION The version of the package.
@param _ARG_OPTIONS Additional options for the package, such as 'REQUIRED' or 'CONFIG'.
]]
function(sc_add_project_dependency _ARG_PACKAGE) 
    cmake_parse_arguments(_ARG "" "VERSION" "TARGETS;OPTIONS" ${ARGN})
    set(_VAR_TARGET Z_SC_PKG_${_ARG_PACKAGE}_TARGETS)
    set(_VAR_OPTIONS Z_SC_PKG_${_ARG_PACKAGE}_OPTIONS)
    set(_VAR_VERSION Z_SC_PKG_${_ARG_PACKAGE}_VERSION)
    #set(my_pkg_library_path  Z_SC_PKG_${_ARG_PACKAGE}_LIBRARY_PATH)
    #set(my_pkg_include_dirs  Z_SC_PKG_${_ARG_PACKAGE}_INCLUDE_DIRS)

    # Set the target as an internal cached variable
    sc_global_set(${_VAR_TARGET} "${_ARG_TARGETS}" "Targets of ${_ARG_PACKAGE}" INTERNAL) 

    # Set the version as an internal cached variable
    sc_global_set(${_VAR_VERSION} "${_ARG_VERSION}" "Version of ${_ARG_PACKAGE}" INTERNAL)

    # Set the options as an internal cached variable
    string(REPLACE ";" " " _OPTIONS "${_ARG_OPTIONS}")
    sc_global_set(${_VAR_OPTIONS} "${_OPTIONS}" "Options of ${_ARG_PACKAGE}" INTERNAL) 

    #message("#######sc_add_project_dependency: ${_ARG_PKG_NAME} (${my_pkg_version}: ${${my_pkg_version}}, ${my_TARGETs}: ${${my_TARGETs}}, ${my_OPTIONS}: ${${my_OPTIONS}})")
    # if (DEFINED _ARG_LIBRARY_PATH)
    #   sc_global_set(${my_pkg_library_path} ${_ARG_LIBRARY_PATH} "Library path of ${_ARG_PACKAGE}" INTERNAL) 
    # endif()

    # if (DEFINED _ARG_INCLUDE_DIRS)
    #   sc_global_set(${my_pkg_include_dirs} ${_ARG_INCLUDE_DIRS} "Include directories of ${_ARG_PACKAGE}" INTERNAL)
    # endif()  
endfunction()

#[[
@brief Finds and registers a package, and records its properties for later use and reporting.
       The function can search for a package or a specified target. You can also set variables names for version, include dirs or libraries. 
@details
- Dependency Tracking: All found dependencies are registered and can be queried or reported later.
- Feature Summary Integration : Found packages are described in CMake's feature summary, making it easy to review which dependencies were found and their properties.
- Automatic Property Extraction: Captures version, library path, and include directories for each dependency.
- Internal Caching: Stores dependency information in internal CMake cache variables for use in other parts of the project.
@param TARGET The target name of the package to find.
@param PACKAGE The prefix of the package, used to derive internal variable names.
@param OPTIONS Additional options for the package, such as 'REQUIRED' or 'CONFIG'.
@param ARGN Additional arguments for the package search.
]]
function(sc_find_package) 
  set(oneValueArgs TARGET PACKAGE COMPONENTS VAR_VERSION VAR_INCLUDE_DIRS VAR_LIBRARIES)
  set(multiValueArgs OPTIONS)
  
  cmake_parse_arguments(_ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  
  if (NOT DEFINED _ARG_PACKAGE) 
    string(REGEX REPLACE "::[^::]*$" "" _ARG_PACKAGE "${_ARG_TARGET}")
  endif()
  
  message(CHECK_START "Looking for package \"${_ARG_PACKAGE}\"")

  # Only try to find the package if the target is not already existing
  if(NOT TARGET ${_ARG_TARGET})
    #message(STATUS "###### find_package(${_ARG_PACKAGE}  ${_ARG_OPTIONS} COMPONENTS ${_ARG_COMPONENTS})")
    find_package(${_ARG_PACKAGE}  ${_ARG_OPTIONS} COMPONENTS ${_ARG_COMPONENTS})
  endif()

  if (DEFINED _ARG_TARGET)
    #message(STATUS "TARGET DEFINED : ${_ARG_TARGET}")
    if (TARGET ${_ARG_TARGET})
      list(APPEND _targets ${_ARG_TARGET})
    endif()
  else()
    if (NOT DEFINED _ARG_VAR_LIBRARIES)
      set(_ARG_VAR_LIBRARIES "${_ARG_PACKAGE}_LIBRARIES")
    endif()
    #message(STATUS "######## ${_ARG_PACKAGE} ${_ARG_VAR_LIBRARIES}: ${${_ARG_VAR_LIBRARIES}}" )
    list(APPEND _targets ${${_ARG_VAR_LIBRARIES}})
    list(REMOVE_DUPLICATES _targets)
  endif()
  
  list(LENGTH _targets _targets_count)
  #message(STATUS "######## The length of ${_targets} is: ${_targets_count}")
  if (_targets_count GREATER 0)
    # Get the version
    set(_pkg_version ${${_ARG_PACKAGE}_VERSION})
    if (_pkg_version MATCHES "NOTFOUND" OR _pkg_version STREQUAL "")
      if (DEFINED _ARG_VAR_VERSION)
        set(_pkg_version ${${_ARG_VAR_VERSION}})
      endif()
    endif()
    if (_pkg_version STREQUAL "")
      set(_pkg_version "NOTFOUND")
    endif()
    string(APPEND _desc "(version : ${_pkg_version})")
  endif()

  foreach(_target ${_targets})
    string(APPEND _desc "\n\t${_target}")

    # Get the library path 
    get_target_property(_pkg_libraries "${_target}" LOCATION)
    if (_pkg_libraries MATCHES "NOTFOUND")
       if (NOT DEFINED _ARG_VAR_LIBRARIES)
          set(_ARG_VAR_LIBRARIES "${_ARG_PACKAGE}_LIBRARIES")
       endif()
       #message(STATUS "######## ${_ARG_VAR_LIBRARIES} =  ${${_ARG_VAR_LIBRARIES}}")
       set(_pkg_libraries "${${_ARG_VAR_LIBRARIES}}")
    endif()
    list(REMOVE_DUPLICATES _pkg_libraries)
    foreach(_pkg_library ${_pkg_libraries})
       string(APPEND _desc "\n\t\tlib : ${_pkg_library}")
    endforeach()

    # Get the include directories 
    get_target_property(_pkg_include_dirs ${_target} INTERFACE_INCLUDE_DIRECTORIES)
    #message(STATUS "######## ${_target} INTERFACE INCLUDE : ${_pkg_include_dirs}")
    if (_pkg_include_dirs MATCHES "NOTFOUND") 
      set(_pkg_include_dirs ${${_ARG_PACKAGE}_INCLUDE_DIRS})
      #message(STATUS "######## ${_ARG_PACKAGE}_INCLUDE_DIRS : ${${_ARG_PACKAGE}_INCLUDE_DIRS}")
      list(LENGTH _pkg_include_dirs _pkg_include_dirs_count)
      if ((_pkg_include_dirs_count EQUAL 0) AND (DEFINED _ARG_VAR_INCLUDE_DIRS))
        set(_pkg_include_dirs "${${_ARG_VAR_INCLUDE_DIRS}}")
        #message(STATUS "######## ${_ARG_VAR_INCLUDE_DIRS} : ${${_ARG_VAR_INCLUDE_DIRS}}")
      endif()
    endif()
    list(REMOVE_DUPLICATES _pkg_include_dirs)
    foreach(_pkg_include_dir ${_pkg_include_dirs})
      string(APPEND _desc "\n\t\tinclude : ${_pkg_include_dir}")
    endforeach()
    #message(STATUS "######## search ${_target} : ${_desc}")
  endforeach()

  if (_targets_count GREATER 0)
    # Describe the package for the feature summary which is shown at the end of the configuration
    include(FeatureSummary)
    string(REPLACE ";" "," _desc "${_desc}")
    # Manipulate CMAKE_MESSAGE_LOG_LEVEL to avoid duplicated set_package_properties call warning
    set(_log_level ${CMAKE_MESSAGE_LOG_LEVEL})
    set(CMAKE_MESSAGE_LOG_LEVEL "ERROR")
    if (_ARG_OPTIONS MATCHES "REQUIRED")
      set(_summary_type REQUIRED)
    else()
      set(_summary_type RECOMMENDED)
    endif()
    set_package_properties(${_ARG_PACKAGE} PROPERTIES DESCRIPTION "${_desc}" TYPE REQUIRED)
    set(CMAKE_MESSAGE_LOG_LEVEL "${_log_level}")
    sc_add_project_dependency(${_ARG_PACKAGE} 
      TARGETS 
        ${_targets}  
      VERSION 
        "${_pkg_version}" 
      OPTIONS  
        "${_ARG_OPTIONS}"
    )

    message(CHECK_PASS "found with targets \"${_targets}\" ( version : ${_pkg_version} ).")
  else()  
    message(CHECK_FAIL "not found")
  endif()
  

endfunction()