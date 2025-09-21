#[[
@file SCInstall.cmake

@brief 
This CMake module provides a set of utility functions to standardize and 
simplify the installation and packaging of C++ projects, libraries, and executables. 
It is designed to automate common CMake patterns for modern C++ projects, 
including dependency management, configuration file generation, and platform-specific packaging.

@note
- These functions expect certain project conventions, see SCFindPackage.cmake
- Designed for use in modern CMake projects (CMake 3.21+).
]]



#[[
@brief Retrieves the CMake target name associated with a given package name added by sc_add_project_dependency()
@param ARG_PKG_NAME The name of the package to look up.
@param ARG_OUT_TARGET_NAME The variable to store the resulting target name (set in parent scope).
]]
function(sc_get_target_name ARG_PKG_NAME ARG_OUT_TARGET_NAME)
  set(_dependency_var_name "SC_PROJECT_DEPENDENCY_${ARG_PKG_NAME}")
  if (NOT DEFINED ${_dependency_var_name})
    message(VERBOSE "Package ${ARG_PKG_NAME} is not found in the project dependencies. It could not been added using add_project_dependency() before calling this function.")
    set(${ARG_OUT_TARGET_NAME} ${ARG_PKG_NAME} PARENT_SCOPE)
    return()
  endif()  
  list(GET ${_dependency_var_name} 1 _target_name)
  set(${ARG_OUT_TARGET_NAME} ${_target_name} PARENT_SCOPE)
endfunction()

function(sc_func IN_DIRS OUT_DIRS)
endfunction()

function(sc_normalize_include_dirs IN_DIRS OUT_DIRS)
  set(_inc_dirs "")
  foreach(_inc ${IN_DIRS})
    # make include absolute
    if (NOT IS_ABSOLUTE ${_inc}) 
      set(_absolute_inc "${CMAKE_SOURCE_DIR}/${_inc}")
    endif()
    list(APPEND _inc_dirs ${_absolute_inc})
  endforeach()
  set(${OUT_DIRS} "${_inc_dirs}" PARENT_SCOPE)
endfunction()  

function(sc_remove_first_substring MY_STRING SEARCH_STRING RESULT_STRING)
  # Check if the substring exists in the string
  string(FIND "${MY_STRING}" "${SEARCH_STRING}" START_INDEX)
  string(LENGTH "${SEARCH_STRING}" _search_string_length)
  # If the substring is not found, keep the original string
  set(_result_string ${MY_STRING})
  if(START_INDEX GREATER_EQUAL 0)
    math(EXPR START_INDEX "${START_INDEX} + ${_search_string_length}")
    string(SUBSTRING "${MY_STRING}" ${START_INDEX} -1 _result_string)
    string(FIND "${_result_string}" "/" START_INDEX_2)
    if (START_INDEX_2 EQUAL 0)
      string(SUBSTRING "${_result_string}" 1 -1 _result_string)
    endif()

  endif()
  set(${RESULT_STRING} "${_result_string}" PARENT_SCOPE)
endfunction()


#[[
@brief 
Collects CMake target names from a list of dependency package names registered by sc_add_project_dependency()
and sets them to an output variable.
@param ARG_DEPENDENCIES The variable containing the list of package names.
@param ARG_OUT_TARGETS The variable to store the resulting list of target names (set in parent scope).
@note Pass variable names, not values. E.g.:
- Correct:
```
sc_collect_targets(_ARG_PUBLIC_DEPENDENCIES _public_link_targets)
```
- Wrong:
```
sc_collect_targets(${_ARG_PUBLIC_DEPENDENCIES} public_link_targets)
sc_collect_targets(${_ARG_PUBLIC_DEPENDENCIES} ${public_link_targets})
```
]]
function(sc_collect_targets ARG_DEPENDENCIES ARG_OUT_TARGETS)
  if (NOT DEFINED ${ARG_DEPENDENCIES})
    return()
  endif()
  set(_link_targets "")
  set(_arg_dependencies ${${ARG_DEPENDENCIES}})
  foreach(_pkg_name ${_arg_dependencies})
    sc_get_target_name(${_pkg_name} _link_target_name)
    # target name can be a list of targets separated by space, so we need to convert it to a list, which is separated by semicolon in CMake.
    string(REPLACE " " ";" _link_target_name_1 "${_link_target_name}")
    list(APPEND _link_targets ${_link_target_name_1})
  endforeach()
  set(${ARG_OUT_TARGETS} ${_link_targets} PARENT_SCOPE)
