include(${SIDECMAKE_DIR}/SystemLink.cmake)
include(${SIDECMAKE_DIR}/LibFuzzer.cmake)
include(${SIDECMAKE_DIR}/SCUtilities.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(myproject_supports_sanitizers)

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

  # Add utf-8 and unicode support for MSVC
  if (MSVC)
    add_compile_options("/utf-8")
    add_definitions(/DUNICODE /D_UNICODE)
  endif()

  # Get system name in uppercase
  string(TOUPPER ${CMAKE_SYSTEM_NAME} _system_name_upper) 
  sc_global_set(Z_SC_RUNTIME_OS_NAME ${_system_name_upper} "The CMAKE_SYSTEM_NAME in uppercase." INTERNAL)
  add_compile_definitions(SC_RUNTIME_OS_${Z_SC_RUNTIME_OS_NAME})
  unset(_system_name_upper)

  # Determine architecture (32/64 bit)
  set(_runtime_os_64 OFF)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_runtime_os_64 ON)
    add_compile_definitions(Z_SC_RUNTIME_OS_64)
  endif()
  sc_global_set(Z_SC_RUNTIME_OS_64 ${_runtime_os_64} "Determine architecture (32/64 bit)" INTERNAL)
  unset(_runtime_os_64)
  
  # Determine endianness
  if (CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN") 
    sc_global_set(Z_SC_RUNTIME_BIG_ENDIAN ON "Determine big endian" INTERNAL)
    sc_global_set(Z_SC_RUNTIME_LITTLE_ENDIAN OFF "Determine little endian" INTERNAL)
    add_compile_definitions(SC_RUNTIME_BIG_ENDIAN)
  else()
    sc_global_set(Z_SC_RUNTIME_BIG_ENDIAN OFF "Determine big endian" INTERNAL)
    sc_global_set(Z_SC_RUNTIME_LITTLE_ENDIAN ON "Determine little endian" INTERNAL)
    add_compile_definitions(SC_RUNTIME_LITTLE_ENDIAN)
  endif()


  sc_global_set(SC_ENABLE_HARDENING ON "Enable hardening" CACHE BOOL ADVANCED GROUP "Build Configuration") 
  sc_global_set(SC_ENABLE_COVERAGE OFF "Enable coverage reporting" CACHE BOOL ADVANCED GROUP "Build Configuration") 
  cmake_dependent_option(
    SC_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    SC_ENABLE_HARDENING
    OFF)

  myproject_supports_sanitizers()

  if (NOT DEFINED SC_ENABLE_DEVELOPER_MODE) 
    sc_global_set(SC_ENABLE_DEVELOPER_MODE PROJECT_IS_TOP_LEVEL AND NOT CMAKE_PACKAGING_MAINTAINER_MODE "Enable developer-focused build options and checks" CACHE BOOL GROUP "Build Configuration")
  endif()

  sc_global_set(SC_ENABLE_IPO ${SC_ENABLE_DEVELOPER_MODE} "Enable IPO/LTO" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_WARNINGS_AS_ERRORS ${SC_ENABLE_DEVELOPER_MODE} "Treat Warnings As Errors" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_USER_LINKER OFF "Enable user-selected linker" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_SANITIZER_LEAK OFF "Enable leak sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_SANITIZER_THREAD OFF "Enable thread sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_SANITIZER_MEMORY OFF "Enable memory sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_UNITY_BUILD OFF "Enable unity builds" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_CLANG_TIDY ${SC_ENABLE_DEVELOPER_MODE} "Enable clang-tidy" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_CPPCHECK ${SC_ENABLE_DEVELOPER_MODE} "Enable cpp-check analysis" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_PCH OFF "Enable precompiled headers" CACHE BOOL ADVANCED GROUP "Build Configuration")
  sc_global_set(SC_ENABLE_CACHE ON "Enable ccache" CACHE BOOL ADVANCED GROUP "Build Configuration")


  if(SC_ENABLE_DEVELOPER_MODE)
    sc_global_set(SC_ENABLE_SANITIZER_ADDRESS ${SUPPORTS_ASAN} "Enable address sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
    sc_global_set(SC_ENABLE_SANITIZER_UNDEFINED ${SUPPORTS_UBSAN} "Enable undefined sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
  else()
    sc_global_set(SC_ENABLE_SANITIZER_ADDRESS OFF "Enable address sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
    sc_global_set(SC_ENABLE_SANITIZER_UNDEFINED OFF "Enable undefined sanitizer" CACHE BOOL ADVANCED GROUP "Build Configuration")
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

  sc_global_set(SC_BUILD_FUZZ_TESTS ${DEFAULT_FUZZER} "Enable fuzz testing executable" CACHE BOOL ADVANCED GROUP "Build Configuration")

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

  #target_compile_features(SC_BUILD_OPTIONS INTERFACE cxx_std_${CMAKE_CXX_STANDARD})  
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




endmacro()
