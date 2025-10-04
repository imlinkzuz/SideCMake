include(${SIDECMAKE_DIR}/SCUtilities.cmake)

#[[
@brief Registers a project dependency for later use and tracking.
@details The function appends the dependency information to an internal cache variable for project-wide access.
@param ARG_PKG_NAME The name of the package or dependency.
@param ARG_PKG_TARGET The CMake target associated with the package.
@param ARG_PKG_VERSION The version of the package.
@param ARG_PKG_OPTIONS Additional options for the package, such as 'REQUIRED' or 'CONFIG'.
]]
function(sc_add_project_dependency ARG_PKG_NAME ARG_PKG_TARGET ARG_PKG_VERSION ARG_PKG_OPTIONS) 

    #cmake_parse_arguments(ARG "" "LIBRARY_PATH" "INCLUDE_DIRS" ${ARGN})
    set(my_pkg_target Z_SC_PKG_${ARG_PKG_PREFIX}_TARGET)
    set(my_pkg_options Z_SC_PKG_${ARG_PKG_PREFIX}_OPTIONS)
    set(my_pkg_version       Z_SC_PKG_${ARG_PKG_PREFIX}_VERSION)
    set(my_pkg_library_path  Z_SC_PKG_${ARG_PKG_PREFIX}_LIBRARY_PATH)
    set(my_pkg_include_dirs  Z_SC_PKG_${ARG_PKG_PREFIX}_INCLUDE_DIRS)

    # Set the target as an internal cached variable
    sc_global_set(${my_pkg_target} "${ARG_PKG_TARGET}" "Target of ${ARG_PKG_PREFIX}" INTERNAL) 

    # Set the version as an internal cached variable
    sc_global_set(${my_pkg_version} "${ARG_PKG_VERSION}" "Version of ${ARG_PKG_PREFIX}" INTERNAL)

    # Set the options as an internal cached variable
    string(REPLACE ";" " " _pkg_options "${ARG_PKG_OPTIONS}")
    sc_global_set(${my_pkg_options} "${_pkg_options}" "Options of ${ARG_PKG_PREFIX}" INTERNAL) 

    # if (DEFINED ARG_LIBRARY_PATH)
    #   sc_global_set(${my_pkg_library_path} ${ARG_LIBRARY_PATH} "Library path of ${ARG_PKG_PREFIX}" INTERNAL) 
    # endif()

    # if (DEFINED ARG_INCLUDE_DIRS)
    #   sc_global_set(${my_pkg_include_dirs} ${ARG_INCLUDE_DIRS} "Include directories of ${ARG_PKG_PREFIX}" INTERNAL)
    # endif()  
endfunction()

#[[
@brief Finds and registers a package, and records its properties for later use and reporting.
@details
- Dependency Tracking: All found dependencies are registered and can be queried or reported later.
- Feature Summary Integration : Found packages are described in CMake's feature summary, making it easy to review which dependencies were found and their properties.
- Automatic Property Extraction: Captures version, library path, and include directories for each dependency.
- Internal Caching: Stores dependency information in internal CMake cache variables for use in other parts of the project.
@param PKG_TARGET The target name of the package to find.
@param PKG_PREFIX The prefix of the package, used to derive internal variable names.
@param PKG_OPTIONS Additional options for the package, such as 'REQUIRED' or 'CONFIG'.
@param ARGN Additional arguments for the package search.
]]
function(sc_find_package) 
  set(oneValueArgs PKG_TARGET PKG_PREFIX)
  set(multiValueArgs PKG_OPTIONS)
  cmake_parse_arguments(ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if (NOT ARG_PKG_PREFIX) 
    string(REGEX REPLACE "::[^::]*$" "" ARG_PKG_PREFIX "${ARG_PKG_TARGET}")
  endif()

  # Only try to find the package if the target is not already existing
  if(NOT TARGET ${ARG_PKG_TARGET})
    #message(STATUS "Looking for package ${ARG_PKG_PREFIX} (${ARG_PKG_TARGET})")
    find_package(${ARG_PKG_PREFIX}  ${ARG_PKG_OPTIONS})
  endif()

  if (TARGET ${ARG_PKG_TARGET}) 

    # Get the version
    set(my_pkg_version_tmp ${${ARG_PKG_PREFIX}_VERSION})
    if (NOT my_pkg_version_tmp)
      set(my_pkg_version_tmp "version-not-found")
    endif()



    # Get the library path 
    get_target_property(my_pkg_library_path_tmp ${ARG_PKG_TARGET} LOCATION)

    # Get the include directories 
    get_target_property(my_pkg_include_dirs_tmp ${ARG_PKG_TARGET} INTERFACE_INCLUDE_DIRECTORIES)


    # Describe the package for the feature summary which is shown at the end of the configuration
    set(my_pkg_properties_desc "")
    if (my_pkg_version_tmp)
       set(my_pkg_properties_desc "(version == ${my_pkg_version_tmp})")
    endif()

    if (my_pkg_library_path_tmp)
      STRING(APPEND my_pkg_properties_desc "\n\tlib = ${my_pkg_library_path_tmp}")
    endif()

    if (my_pkg_include_dirs_tmp)
      STRING(APPEND my_pkg_properties_desc "\n\tinclude = ${my_pkg_include_dirs_tmp}") 
    endif()

    # Set the package properties for the feature_summary
    message(STATUS "Found package ${ARG_PKG_PREFIX} ${my_pkg_properties_desc}")
    string(REPLACE ";" "," my_pkg_properties_desc "${my_pkg_properties_desc}")
    include(FeatureSummary)
    set_package_properties(${ARG_PKG_PREFIX} PROPERTIES DESCRIPTION "${my_pkg_properties_desc}" TYPE REQUIRED)


    sc_add_project_dependency(${ARG_PKG_PREFIX} ${ARG_PKG_TARGET}  "${my_pkg_version_tmp}" "${ARG_PKG_OPTIONS}")
  endif()  
endfunction()