endfunction()


#[[
@brief Sets up installation rules and generates CMake configuration files for the project.
@details
- Generates and installs Config.cmake and ConfigVersion.cmake for package configuration.
- Installs CMake export targets.
- Generates and installs a config.hpp header for project configuration.
@notes
- This function is intended to be called after defining the project and its targets.
@param ARG_PROJECT_NAME The name of the project, defaults to ${PROJECT_NAME}.
@param ARG_COMPATIBILITY The compatibility mode used in write_basic_package_version_file(), defaults to AnyNewerVersion.
]]
function(sc_install_project)

  set(_oneValueArgs  
    PROJECT_NAME # The project name, default to ${PROJECT_NAME}
    COMPATIBILITY # The compatibility mode used in write_basic_package_version_file(), defauts to AnyNewerVersion
  )

  cmake_parse_arguments(
    _ARG
    ""
    "${_oneValueArgs}"
    ""
    "${ARGN}")

  if (NOT _ARG_PROJECT_NAME)
    set(_ARG_PROJECT_NAME ${PROJECT_NAME})
  endif()

  if (NOT _ARG_COMPATIBILITY)
    set(_ARG_COMPATIBILITY "AnyNewerVersion")
  endif()

  if (NOT PROJECT_NAME STREQUAL ${_ARG_PROJECT_NAME})
    message(STATUS "======================================================================")
    message(FATAL_ERROR "Please use project(\"${_ARG_PROJECT_NAME}\") to set a project first. Current project scope is \"${PROJECT_NAME}\"")
  endif()

  # Generate config.cmake 
  ## Developer can provide his own Config.cmake.in  in ${CMAKE_CURRENT_SOURCE_DIR}/configured_file, 
  ## if not, ${SIDECMAKE_DIR}/configured_file/Config.cmake.in will be used.
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/configured_file/Config.cmake.in)
      set(_configured_file_config_cmake_in "${CMAKE_CURRENT_SOURCE_DIR}/configured_file/Config.cmake.in")
  else()
      set(_configured_file_config_cmake_in "${SIDECMAKE_DIR}/configured_file/Config.cmake.in")
  endif()

  configure_package_config_file(${_configured_file_config_cmake_in}
    "${CMAKE_CURRENT_BINARY_DIR}/${_ARG_PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_ARG_PROJECT_NAME}
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
  )
  
  # generate the version file for the config file
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${_ARG_PROJECT_NAME}ConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY ${_ARG_COMPATIBILITY}
  )

  # install the generated configuration files
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${_ARG_PROJECT_NAME}Config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${_ARG_PROJECT_NAME}ConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_ARG_PROJECT_NAME}
  )

  # install the configuration targets
  set(_export_target "${_ARG_PROJECT_NAME}Targets")
  if (${export_target})
    install(EXPORT ${export_target}
      FILE ${_ARG_PROJECT_NAME}Targets.cmake
      NAMESPACE ${_ARG_PROJECT_NAME}::
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${_ARG_PROJECT_NAME}  
    )
  endif()
  set(_CONFIGURED_INCLUDE_INSTALL_DIR "${PROJECT_BINARY_DIR}/configured_files/include")

  # Generate config.h
  ## try to use configured_file in ${CMAKE_CURRENT_SOURCE_DIR} first, then fallback to ${SIDECMAKE_DIR}/configured_file/config.hpp.in
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/configured_file/config.hpp.in) 
    set(_configured_file_config_hpp_in "${CMAKE_CURRENT_SOURCE_DIR}/configured_file/config.hpp.in")
  else()
    set(_configured_file_config_hpp_in "${SIDECMAKE_DIR}/configured_file/config.hpp.in")
  endif()

  set(_TARGET_CONFIGURED_CONFIG_FILE "${_CONFIGURED_INCLUDE_INSTALL_DIR}/${_ARG_PROJECT_NAME}/config.hpp")
  message(STATUS "Generating config.h at ${_TARGET_CONFIGURED_CONFIG_FILE}")
  configure_file(${_configured_file_config_hpp_in} ${_TARGET_CONFIGURED_CONFIG_FILE} ESCAPE_QUOTES)

  install(FILES
    ${_TARGET_CONFIGURED_CONFIG_FILE}
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ARG_PROJECT_NAME}")

