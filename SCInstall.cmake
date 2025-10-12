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
@brief Retrieves the CMake target name associated with a given package name added by sc_add_project_dependency()
@param arg_pkg_name The name of the package to look up.
@param arg_out_target The variable to store the resulting target name (set in parent scope).
]]
function(sc_get_targets arg_pkg_name arg_out_targets)
  set(_ref_targets "Z_SC_PKG_${arg_pkg_name}_TARGETS")
  #message("##########sc_get_targets ${_ref_targets} : ${${_ref_targets}}")
  if ((NOT ${_ref_targets}) OR (${_ref_targets} STREQUAL ""))
    message(VERBOSE "Package ${arg_pkg_name} is not found in the project dependencies. It could not been added using add_project_dependency() before calling this function.")
    list(APPEND _targets ${arg_pkg_name})
    #message("##########sc_get_targets ${_ref_targets} is not defined, use ${_targets} instead")
    set(${arg_out_targets} ${_targets} PARENT_SCOPE)
    return()
  endif()
  list(APPEND _targets "${${_ref_targets}}")
  set(${arg_out_targets} ${_targets} PARENT_SCOPE)
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
    sc_get_targets(${_pkg_name} _pkg_targets)
    foreach(_pkg_target ${_pkg_targets})
      #message("########### sc_collect_targets: ${_pkg_target} for package ${_pkg_name}")
      if (NOT TARGET ${_pkg_target})
        message(VERBOSE "`${_pkg_target}` is not currently a target. Unless `${_pkg_target}` will be added later, this may cause the build to fail.")
      endif()
      list(APPEND _link_targets ${_pkg_target})
    endforeach()  
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

  set(_config_find_dependencies_code "")
  set(_ref_config_find_dependencies "Z_SC_${_ARG_PROJECT_NAME}_CONFIG_FIND_DEPENDENCIES")
  foreach(_dep ${${_ref_config_find_dependencies}})
      string(APPEND _config_find_dependencies_code "${_dep}\n")
  endforeach() 

  include(CMakePackageConfigHelpers)
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

  set(_ref_export_targets "Z_SC_${_ARG_PROJECT_NAME}_EXPORT_TARGETS")
  if (DEFINED ${_ref_export_targets})
    list(REMOVE_DUPLICATES ${_ref_export_targets})
    install(TARGETS ${${_ref_export_targets}} 
      EXPORT ${_ARG_PROJECT_NAME}Targets DESTINATION lib
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin    
    )

    # install the configuration targets
    # install the configuration targets
    install(EXPORT ${_ARG_PROJECT_NAME}Targets
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

  include("${SIDECMAKE_DIR}/SCUtilities.cmake")
  sc_internal_list_append(Z_SC_ALL_PROJECTS ${_ARG_PROJECT_NAME})  

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
    INSTALLED_INCLUDE_DIRS # The header directories to be installed, these directories will be installed to ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME} 
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
  target_include_directories(${_ARG_TARGET_NAME}
    PRIVATE 
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      ${_ARG_PRIVATE_INCLUDE_DIRS}
  )

  target_include_directories(${_ARG_TARGET_NAME} 
    INTERFACE
      ${_ARG_INTERFACE_INCLUDE_DIRS}
    PUBLIC
      ${_ARG_PUBLIC_INCLUDE_DIRS}
    PRIVATE 
      $<BUILD_INTERFACE:${_CONFIGURED_INCLUDE_INSTALL_DIR}>
  )

  foreach(_inc ${_ARG_INSTALLED_INCLUDE_DIRS})
      if (IS_ABSOLUTE ${_inc})
        install(DIRECTORY ${_inc} DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ARG_PROJECT_NAME}")
      else()
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/${_inc} DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ARG_PROJECT_NAME}")
      endif()
  endforeach()    

  sc_collect_targets(_ARG_INTERFACE_DEPENDENCIES _interface_link_targets)
  sc_collect_targets(_ARG_PUBLIC_DEPENDENCIES _public_link_targets)
  sc_collect_targets(_ARG_PRIVATE_DEPENDENCIES _private_link_targets)

  target_link_libraries(${_ARG_TARGET_NAME}  PRIVATE  ${_system_library_options})

  target_link_system_libraries(${_ARG_TARGET_NAME}
    INTERFACE ${_interface_link_targets}
    PUBLIC ${_public_link_targets}
    PRIVATE ${_private_link_targets}
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

  # Register the dependencies for the Config.cmake.in
  set(_config_find_dependencies "")

  if (_ARG_LINK_TYPE STREQUAL "STATIC") 
    list(APPEND _all_dependencies 
        ${_ARG_INTERFACE_DEPENDENCIES} 
        ${_ARG_PUBLIC_DEPENDENCIES} 
        # ${_ARG_PRIVATE_DEPENDENCIES} # dont include private dependencies for static library
    )
    foreach(_dep ${_all_dependencies}) 
      set(_dep_version "${Z_SC_PKG_${_dep}_VERSION}")
      set(_dep_options "${Z_SC_PKG_${_dep}_OPTIONS}")
      list(APPEND _config_find_dependencies "sc_find_dependency(\"${_dep}\" \"${_dep_version}\" ${_dep_options})")
    endforeach()
  endif()
  set(_ref_config_find_dependencies "Z_SC_${_ARG_PROJECT_NAME}_CONFIG_FIND_DEPENDENCIES")
  if (DEFINED ${_ref_config_find_dependencies})
      list(PREPEND _config_find_dependencies "${${_ref_config_find_dependencies}}")
  endif()
  set(${_ref_config_find_dependencies} "${_config_find_dependencies}" CACHE INTERNAL "The find dependencies code for the project \"${_ARG_PROJECT_NAME}\" config.cmake.in")

  # Register the targets for export later in sc_install_project()
  set(_ref_export_targets "Z_SC_${_ARG_PROJECT_NAME}_EXPORT_TARGETS")
  set(_export_targets "")
  if (DEFINED ${_ref_export_targets})
      list(PREPEND _export_targets ${${_ref_export_targets}})
  endif()
  list(APPEND _export_targets ${_ARG_TARGET_NAME})
  set(${_ref_export_targets} ${_export_targets} CACHE INTERNAL "The export targets for the project \"${_ARG_PROJECT_NAME}\"")


  include(${SIDECMAKE_DIR}/SCFindPackage.cmake)

  # register the library as a project dependency for internal cross-dependency management
  sc_add_project_dependency("${_ARG_PROJECT_NAME}::${_ARG_TARGET_NAME}" 
    TARGETS 
      ${_ARG_TARGET_NAME} 
    VERSION 
      "${PROJECT_VERSION}"
  )

  include("${SIDECMAKE_DIR}/SCUtilities.cmake")
  sc_internal_list_append(Z_SC_ALL_TARGETS ${_ARG_TARGET_NAME})

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
  install(TARGETS ${_ARG_TARGET_NAME}
    BUNDLE DESTINATION "${CMAKE_INSTALL_PREFIX}/Applications"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin    
  )

  include("${SIDECMAKE_DIR}/SCUtilities.cmake")
  sc_internal_list_append(Z_SC_ALL_TARGETS ${_ARG_TARGET_NAME})

endfunction(sc_install_executable)