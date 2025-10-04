cmake_minimum_required(VERSION 3.28)

function(sc_add_unit_test) 
  cmake_parse_arguments(
    _ARG
    "VERSION_MATCHES"
    "TEST_NAME"
    "TARGETS;TEST_SOURCES"
    ${ARGN}
  )

  find_package(doctest REQUIRED)

  foreach(_my_target ${_ARG_TARGETS})
    if(NOT TARGET ${_my_target})
      message(FATAL_ERROR "Target '${_my_target}' not found!")
      return() # be strictly paranoid for Template Janitor github action! CK
    endif()
    get_target_property(_my_target_type ${_my_target} TYPE)
    if (_my_target_type STREQUAL "EXECUTABLE") 
      list(APPEND _executable_targets ${_my_target})
    else()
      list(APPEND _library_targets ${_my_target})
    endif()
  endforeach()  

  
  if (NOT PROJECT_NAME STREQUAL "CmakeConfigPackageTests")
    set(PROJECT_NAME CmakeConfigPackageTests LANGUAGES CXX)

  if(PROJECT_IS_TOP_LEVEL OR TEST_INSTALLED_VERSION)
      enable_testing()
      if(NOT TARGET SC_BUILD_OPTIONS)
        message(FATAL_ERROR "Required config package not found!")
        return() # be strictly paranoid for Template Janitor github action! CK
      endif()
    endif()  
  endif()    

  if (_ARG_VERSION_MATCHES)
    foreach(_my_target ${_executable_targets}) 
      # Provide a simple smoke test to make sure that the CLI works and can display a --help message
      add_test(NAME test_${_ARG_TEST_NAME}_has_help COMMAND ${_my_target} --help)
      # Provide a test to verify that the version being reported from the application
      # matches the version given to CMake. This will be important once you package
      # your program. Real world shows that this is the kind of simple mistake that is easy
      # to make, but also easy to test for.
      set(_test_version_matches_target test_${_ARG_TEST_NAME}_version_matches)
      add_test(NAME ${_test_version_matches_target} COMMAND ${_my_target} --version)
      set_tests_properties(${_test_version_matches_target} PROPERTIES PASS_REGULAR_EXPRESSION "${PROJECT_VERSION}")
    endforeach()
  endif()

  add_executable(${_ARG_TEST_NAME} ${_ARG_TEST_SOURCES})
  target_include_directories(
    ${_ARG_TEST_NAME}
    PRIVATE
      $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/configured_files/include>
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>
  )

  target_link_libraries(
    ${_ARG_TEST_NAME}
    PRIVATE SC_BUILD_WARNINGS
            SC_BUILD_OPTIONS
            doctest::doctest
            ${_library_targets}
      )
   
  if(WIN32 AND BUILD_SHARED_LIBS)
    add_custom_command(
      TARGET ${_ARG_TEST_NAME}
      PRE_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:tests> $<TARGET_FILE_DIR:tests>
      COMMAND_EXPAND_LISTS)
  endif()      

  include(${doctest_DIR}/doctest.cmake)

  # automatically discover tests that are defined in catch based test files you can modify the unittests. Set TEST_PREFIX
  # to whatever you want, or use different for different binaries
  doctest_discover_tests(
    ${_ARG_TEST_NAME}
    TEST_PREFIX
    "unittests."
#    REPORTER
#    XML
    JUNIT_OUTPUT_DIR
    .
#    OUTPUT_PREFIX
#    "unittests."
#    TEST_SUFFIX
#    .xml
)  


endfunction()