endfunction(sc_install_project)

#[[
@brief Defines, configures, and installs a library target with modern CMake best practices.
@details 
- Adds the library target and sets up include directories and dependencies.
- Installs the library and its headers.
- Generates and installs an export header for symbol visibility.(e.g., for MSVC).
- Handles static/shared linking and dependency propagation.
- Registers the library as a project dependency.
@param PROJECT_NAME The name of the project, defaults to ${PROJECT_NAME}.
@param TARGET_NAME The name of the target library to be created.
@param LINK_TYPE The type of the library to be created: 'AUTO', 'STATIC', or 'SHARED'. Defaults to 'AUTO', which is determined by the BUILD_SHARED_LIBS variable.
@param TARGET_PROPERTIES Properties to set for the target library.
@param INTERFACE_SOURCES,PUBLIC_SOURCES,PRIVATE_SOURCES Source files for the target library, categorized by visibility.
@param INTERFACE_DEPENDENCIES, PUBLIC_DEPENDENCIES, PRIVATE_DEPENDENCIES Dependencies for the target library, categorized by visibility.
@param INTERFACE_INCLUDE_DIRS Interface include directories of the target library, which will be installed to the install include directory. Only the path without generator expressions will be installed automatically. Path with generator expressions(such as BUILD_INTERFACE and INSTALL_INTERFACE) will be added to the target but not installed. 
@param PUBLIC_INCLUDE_DIRS Public include directories of the target library, which will be installed to the install include directory. Only the path without generator expressions will be installed automatically. Path with generator expressions(such as BUILD_INTERFACE and INSTALL_INTERFACE) will be added to the target but not installed. 
@param PRIVATE_INCLUDE_DIRS Include directories for the target library, categorized by visibility.
]]
function(sc_install_library)

