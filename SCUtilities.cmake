cmake_policy(SET CMP0183 NEW)

#[[
@file SCUtilities.cmake
@brief Utility functions for CMake projects.
]]


#[[
@brief Prints a label and value in a formatted manner.
@details Useful for producing readable, column-aligned output in CMake status messages.
@param LABEL The label to print.
@param VALUE The value to print.
]]
function(sc_print_aligned arg_label arg_value arg_output)
    set(MAX_LENGTH 28)
    string(LENGTH "${arg_label}" CURRENT_LABEL_LENGTH)
    math(EXPR _padding_length "${MAX_LENGTH} - ${CURRENT_LABEL_LENGTH}")
    if (_padding_length LESS 0)
        set(_padding_length 4)
    endif()    
    string(REPEAT " " ${_padding_length} _padding)
    set(${arg_output} "${${arg_output}}${arg_label}${_padding} ${arg_value}\n" PARENT_SCOPE)
endfunction()

#[[
@brief Dumps all CMake variables, optionally filtered by a regex pattern.
@param ARGV0 Optional regex pattern to filter variable names.
]]
function(sc_dump_all_variables)
    get_cmake_property(_variableNames VARIABLES)
    list (SORT _variableNames)
    foreach (_variableName ${_variableNames})
        if (ARGV0)
            unset(MATCHED)
            string(REGEX MATCH ${ARGV0} MATCHED ${_variableName})
            if (NOT MATCHED)
                continue()
            endif()
        endif()
        sc_print_aligned(${_variableName} ${${_variableName}})
    endforeach()
endfunction()

function(sc_print_variable arg_group arg_variables arg_output)
  set(_variables ${${arg_variables}})
  set(_output ${${arg_output}})

  foreach(_var ${${arg_variables}}) 
    if (DEFINED Z_SC_GROUP_${_var} AND Z_SC_GROUP_${_var} STREQUAL arg_group) 
      get_property(_description CACHE ${_var} PROPERTY HELPSTRING)
      sc_print_aligned("* ${_description}:" "${${_var}}" _output)
      list(REMOVE_ITEM _variables "${_var}")
    endif()
  endforeach()

  set(${arg_variables} "${_variables}" PARENT_SCOPE)
  set(${arg_output} "${_output}" PARENT_SCOPE)
endfunction()

