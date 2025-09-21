include(${SIDECMAKE_DIR}/SystemLink.cmake)
include(${SIDECMAKE_DIR}/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(myproject_supports_sanitizers)
# Get system name in uppercase
  message(status "Determining system name... ${CMAKE_SYSTEM_NAME}")
  string(TOUPPER ${CMAKE_SYSTEM_NAME} _system_name_upper) 
  set(SC_RUNTIME_OS_NAME ${_system_name_upper} CACHE INTERNAL "The CMAKE_SYSTEM_NAME in uppercase.")
  unset(_system_name_upper)

  # Determine architecture (32/64 bit)
  set(SC_RUNTIME_OS_64 OFF CACHE INTERNAL "Determine architecture (32/64 bit)")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(SC_RUNTIME_OS_64 ON)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(myproject_setup_options)
  option(SC_ENABLE_HARDENING "Enable hardening" ON)
  option(SC_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    SC_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    SC_ENABLE_HARDENING
    OFF)

  myproject_supports_sanitizers()

  if (NOT DEFINED SC_ENABLE_DEVELOPER_MODE) 
    set(SC_ENABLE_DEVELOPER_MODE PROJECT_IS_TOP_LEVEL AND NOT CMAKE_PACKAGING_MAINTAINER_MODE CACHE BOOL "Enable developer mode")
  endif()

  option(SC_ENABLE_IPO "Enable IPO/LTO" ${SC_ENABLE_DEVELOPER_MODE})
  option(SC_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ${SC_ENABLE_DEVELOPER_MODE})
  option(SC_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
  option(SC_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
  option(SC_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
  option(SC_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
  option(SC_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
  option(SC_ENABLE_CLANG_TIDY "Enable clang-tidy" ${SC_ENABLE_DEVELOPER_MODE})
  option(SC_ENABLE_CPPCHECK "Enable cpp-check analysis" ${SC_ENABLE_DEVELOPER_MODE})
  option(SC_ENABLE_PCH "Enable precompiled headers" OFF)
  option(SC_ENABLE_CACHE "Enable ccache" ON)


  if(SC_ENABLE_DEVELOPER_MODE)
    option(SC_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN} )
    option(SC_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN} )
  else()
    option(SC_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF )
    option(SC_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF )
  endif()


  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      SC_ENABLE_IPO
      SC_WARNINGS_AS_ERRORS
      SC_ENABLE_USER_LINKER
      SC_ENABLE_SANITIZER_ADDRESS
      SC_ENABLE_SANITIZER_LEAK
      SC_ENABLE_SANITIZER_UNDEFINED
      SC_ENABLE_SANITIZER_THREAD
      SC_ENABLE_SANITIZER_MEMORY
      SC_ENABLE_UNITY_BUILD
      SC_ENABLE_CLANG_TIDY
      SC_ENABLE_CPPCHECK
      SC_ENABLE_COVERAGE
      SC_ENABLE_PCH
      SC_ENABLE_CACHE)
  endif()

  myproject_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (SC_ENABLE_SANITIZER_ADDRESS OR SC_ENABLE_SANITIZER_THREAD OR SC_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(SC_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(myproject_global_options)
  if(SC_ENABLE_IPO)
    include(${SIDECMAKE_DIR}/InterproceduralOptimization.cmake)
    myproject_enable_ipo()
  endif()

  myproject_supports_sanitizers()

  if(SC_ENABLE_HARDENING AND SC_ENABLE_GLOBAL_HARDENING)
    include(${SIDECMAKE_DIR}/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SC_ENABLE_SANITIZER_UNDEFINED
       OR SC_ENABLE_SANITIZER_ADDRESS
       OR SC_ENABLE_SANITIZER_THREAD
       OR SC_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME ${SC_ENABLE_DEVELOPER_MODE})
    endif()
    #message("${SC_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${SC_ENABLE_SANITIZER_UNDEFINED}")
    myproject_enable_hardening(SC_BUILD_OPTIONS ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(myproject_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(${SIDECMAKE_DIR}/StandardProjectSettings.cmake)
  endif()

  add_library(SC_BUILD_WARNINGS INTERFACE)
  add_library(SC_BUILD_OPTIONS INTERFACE)

  include(${SIDECMAKE_DIR}/CompilerWarnings.cmake)
  myproject_set_project_warnings(
    SC_BUILD_WARNINGS
    ${SC_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(SC_ENABLE_USER_LINKER)
    include(${SIDECMAKE_DIR}/Linker.cmake)
    myproject_configure_linker(SC_BUILD_OPTIONS)
  endif()

  include(${SIDECMAKE_DIR}/Sanitizers.cmake)
  myproject_enable_sanitizers(
    SC_BUILD_OPTIONS
    ${SC_ENABLE_SANITIZER_ADDRESS}
    ${SC_ENABLE_SANITIZER_LEAK}
    ${SC_ENABLE_SANITIZER_UNDEFINED}
    ${SC_ENABLE_SANITIZER_THREAD}
    ${SC_ENABLE_SANITIZER_MEMORY})

  set_target_properties(SC_BUILD_OPTIONS PROPERTIES UNITY_BUILD ${SC_ENABLE_UNITY_BUILD})

  if(SC_ENABLE_PCH)
    target_precompile_headers(
      SC_BUILD_OPTIONS
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(SC_ENABLE_CACHE)
    include(${SIDECMAKE_DIR}/Cache.cmake)
    myproject_enable_cache()
  endif()

  include(${SIDECMAKE_DIR}/StaticAnalyzers.cmake)
  if(SC_ENABLE_CLANG_TIDY)
    myproject_enable_clang_tidy(SC_BUILD_OPTIONS ${SC_WARNINGS_AS_ERRORS})
  endif()

  if(SC_ENABLE_CPPCHECK)
    myproject_enable_cppcheck(${SC_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(SC_ENABLE_COVERAGE)
    include(${SIDECMAKE_DIR}/Tests.cmake)
    myproject_enable_coverage(SC_BUILD_OPTIONS)
  endif()

  if(SC_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(SC_BUILD_OPTIONS INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(SC_ENABLE_HARDENING AND NOT SC_ENABLE_GLOBAL_HARDENING)
    include(${SIDECMAKE_DIR}/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SC_ENABLE_SANITIZER_UNDEFINED
       OR SC_ENABLE_SANITIZER_ADDRESS
       OR SC_ENABLE_SANITIZER_THREAD
       OR SC_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME ${SC_ENABLE_DEVELOPER_MODE})
    endif()
    myproject_enable_hardening(SC_BUILD_OPTIONS OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

  # Add utf-8 and unicode support for MSVC
  if (MSVC)
    add_compile_options("/utf-8")
    add_definitions(/DUNICODE /D_UNICODE)
  endif()

  string(TOUPPER ${CMAKE_SYSTEM_NAME} SC_TARGET_OS_NAME)
  add_compile_definitions(SC_TARGET_OS_${SC_TARGET_OS_NAME})

  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(SC_TARGET_ARCH_64 ON)
    add_compile_definitions(SC_TARGET_ARCH_64)
  endif()

  if (CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN") 
    set(SC_TARGET_ARCH_BIG_ENDIAN ON)
    set(SC_TARGET_ARCH_LITTLE_ENDIAN OFF)
    add_compile_definitions(SC_TARGET_ARCH_BIG_ENDIAN)
  else()
    set(SC_TARGET_ARCH_BIG_ENDIAN OFF)
    set(SC_TARGET_ARCH_LITTLE_ENDIAN ON)
    add_compile_definitions(SC_TARGET_ARCH_LITTLE_ENDIAN)
  endif()

  target_compile_features(SC_BUILD_OPTIONS INTERFACE cxx_std_${CMAKE_CXX_STANDARD})


endmacro()
