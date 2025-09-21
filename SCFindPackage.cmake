include(FeatureSummary)

#[[
@brief Registers a project dependency for later use and tracking.
@details The function appends the dependency information to an internal cache variable for project-wide access.
@param ARG_PKG_NAME The name of the package or dependency.
@param ARG_PKG_TARGET The CMake target associated with the package.
@param ARG_PKG_VERSION The version of the package.
@param ARG_PKG_OPTIONS Additional options for the package, such as 'REQUIRED' or 'CONFIG'.
]]
function(sc_add_project_dependency ARG_PKG_NAME ARG_PKG_TARGET ARG_PKG_VERSION ARG_PKG_OPTIONS) 

    list(APPEND _project_dependencies ${ARG_PKG_NAME})
    list(APPEND _project_dependencies ${ARG_PKG_TARGET})
    list(APPEND _project_dependencies ${ARG_PKG_VERSION})
    list(APPEND _project_dependencies ${ARG_PKG_OPTIONS})

    set(SC_PROJECT_DEPENDENCY_${ARG_PKG_NAME} ${_project_dependencies} CACHE INTERNAL "List of project dependencies")
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

  string(TOUPPER ${ARG_PKG_PREFIX} my_prefix_upper)

  if(NOT TARGET ${ARG_PKG_TARGET})
    #message(STATUS "Looking for package ${ARG_PKG_PREFIX} (${ARG_PKG_TARGET})")
    find_package(${ARG_PKG_PREFIX}  ${ARG_PKG_OPTIONS})
  endif()
  if (${ARG_PKG_PREFIX}_FOUND) 
    set(my_pkg_version       sc_${my_prefix_upper}_VERSION)
    set(my_pkg_library_path  sc_${my_prefix_upper}_LIBRARY_PATH)
    set(my_pkg_include_dirs  sc_${my_prefix_upper}_INCLUDE_DIRS)


    # Get the version
    set(my_pkg_version_tmp ${${ARG_PKG_PREFIX}_VERSION})
    if (NOT my_pkg_version_tmp)
      set(my_pkg_version_tmp "version-not-found")
    endif()

    set(${my_pkg_version} "${my_pkg_version_tmp}" CACHE INTERNAL "Version of ${ARG_PKG_PREFIX}")

    # If the target is not existing, we cannot get its properties
    if (TARGET ${ARG_PKG_TARGET}) 
      # Get the library
      get_target_property(my_pkg_library_path_tmp ${ARG_PKG_TARGET} LOCATION)
      set(${my_pkg_library_path} ${my_pkg_library_path_tmp} CACHE INTERNAL "Library path of ${ARG_PKG_PREFIX}")

      # Get the include directory path
      get_target_property(my_pkg_include_dirs_tmp ${ARG_PKG_TARGET} INTERFACE_INCLUDE_DIRECTORIES)
      set(${my_pkg_include_dirs} ${my_pkg_include_dirs_tmp} CACHE INTERNAL "Include directories of ${ARG_PKG_PREFIX}")
    endif()



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
    set_package_properties(${ARG_PKG_PREFIX} PROPERTIES DESCRIPTION "${my_pkg_properties_desc}" TYPE REQUIRED)
    string(REPLACE ";" " " _pkg_options "${ARG_PKG_OPTIONS}")

    sc_add_project_dependency(${ARG_PKG_PREFIX} ${ARG_PKG_TARGET}  "${my_pkg_version_tmp}" ${_pkg_options})
  endif()  
endfunction()