# Set default options
  # *****************************************
  # Set the requirements and defaults
  # *****************************************
  cmake_minimum_required( VERSION 3.21 FATAL_ERROR )
  cmake_policy(SET CMP0103 NEW) # disallow multiple calls with the same NAME

  include(CMakePackageConfigHelpers)
  include(GNUInstallDirs)
  include(${SIDECMAKE_DIR}/SystemLink.cmake)

  # *****************************************
  # Parse the arguments
  # *****************************************
  set(_oneValueArgs  
    PROJECT_NAME # The project name, if not specified, it will use the ${PROJECT_NAME}
    TARGET_NAME  # The target name, this is the name of the library to be created
    LINK_TYPE    # 'AUTO':determined by BUILD_SHARED_LIBS. 'STATIC': build static library. 'SHARED': build shared library. Default value is 'AUTO'.
  )
  
  set(_multiValueArgs 
    TARGET_PROPERTIES # The properties of the target, these properties will be set to the target
    INTERFACE_SOURCES # The interface sources of the target, these sources will be used by the target that links to this target
    PUBLIC_SOURCES    # The public sources of the target, these sources will be used by the target that links to this target
    PRIVATE_SOURCES   # The private sources of the target, these sources will be used only by this target
    INTERFACE_DEPENDENCIES # The interface dependencies of the target, these dependencies will be used by the target that links to this target
    PUBLIC_DEPENDENCIES  # The public dependencies of the target, these dependencies will be used by the target that links to this target
    PRIVATE_DEPENDENCIES # The private dependencies of the target, these dependencies will be used only by this target
    INTERFACE_INCLUDE_DIRS # The interface include directories of the target, these directories will be used by the target that links to this target
    PUBLIC_INCLUDE_DIRS # The public include directories of the target, these directories will be used by the target that links to this target
    PRIVATE_INCLUDE_DIRS # The private include directories of the target, these directories will be used only by this target
   )

   set(_optionalArgs
     SYSTEM_LIBRARY
   )

  cmake_parse_arguments(
    _ARG
    ""
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  if (NOT _ARG_TARGET_NAME)
    message(FATAL_ERROR "TARGET_NAME must be specified")
  endif()

  if (NOT _ARG_PROJECT_NAME)
    set(_ARG_PROJECT_NAME ${PROJECT_NAME})
  endif()
  
  if (NOT _ARG_LINK_TYPE)
    set(_ARG_LINK_TYPE "AUTO")
  endif()

  if (_ARG_LINK_TYPE STREQUAL "AUTO")
    if (BUILD_SHARED_LIBS) 
      set(_ARG_LINK_TYPE "SHARED")
    else()
      set(_ARG_LINK_TYPE "STATIC")
    endif()  
  endif()
  
  # *****************************************
  # Add library and set the properties
  # *****************************************
  add_library(${_ARG_TARGET_NAME})

  if (NOT TARGET ${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME})
    add_library(${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME} ALIAS ${_ARG_TARGET_NAME})
  endif()

  if (_ARG_TARGET_PROPERTIES)
    #message(STATUS "Setting properties for target ${_ARG_TARGET_NAME}: ${_ARG_TARGET_PROPERTIES}")
    set_target_properties(${_ARG_TARGET_NAME} PROPERTIES ${_ARG_TARGET_PROPERTIES})
  endif()

  # *****************************************
  # Add sources, include directories and dependencies
  # *****************************************
  target_sources(${_ARG_TARGET_NAME}
    INTERFACE ${_ARG_INTERFACE_SOURCES}
    PUBLIC ${_ARG_PUBLIC_SOURCES}
    PRIVATE ${_ARG_PRIVATE_SOURCES}
  )

  set(_CONFIGURED_INCLUDE_INSTALL_DIR "${PROJECT_BINARY_DIR}/configured_files/include")
  
  # *****************************************
  # Install the public header files
  # *****************************************
  if (DEFINED _ARG_INTERFACE_INCLUDE_DIRS)
    sc_normalize_include_dirs(${_ARG_INTERFACE_INCLUDE_DIRS} _ARG_INTERFACE_INCLUDE_DIRS)
  endif()  

  if (DEFINED _ARG_PUBLIC_INCLUDE_DIRS)
    sc_normalize_include_dirs(${_ARG_PUBLIC_INCLUDE_DIRS} _ARG_PUBLIC_INCLUDE_DIRS)
  endif()

  if (DEFINED _ARG_PRIVATE_INCLUDE_DIRS)
    sc_normalize_include_dirs(${_ARG_PRIVATE_INCLUDE_DIRS} _ARG_PRIVATE_INCLUDE_DIRS)
  endif()

  target_include_directories(${_ARG_TARGET_NAME}
    PRIVATE 
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      ${_ARG_PRIVATE_INCLUDE_DIRS}
  )

  target_include_directories(${_ARG_TARGET_NAME} 
    SYSTEM PRIVATE 
      $<BUILD_INTERFACE:${_CONFIGURED_INCLUDE_INSTALL_DIR}>
  )

  set(_source_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/include)
  foreach(_inc ${_ARG_PUBLIC_INCLUDE_DIRS})
      if ((_inc MATCHES "^\\$\\<BUILD_INTERFACE:") OR (_inc MATCHES "^\\$\\<INSTALL_INTERFACE:")) 
          target_include_directories(${_ARG_TARGET_NAME} 
              PUBLIC 
              ${_inc})
      else()
          sc_remove_first_substring(${_inc} ${_source_include_dirs} _inc_short)
          target_include_directories(${_ARG_TARGET_NAME} 
              PUBLIC 
              $<BUILD_INTERFACE:${_inc}> 
              $<INSTALL_INTERFACE:include/${_inc_short}>)
          get_filename_component(_parent_inc ${_inc} DIRECTORY)
          install(DIRECTORY ${_inc} DESTINATION "${_parent_inc}")
      endif()
  endforeach()

  foreach(_inc ${_ARG_INTERFACE_INCLUDE_DIRS})
      if ((_inc MATCHES "^\\$\\<BUILD_INTERFACE:") OR (_inc MATCHES "^\\$\\<INSTALL_INTERFACE:")) 
          target_include_directories(${_ARG_TARGET_NAME} 
              INTERFACE
              ${_inc})
      else()
          sc_remove_first_substring(${_inc} ${_source_include_dirs} _inc_short)
          target_include_directories(${_ARG_TARGET_NAME} 
              INTERFACE 
              $<BUILD_INTERFACE:${_inc}> 
              $<INSTALL_INTERFACE:include/${_inc_short}>)
          get_filename_component(_parent_inc ${_inc} DIRECTORY)
          install(DIRECTORY ${_inc} DESTINATION "${_parent_inc}")
      endif()
  endforeach()


  sc_collect_targets(_ARG_INTERFACE_DEPENDENCIES _interface_link_targets)
  sc_collect_targets(_ARG_PUBLIC_DEPENDENCIES _public_link_targets)
  sc_collect_targets(_ARG_PRIVATE_DEPENDENCIES _private_link_targets)

  if (_ARG_SYSTEM_LIBRARY)
     set(_system_library_options SC_BUILD_OPTIONS SC_BUILD_WARNINGS)
  else()
     set(_system_library_options SC_BUILD_OPTIONS)
  endif()   

  target_link_libraries(${_ARG_TARGET_NAME}  PRIVATE  ${_system_library_options})

  target_link_system_libraries(${_ARG_TARGET_NAME}
    INTERFACE ${_interface_link_targets}
    PUBLIC ${_public_link_targets}
    PRIVATE ${_private_link_targets}
  )

  # *****************************************
  # Install the generated library files
  # *****************************************
  install(TARGETS ${_ARG_TARGET_NAME} ${_system_library_options}
    EXPORT ${_ARG_PROJECT_NAME}Targets DESTINATION lib
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin    
  )

  # Generate MSVC export header
  set(_TARGET_EXPORT_HEADER_FILE "${_CONFIGURED_INCLUDE_INSTALL_DIR}/${_ARG_PROJECT_NAME}/${_ARG_TARGET_NAME}_export.hpp")
  string(TOUPPER "${_ARG_PROJECT_NAME}_" _TARGET_EXPORT_PREFIX_NAME)
  include(GenerateExportHeader)
  generate_export_header(${_ARG_TARGET_NAME} EXPORT_FILE_NAME ${_TARGET_EXPORT_HEADER_FILE} PREFIX_NAME ${_TARGET_EXPORT_PREFIX_NAME})
  install(FILES
    ${_TARGET_EXPORT_HEADER_FILE}
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ARG_PROJECT_NAME}"
  )

  # *****************************************
  # Install the configuration targets
  # *****************************************
  # generate the config file that includes the exports
  # Prepare the dependencies for the config file
  set(_CONFIG_FIND_DEPENDENCY_ARGS "")
  if (_ARG_LINK_TYPE STREQUAL "STATIC") 
    set(_CONFIG_STATIC_BUILD NO)
  else()
    set(_CONFIG_STATIC_BUILD YES)
  endif()  

  if (_ARG_LINK_TYPE STREQUAL "STATIC") 
    list(APPEND _all_dependencies ${_ARG_INTERFACE_DEPENDENCIES} ${_ARG_PUBLIC_DEPENDENCIES} ${_ARG_PRIVATE_DEPENDENCIES} )
    foreach(_dep ${_all_dependencies}) 
      set(_dep_var_name "SC_PROJECT_DEPENDENCY_${_dep}")
      #message(STATUS "--------------SC_PROJECT_DEPENDENCY_${_dep}: ${${_dep_var_name}}")
      list(GET ${_dep_var_name} 2 _dep_version) 
      list(GET ${_dep_var_name} 3 _dep_options)
      list(APPEND _CONFIG_FIND_DEPENDENCY_ARGS "${_dep} ${_dep_version} ${_dep_options}")
    endforeach()
  endif()
  #unset(_CONFIG_FIND_DEPENDENCY_ARGS)
  #unset(_CONFIG_STATIC_BUILD)

  include(${SIDECMAKE_DIR}/SCFindPackage.cmake)
  sc_add_project_dependency("${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME}" ${_ARG_TARGET_NAME} "${PROJECT_VERSION}" "")

