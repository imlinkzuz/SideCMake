cmake_minimum_required(VERSION 3.28)

function(sc_add_unit_test) 
  cmake_parse_arguments(
    _ARG
    "VERSION_MATCHES"
    "TEST_NAME;TEST_FRAMEWORK"
    "TARGETS;TEST_SOURCES;TEST_DEPENDENCIES"
    ${ARGN}
  )

  if (NOT DEFINED _ARG_TEST_FRAMEWORK)
    set(_ARG_TEST_FRAMEWORK "DOCTEST")
  else()
    string(TOUPPER "${_ARG_TEST_FRAMEWORK}" _ARG_TEST_FRAMEWORK)
  endif()
 
  if (_ARG_TEST_FRAMEWORK STREQUAL "DOCTEST")
    find_package(doctest REQUIRED)
  endif()

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
    project("CmakeConfigPackageTests" LANGUAGES CXX)
  endif()

  if(PROJECT_IS_TOP_LEVEL OR TEST_INSTALLED_VERSION)
      if(NOT TARGET SC_BUILD_OPTIONS)
        message(FATAL_ERROR "Required config package not found!")
        return() # be strictly paranoid for Template Janitor github action! CK
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
  
  set(_CONFIGURED_INCLUDE_INSTALL_DIR "${CMAKE_BINARY_DIR}/configured_files/include")
  target_include_directories(
    ${_ARG_TEST_NAME}
    PRIVATE
      $<BUILD_INTERFACE:${_CONFIGURED_INCLUDE_INSTALL_DIR}>
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>
  )

  target_link_libraries(
    ${_ARG_TEST_NAME}
    PRIVATE SC_BUILD_WARNINGS
            SC_BUILD_OPTIONS
            ${_library_targets}
      )
  
  if(WIN32 AND BUILD_SHARED_LIBS)
    add_custom_command(
      TARGET ${_ARG_TEST_NAME}
      PRE_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:tests> $<TARGET_FILE_DIR:tests>
      COMMAND_EXPAND_LISTS)
  endif()      

  if (_ARG_TEST_FRAMEWORK STREQUAL "DOCTEST")
    target_link_libraries(${_ARG_TEST_NAME} PRIVATE doctest::doctest)
    include(${doctest_DIR}/doctest.cmake)

    # automatically discover tests that are defined in catch based test files you can modify the unittests. Set TEST_PREFIX
    # to whatever you want, or use different for different binaries
    doctest_discover_tests(
      ${_ARG_TEST_NAME}
      TEST_PREFIX
      "unittests."
      #REPORTER
      #XML
      JUNIT_OUTPUT_DIR
      .
      #OUTPUT_PREFIX
      #"unittests."
      #TEST_SUFFIX
      #.xml
    )  
  else()  
    message(STATUS "########### CMAKE_CURRENT_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}")
    add_test(NAME unittests.${_ARG_TEST_NAME} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} COMMAND ${_ARG_TEST_NAME})
  endif()

endfunction()

function(sc_add_compile_only_test) 
  cmake_parse_arguments(
    _ARG
    "WILL_FAIL;WILL_PASS"
    "TEST_NAME"
    "TARGETS;TEST_SOURCES;TEST_DEPENDENCIES"
    ${ARGN}
  )

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
    project("CmakeConfigPackageTests" LANGUAGES CXX)
  endif()

  if(PROJECT_IS_TOP_LEVEL OR TEST_INSTALLED_VERSION)
      if(NOT TARGET SC_BUILD_OPTIONS)
        message(FATAL_ERROR "Required config package not found!")
        return() # be strictly paranoid for Template Janitor github action! CK
      endif()
  endif()
  
  if (_ARG_WILL_FAIL)
    add_library(${_ARG_TEST_NAME} EXCLUDE_FROM_ALL)
  else()
    add_library(${_ARG_TEST_NAME}) 
  endif()

  target_sources(${_ARG_TEST_NAME} PRIVATE ${_ARG_TEST_SOURCES})
  target_include_directories(
    ${_ARG_TEST_NAME}
    PRIVATE
      $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/configured_files/include>
      $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>
  )

  target_link_libraries(
    ${_ARG_TEST_NAME}
    PRIVATE SC_BUILD_WARNINGS
            SC_BUILD_OPTIONS
            ${_library_targets}
      )
  
  if(WIN32 AND BUILD_SHARED_LIBS)
    add_custom_command(
      TARGET ${_ARG_TEST_NAME}
      PRE_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:tests> $<TARGET_FILE_DIR:tests>
      COMMAND_EXPAND_LISTS)
  endif()      

  if (_ARG_WILL_FAIL)
    set(_expected_result "failure")
  else()
    set(_expected_result "pass")
  endif()

  add_test(NAME ${_ARG_TEST_NAME}
             COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target ${_ARG_TEST_NAME} --config $<CONFIGURATION> 
             WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  if (_ARG_WILL_FAIL)
    set_tests_properties(${_ARG_TEST_NAME} PROPERTIES
      WILL_FAIL TRUE
    )
  else()  
    set_tests_properties(${_ARG_TEST_NAME} PROPERTIES
      WILL_FAIL FALSE
    )
  endif()    

endfunction()
