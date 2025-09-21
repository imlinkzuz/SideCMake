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
function(print_aligned LABEL VALUE)
    set(MAX_LENGTH 24)
    string(LENGTH "${LABEL}" CURRENT_LABEL_LENGTH)
    math(EXPR PADDING_LENGTH "${MAX_LENGTH} - ${CURRENT_LABEL_LENGTH}")
    if (PADDING_LENGTH LESS 0)
        set(PADDING_LENGTH 4)
    endif()    
    string(REPEAT " " ${PADDING_LENGTH} PADDING)
    message(STATUS "${LABEL}${PADDING} ${VALUE}")
endfunction()

#[[
@brief Dumps all CMake variables, optionally filtered by a regex pattern.
@param ARGV0 Optional regex pattern to filter variable names.
]]
function(dump_cmake_variables)
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
        print_aligned(${_variableName} ${${_variableName}})
    endforeach()
endfunction()

#[[
@brief Prints a summary of the project configuration.
@notes This function is typically called at the end of the configuration process to give users a clear overview of the build environment and settings.
]]
function(print_summary)
    message("   ")
    message("   ")
    message(STATUS "# Project Summary: ------------------------------------------")
    message(STATUS "## General:")
    print_aligned("Project:" "${PROJECT_NAME} v${PROJECT_VERSION}")
    print_aligned("Targets:"  "${SC_ALL_TARGETS}")
    print_aligned("Build Type:" "${CMAKE_BUILD_TYPE}")
    if (${ENABLE_SHARED_LIBS})
    set(_LINK_TYPE "SHARED")
    else()
    set(_LINK_TYPE "STATIC")
    endif()  
    print_aligned("Link Type:" "${_LINK_TYPE}")

    print_aligned("Install:" "${CMAKE_INSTALL_PREFIX}")

    print_aligned("Target System:" "${CMAKE_SYSTEM_NAME}")
    print_aligned("    Arch:" "${CMAKE_SYSTEM_PROCESSOR}")
    print_aligned("    Bit Order:" "${CMAKE_C_BYTE_ORDER}")


    print_aligned("CXX Compiler:" "${CMAKE_CXX_COMPILER_ID} v${CMAKE_CXX_COMPILER_VERSION}")
    print_aligned("    Standard:" "${CMAKE_CXX_STANDARD} (required: ${CMAKE_CXX_STANDARD_REQUIRED})")
    print_aligned("    Extensions:" "${CMAKE_CXX_EXTENSIONS}")
    print_aligned("    Visibility:" "${CMAKE_CXX_VISIBILITY_PRESET}")
    print_aligned("    Flags:" "${CMAKE_CXX_FLAGS}")

    print_aligned("C Compiler:" "${CMAKE_C_COMPILER_ID} v${CMAKE_C_COMPILER_VERSION}")
    print_aligned("    Flags :" "${CMAKE_C_FLAGS}")

    print_aligned("Exe Linker Flags:" "${CMAKE_EXE_LINKER_FLAGS}")
    print_aligned("Module Linker Flags:" "${CMAKE_MODULE_LINKER_FLAGS}")
    print_aligned("Shared Lib Linker Flags:" "${CMAKE_SHARED_LINKER_FLAGS}")
    print_aligned("Static Lib Linker Flags:" "${CMAKE_STATIC_LINKER_FLAGS}")
    print_aligned("CMAKE_CROSSCOMPILING:" "${CMAKE_CROSSCOMPILING}")

    if (${CMAKE_CROSSCOMPILING})
    print_aligned("  CMAKE_CROSSCOMPILING_EMULATOR: ${CMAKE_CROSSCOMPILING_EMULATOR}")
    endif()

    include(FeatureSummary)
    add_feature_info("Developer Mode (SC_ENABLE_DEVELOPER_MODE)" SC_ENABLE_DEVELOPER_MODE "\t${SC_ENABLE_DEVELOPER_MODE}")
    add_feature_info("Build Testing (BUILD_TESTING)" BUILD_TESTING "\t${BUILD_TESTING}")
    add_feature_info("Build Shared Libs (BUILD_SHARED_LIBS)" BUILD_SHARED_LIBS "\t${BUILD_SHARED_LIBS}")

    add_feature_info("IPO (Interprocedural Optimization)" SC_ENABLE_IPO "\t${SC_ENABLE_IPO}")
    add_feature_info("Warnings as Errors" SC_WARNINGS_AS_ERRORS "\t${SC_WARNINGS_AS_ERRORS}")
    add_feature_info("Enable user linker " SC_ENABLE_USER_LINKER "\t${SC_ENABLE_USER_LINKER}")

    add_feature_info("Address Sanitizer" SC_ENABLE_SANITIZER_ADDRESS "\t${SC_ENABLE_SANITIZER_ADDRESS}")
    add_feature_info("Leak Sanitizer" SC_ENABLE_SANITIZER_LEAK "\t${SC_ENABLE_SANITIZER_LEAK}")
    add_feature_info("Thread Sanitizer" SC_ENABLE_SANITIZER_THREAD "\t${SC_ENABLE_SANITIZER_THREAD}")
    add_feature_info("Memory Sanitizer" SC_ENABLE_SANITIZER_MEMORY "\t${SC_ENABLE_SANITIZER_MEMORY}")
    add_feature_info("Undefined Behavior Sanitizer" SC_ENABLE_SANITIZER_UNDEFINED "\t${SC_ENABLE_SANITIZER_UNDEFINED}")
    add_feature_info("Unity Build" SC_ENABLE_UNITY_BUILD "\t${SC_ENABLE_UNITY_BUILD}")
    add_feature_info("Clang Tidy" SC_ENABLE_CLANG_TIDY "\t${SC_ENABLE_CLANG_TIDY}")
    add_feature_info("Cpp Check" SC_ENABLE_CPPCHECK "\t${SC_ENABLE_CPPCHECK}")
    add_feature_info("Precompiled Headers" SC_ENABLE_PCH "\t${SC_ENABLE_PCH}")
    add_feature_info("Cache (ccache)" SC_ENABLE_CACHE "\t${SC_ENABLE_CACHE}")

    feature_summary(WHAT PACKAGES_FOUND
                DESCRIPTION ""
                VAR packagesFoundSummaryText)

    feature_summary(WHAT PACKAGES_NOT_FOUND
                DESCRIPTION ""
                VAR packagesNotFoundSummaryText)

    feature_summary(WHAT ENABLED_FEATURES
                DESCRIPTION ""
                VAR enabledFeaturesSummaryText)

    feature_summary(WHAT DISABLED_FEATURES
                DESCRIPTION "## Features Disabled:"
                VAR disabledFeaturesSummaryText)

    message("    ")
    if  (NOT enabledFeaturesSummaryText STREQUAL "")
      message(STATUS "## Features Enabled:")
      message(STATUS "${enabledFeaturesSummaryText}")
    endif()

    if  (NOT disabledFeaturesSummaryText STREQUAL "")
      message(STATUS "## Features Disabled:")
      message(STATUS "${disabledFeaturesSummaryText}")
    endif()
    
    if (NOT packagesFoundSummaryText STREQUAL "")
      message(STATUS "## Package Found:")
      message(STATUS "${packagesFoundSummaryText}")
    endif()

    string(STRIP ${packagesNotFoundSummaryText} packagesNotFoundSummaryText)
    if (DEFINED packagesNotFoundSummaryText AND (NOT packagesNotFoundSummaryText STREQUAL "")) 
      message(STATUS "## Packages not Found:${packagesNotFoundSummaryText}:")
      message(STATUS "${packagesNotFoundSummaryText}")
    endif()
    message(STATUS "-----------------------------------------------------------")

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