endfunction(sc_install_library)  

#[[
@brief Defines, configures, and installs an executable target, with support for platform-specific packaging.
@details
- Adds the executable target and sets up include directories and dependencies.
- Handles platform-specific packaging(Windows, Linux, macOS).
- Installs the executable and its dpendencies(shared library) and resources.
@param PROJECT_NAME The name of the project, defaults to ${PROJECT_NAME}.
@param TARGET_NAME The name of the target executable to be created.
@param MANIFESTS Manifests to be added to the target executable, e.g., "app.manifest"
@param OPTIONS Options for the add_executable() command, e.g., "WIN32", "MACOSX_BUNDLE"
@param TARGET_PROPERTIES Properties to set for the target executable.
@param INTERFACE_SOURCES, PUBLIC_SOURCES, PRIVATE_SOURCES Source files for the target executable, categorized by visibility.  
@param INTERFACE_DEPENDENCIES, PUBLIC_DEPENDENCIES, PRIVATE_DEPENDENCIES Dependencies for the target executable, categorized by visibility.
@param INTERFACE_INCLUDE_DIRS, PUBLIC_INCLUDE_DIRS, PRIVATE_INCLUDE_DIRS Include directories for the target executable, categorized by visibility.
@param SHARED_DEPENDENCIES Shared libraries to bundle with the executable, which will be copied to the executable's directory on build and install.
@param FONTS Fonts to be copied to the resources/fonts directory of the target executable.
]]
function(sc_install_executable)
# Set default options
  # *****************************************
  # Set the requirements and defaults
  # *****************************************
  cmake_minimum_required( VERSION 3.21 FATAL_ERROR )
  cmake_policy(SET CMP0103 NEW) # disallow multiple calls with the same NAME

  include(CMakePackageConfigHelpers)
  include(GNUInstallDirs)
  include(${SIDECMAKE_DIR}/SystemLink.cmake)

  # *****************************************
  # Parse the arguments
  # *****************************************
  set(_oneValueArgs  
    PROJECT_NAME # The project name, default to ${PROJECT_NAME}
    TARGET_NAME  # The target name, this is the name of the project to be created
    MANIFESTS # The manifests to be added to the target
    ICON  # The icon to be added to the target
  )

  set(_multiValueArgs 
    OPTIONS           # The options of add_executable
    TARGET_PROPERTIES # The properties of the target, these properties will be set to the target
    INTERFACE_SOURCES # The interface sources of the target, these sources will be used by the target that links to this target
    PUBLIC_SOURCES    # The public sources of the target, these sources will be used by the target that links to this target
    PRIVATE_SOURCES   # The private sources of the target, these sources will be used only by this target
    PUBLIC_DEPENDENCIES  # The public dependencies of the target, these dependencies will be used by the target that links to this target
    PRIVATE_DEPENDENCIES # The private dependencies of the target, these dependencies will be used only by this target
    INTERFACE_INCLUDE_DIRS # The interface include directories of the target, these directories will be used by the target that links to this target
    PUBLIC_INCLUDE_DIRS # The public include directories of the target, these directories will be used by the target that links to this target
    PRIVATE_INCLUDE_DIRS # The private include directories of the target, these directories will be used only by this target
    SHARED_DEPENDENCIES # The shared dependencies of the target, these dependencies will will be put aside with executable file. On macOS shared targets works as Framework
    FONTS # The fonts to be copied to the resources/fonts directory of the target 
    RESOURCES # The resources to be added to the target, these resources will be copied to the Resources directory of the target
   )  

  cmake_parse_arguments(
    _ARG
    ""
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")
  

  if (NOT _ARG_TARGET_NAME)
    message(FATAL_ERROR "TARGET_NAME must be specified")
  endif()

  if (NOT _ARG_PROJECT_NAME)
    set(_ARG_PROJECT_NAME ${PROJECT_NAME})
  endif()

  string(TOUPPER "${_ARG_OPTIONS}" _ARG_OPTIONS)

  # create the target executable
  add_executable(${_ARG_TARGET_NAME} ${_ARG_OPTIONS})
  if (NOT TARGET ${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME})
    add_executable(${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME} ALIAS ${_ARG_TARGET_NAME})
  endif() 

  if (_ARG_TARGET_PROPERTIES)
    set_target_properties(${_ARG_TARGET_NAME} PROPERTIES ${_ARG_TARGET_PROPERTIES})
  endif()



  # *****************************************
  # Add sources, include directories and dependencies
  # *****************************************
  target_sources(${_ARG_TARGET_NAME}
    INTERFACE ${_ARG_INTERFACE_SOURCES}
    PUBLIC ${_ARG_PUBLIC_SOURCES}
    PRIVATE ${_ARG_PRIVATE_SOURCES}
  )  

  set(_CONFIGURED_INCLUDE_INSTALL_DIR "${PROJECT_BINARY_DIR}/configured_files/include")

  target_include_directories(${_ARG_TARGET_NAME}
    PRIVATE 
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  )

  target_include_directories(${_ARG_TARGET_NAME}
    INTERFACE 
      $<INSTALL_INTERFACE:include>
    PUBLIC ${_ARG_PUBLIC_INCLUDE_DIRS}
    PRIVATE 
      ${_ARG_PRIVATE_INCLUDE_DIRS}
  )

  target_include_directories(${_ARG_TARGET_NAME} 
    SYSTEM PRIVATE 
      $<BUILD_INTERFACE:${_CONFIGURED_INCLUDE_INSTALL_DIR}>
  )

  sc_collect_targets(_ARG_INTERFACE_DEPENDENCIES _interface_link_targets)
  sc_collect_targets(_ARG_PUBLIC_DEPENDENCIES _public_link_targets)
  sc_collect_targets(_ARG_PRIVATE_DEPENDENCIES _private_link_targets)
  sc_collect_targets(_ARG_SHARED_DEPENDENCIES _private_shared_targets)

  target_link_system_libraries(${_ARG_TARGET_NAME}
    INTERFACE ${_interface_link_targets}
    PUBLIC ${_public_link_targets}
    PRIVATE ${_private_link_targets}
  )
  
  # Settings for packaging per platform
  if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if ("WIN32" IN_LIST _ARG_OPTIONS) #only if WIN32 option is set (e.g., for GUI applications)
      include(${SIDECMAKE_DIR}/packaging/Windows.cmake)
      sc_windows_install(
        PROJECT_NAME ${_ARG_PROJECT_NAME}
        TARGET_NAME ${_ARG_TARGET_NAME}
        MANIFESTS ${_ARG_MANIFESTS}
        SHARED_TARGETS ${_private_shared_targets}
        FONTS ${_ARG_FONTS}
        RESOURCES ${_ARG_RESOURCES}
        ICON ${_ARG_ICON}
        )
    endif()  
  elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
      include(${SIDECMAKE_DIR}/packaging/Linux.cmake)
      sc_linux_install(
        PROJECT_NAME ${_ARG_PROJECT_NAME}
        TARGET_NAME ${_ARG_TARGET_NAME}
        MANIFESTS ${_ARG_MANIFESTS}
        SHARED_TARGETS ${_private_shared_targets}
        FONTS ${_ARG_FONTS}
        RESOURCES ${_ARG_RESOURCES}
        ICON ${_ARG_ICON}
        )

  elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if ("MACOSX_BUNDLE" IN_LIST _ARG_OPTIONS)
      include(${SIDECMAKE_DIR}/packaging/Darwin.cmake)
      sc_darwin_install(
        PROJECT_NAME ${_ARG_PROJECT_NAME}
        TARGET_NAME ${_ARG_TARGET_NAME}
        MANIFESTS ${_ARG_MANIFESTS}
        SHARED_TARGETS ${_private_shared_targets}
        FONTS ${_ARG_FONTS}
        RESOURCES ${_ARG_RESOURCES}
        ICON ${_ARG_ICON}
        )
    endif()
  endif ()

  # *****************************************
  # Install the generated executable files
  # *****************************************
  install(TARGETS ${_ARG_TARGET_NAME} SC_BUILD_OPTIONS SC_BUILD_WARNINGS
    BUNDLE DESTINATION "${CMAKE_INSTALL_PREFIX}/Applications"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin    
  )

endfunction(sc_install_executable)