#[[
@brief Prints a summary of the project configuration.
@notes This function is typically called at the end of the configuration process to give users a clear overview of the build environment and settings.
]]
function(sc_print_summary)
    set(_summary_text "")
    set(_groups_left "")
    set(_variables_left "")

    # find all groups
    get_cmake_property(_all_cache_vars CACHE_VARIABLES)
    foreach(_var_name ${_all_cache_vars})
        if (_var_name MATCHES "^SC_")
            list(APPEND _groups_left ${Z_SC_GROUP_${_var_name}})
            list(APPEND _variables_left ${_var_name})
        endif()
    endforeach()
    list(REMOVE_DUPLICATES _groups_left)

    string(APPEND _summary_text "# Summary #\n")
    string(APPEND _summary_text "## General ##\n")
    string(APPEND _summary_text "-----------------------------------------------------------\n")
    set(_all_projects ${Z_SC_ALL_PROJECTS})
    set(_all_targets ${Z_SC_ALL_TARGETS} )
    list(REMOVE_DUPLICATES _all_projects)
    list(REMOVE_DUPLICATES _all_targets)
    sc_print_aligned("* Projects:" "${_all_projects}" _summary_text)
    sc_print_aligned("* Targets:"  "${_all_targets}" _summary_text)
    sc_print_aligned("* Build Type:" "${CMAKE_BUILD_TYPE}" _summary_text)
    if (${BUILD_SHARED_LIBS})
      set(_LINK_TYPE "SHARED")
    else()
      set(_LINK_TYPE "STATIC")
    endif()  
    sc_print_aligned("* Link Type:" "${_LINK_TYPE}" _summary_text)

    sc_print_aligned("* Install:" "${CMAKE_INSTALL_PREFIX}" _summary_text)

    sc_print_aligned("* Target System:" "${CMAKE_SYSTEM_NAME}" _summary_text)
    sc_print_aligned("  * Arch:" "${CMAKE_SYSTEM_PROCESSOR}" _summary_text)
    sc_print_aligned("  * Bit Order:" "${CMAKE_C_BYTE_ORDER}" _summary_text)


    sc_print_aligned("* CXX Compiler:" "${CMAKE_CXX_COMPILER_ID} v${CMAKE_CXX_COMPILER_VERSION}" _summary_text)
    sc_print_aligned("  * Standard:" "${CMAKE_CXX_STANDARD} (required: ${CMAKE_CXX_STANDARD_REQUIRED})" _summary_text)
    sc_print_aligned("  * Extensions:" "${CMAKE_CXX_EXTENSIONS}" _summary_text)
    sc_print_aligned("  * Visibility:" "${CMAKE_CXX_VISIBILITY_PRESET}" _summary_text)
    sc_print_aligned("  * Flags:" "${CMAKE_CXX_FLAGS}" _summary_text)

    sc_print_aligned("* C Compiler:" "${CMAKE_C_COMPILER_ID} v${CMAKE_C_COMPILER_VERSION}" _summary_text)
    sc_print_aligned("  * Flags :" "${CMAKE_C_FLAGS}" _summary_text)

    sc_print_aligned("* Exe Linker Flags:" "${CMAKE_EXE_LINKER_FLAGS}" _summary_text)
    sc_print_aligned("* Module Linker Flags:" "${CMAKE_MODULE_LINKER_FLAGS}" _summary_text)
    sc_print_aligned("* Shared Lib Linker Flags:" "${CMAKE_SHARED_LINKER_FLAGS}" _summary_text)
    sc_print_aligned("* Static Lib Linker Flags:" "${CMAKE_STATIC_LINKER_FLAGS}" _summary_text)
    sc_print_aligned("* CMAKE_CROSSCOMPILING:" "${CMAKE_CROSSCOMPILING}" _summary_text)
    if (${CMAKE_CROSSCOMPILING})
      sc_print_aligned("  * CMAKE_CROSSCOMPILING_EMULATOR: ${CMAKE_CROSSCOMPILING_EMULATOR}" _summary_text)
    endif()
    string(APPEND _summary_text "\n## Project Info ##\n")
    string(APPEND _summary_text "-----------------------------------------------------------\n")
    sc_print_aligned("* Product:" "${SC_PRODUCT_NAME} v${SC_PRODUCT_VERSION}" _summary_text)
    list(REMOVE_ITEM _groups_left "Project")
    list(REMOVE_ITEM _variables_left SC_PRODUCT_NAME SC_PRODUCT_VERSION)
    sc_print_aligned("* Main Project:" "${SC_PROJECT_NAME} v${SC_PROJECT_VERSION}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_PROJECT_NAME SC_PROJECT_VERSION)
    sc_print_variable("Project" _variables_left _summary_text)
    
    string(APPEND _summary_text "\n## Build Configuration ##\n")
    list(REMOVE_ITEM _groups_left "Build Configuration")
    string(APPEND _summary_text "-----------------------------------------------------------\n")
    sc_print_aligned("* Developer Mode:" "${SC_ENABLE_DEVELOPER_MODE}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_DEVELOPER_MODE)
    sc_print_aligned("* Warnings As Errors:" "${SC_WARNINGS_AS_ERRORS}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_WARNINGS_AS_ERRORS)
    sc_print_aligned("* IPO:" "${SC_ENABLE_IPO}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_IPO)
    sc_print_aligned("* User Linker:" "${SC_ENABLE_USER_LINKER}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_USER_LINKER)
    sc_print_aligned("* Hardening:" "${SC_ENABLE_HARDENING}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_HARDENING)
    sc_print_aligned("* Global Hardening:" "${SC_ENABLE_GLOBAL_HARDENING}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_GLOBAL_HARDENING)
    sc_print_aligned("* Coverage:" "${SC_ENABLE_COVERAGE}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_COVERAGE)
    sc_print_aligned("* Sanitizer Address:" "${SC_ENABLE_SANITIZER_ADDRESS}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_SANITIZER_ADDRESS)
    sc_print_aligned("* Sanitizer Leak:" "${SC_ENABLE_SANITIZER_LEAK}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_SANITIZER_LEAK)
    sc_print_aligned("* Sanitizer Thread:" "${SC_ENABLE_SANITIZER_THREAD}" _summary_text) 
    list(REMOVE_ITEM _variables_left SC_ENABLE_SANITIZER_THREAD)
    sc_print_aligned("* Sanitizer Memory:" "${SC_ENABLE_SANITIZER_MEMORY}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_SANITIZER_MEMORY)
    sc_print_aligned("* Sanitizer Undefined:" "${SC_ENABLE_SANITIZER_UNDEFINED}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_SANITIZER_UNDEFINED)
    sc_print_aligned("* Unity Build:" "${SC_ENABLE_UNITY_BUILD}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_UNITY_BUILD)
    sc_print_aligned("* Clang Tidy:" "${SC_ENABLE_CLANG_TIDY}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_CLANG_TIDY)
    sc_print_aligned("* Cpp Check:" "${SC_ENABLE_CPPCHECK}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_CPPCHECK)
    sc_print_aligned("* Precompiled Headers:" "${SC_ENABLE_PCH}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_PCH)
    sc_print_aligned("* Cache:" "${SC_ENABLE_CACHE}" _summary_text)
    list(REMOVE_ITEM _variables_left SC_ENABLE_CACHE)
    sc_print_variable("Build Configuration" _variables_left _summary_text)

    string(APPEND _summary_text "\n## Testing ##\n")
    list(REMOVE_ITEM _groups_left "Testing")
    string(APPEND _summary_text "-----------------------------------------------------------\n")
    sc_print_aligned("* Build Tests:" "${BUILD_TESTING}" _summary_text)
    sc_print_aligned("* Fuzz Testing:" "${SC_BUILD_FUZZ_TESTS}" _summary_text)
    sc_print_variable("Testing" _variables_left _summary_text)
   
    foreach(_group_name ${_groups_left})
       string(APPEND _summary_text "\n## ${_group_name} ##\n")
       string(APPEND _summary_text "-----------------------------------------------------------\n")
       sc_print_variable(${_group_name} _variables_left _summary_text)
    endforeach()

    include(FeatureSummary)

    feature_summary(WHAT PACKAGES_FOUND
                DESCRIPTION ""
                VAR packagesFoundSummaryText)

    feature_summary(WHAT PACKAGES_NOT_FOUND
                DESCRIPTION ""
                VAR packagesNotFoundSummaryText)

    #feature_summary(WHAT ENABLED_FEATURES
    #            DESCRIPTION ""
    #            VAR enabledFeaturesSummaryText)

    #feature_summary(WHAT DISABLED_FEATURES
    #            DESCRIPTION "## Features Disabled:"
    #            VAR disabledFeaturesSummaryText)

    #if  (NOT enabledFeaturesSummaryText STREQUAL "")
    #  message(STATUS "${enabledFeaturesSummaryText}")
    #endif()

    #if  (NOT disabledFeaturesSummaryText STREQUAL "")
    #  message(STATUS "${disabledFeaturesSummaryText}")
    #endif()
    
    if (NOT packagesFoundSummaryText STREQUAL "")
      string(APPEND _summary_text "\n## Package Found ##\n")
      string(APPEND _summary_text "-----------------------------------------------------------\n")
      string(APPEND _summary_text "${packagesFoundSummaryText}\n")
    endif()

    string(STRIP ${packagesNotFoundSummaryText} packagesNotFoundSummaryText)
    if (DEFINED packagesNotFoundSummaryText AND (NOT packagesNotFoundSummaryText STREQUAL "")) 
      string(APPEND _summary_text "\n## Packages not Found ##\n")
      string(APPEND _summary_text "-----------------------------------------------------------\n")
      string(APPEND _summary_text "${packagesNotFoundSummaryText}\n")
    endif()
    message(STATUS "===========================================================\n${_summary_text}===========================================================")

endfunction()

#
# This function will prevent in-source builds
#
function(sc_assure_out_of_source_builds)
  # make sure the user doesn't play dirty with symlinks
  get_filename_component(srcdir "${CMAKE_SOURCE_DIR}" REALPATH)
  get_filename_component(bindir "${CMAKE_BINARY_DIR}" REALPATH)

  # disallow in-source builds
  if("${srcdir}" STREQUAL "${bindir}")
    message("######################################################")
    message("Warning: in-source builds are not allowed")
    message("Please create a separate build directory and run cmake from there")
    message("######################################################")
    message(FATAL_ERROR "Quitting configuration")
  endif()
endfunction()

function(sc_list_sha256 IN_LIST OUT_SHA256) 
  string(JOIN ", " _my_concat ${IN_LIST})
  string(SHA256 _my_sha256 "${_my_concat}")
  set(${OUT_SHA256} ${_my_sha256} PARENT_SCOPE)
endfunction()



#[[
@brief Sets a global cached CMake variable with type and metadata.

@details
This function sets a global variable in the CMake cache, supporting multiple types (BOOL, STRING, PATH, FILEPATH, INTERNAL).
It enforces naming conventions for internal and public variables, and allows attaching descriptions, summary grouping, advanced marking, and valid string values.
Intended for project-wide configuration and option management.

@param arg_variable The name of the variable to set.
@param arg_value The value to assign to the variable.
@param arg_description A description for the variable, shown in CMake GUIs.
@arg BOOL Set variable type to BOOL.
@arg STRING Set variable type to STRING.
@arg PATH Set variable type to PATH.
@arg FILEPATH Set variable type to FILEPATH.
@arg INTERNAL Set variable type to INTERNAL (must start with Z_SC_).
@arg ADVANCED Mark variable as advanced in CMake GUIs.
@arg GROUP Specify group name.
@arg STRINGS List of valid string values for the variable.

@note
Internal variables must start with "Z_SC_". Public variables must start with "SC_".
]]
function(sc_global_set arg_variable arg_value arg_description)
  set(_optionsArgs 
    BOOL 
    STRING 
    PATH 
    FILEPATH 
    INTERNAL 
    ADVANCED
  )

  #cmake_parse_arguments(PARSE_ARGV 3 _ARG "${_optionsArgs}" "GROUP" "STRINGS")
  cmake_parse_arguments(_ARG "${_optionsArgs}" "GROUP" "STRINGS" "${ARGN}")
  if (_ARG_INTERNAL) 
    if (NOT arg_variable MATCHES "^Z_SC_")
      message(FATAL_ERROR "Internal cached variable \"${arg_variable}\" must start with \"Z_SC_\"")
    endif()
  else()
    if (NOT arg_variable MATCHES "^SC_")
      message(FATAL_ERROR "Public cached variable \"${arg_variable}\" must start with \"Z_SC_\"")
    endif()
  endif()

  if (_ARG_INTERNAL) 
    set(_variable_type "INTERNAL")
  elseif(_ARG_BOOL)
    set(_variable_type "BOOL")
  elseif(_ARG_STRING)
    set(_variable_type "STRING")
  elseif(_ARG_PATH)
    set(_variable_type "PATH")
  elseif(_ARG_FILEPATH)
    set(_variable_type "FILEPATH")
  else()
    message(FATAL_ERROR "sc_global_set miss type for variable")  
  endif()

  set(${arg_variable} ${arg_value} CACHE ${_variable_type} "${arg_description}")

  if (DEFINED _ARG_GROUP)
    if (NOT _ARG_GROUP STREQUAL "")
      set(Z_SC_GROUP_${arg_variable} "${_ARG_GROUP}" CACHE INTERNAL "${arg_variable} in ${_ARG_GROUP}")
    endif()  
  endif()

  if (_ARG_ADVANCED)
    mark_as_advanced(${arg_variable})
  endif()

  if (DEFINED _ARG_STRINGS) 
    set_property(CACHE ${arg_variable} PROPERTY STRINGS "${_ARG_STRINGS}")
  endif()

endfunction()

# Append items to an internal cached list variable
function(sc_internal_list_append arg_var)
  set(_list_var ${${arg_var}})
  foreach(item ${ARGN})
    list(APPEND _list_var ${item})
  endforeach()
  set(${arg_var} ${_list_var} CACHE INTERNAL "Internal list ${arg_var}" FORCE)
endfunction()