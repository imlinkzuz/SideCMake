function(sc_windows_install)

set(_oneValueArgs
  PROJECT_NAME # The project name, this is the name of the project to be created
  TARGET_NAME # The target name, this is the name of the project to be created
  MANIFESTS # The manifests to be added to the target
  RC_FILE # the resource file to be added to the target
  ICON # The icon to be added to the target
)

set(_multiValueArgs
  SHARED_TARGETS
  FONTS
  RESOURCES
  )

cmake_parse_arguments(
  _ARG
  ""
  "${_oneValueArgs}"
  "${_multiValueArgs}"
  "${ARGN}")  

if (NOT _ARG_PROJECT_NAME)
  set(_ARG_PROJECT_NAME ${PROJECT_NAME})
endif()

if (NOT _ARG_MANIFESTS)
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/manifests/app.manifest)
    set(_ARG_MANIFESTS "${CMAKE_CURRENT_SOURCE_DIR}/manifests/app.manifest")
  else()
    set(_ARG_MANIFESTS "${SIDECMAKE_DIR}/manifests/app.manifest")
  endif()
endif ()

# Icons 
if (NOT _ARG_ICON) 
  set(_ARG_ICON ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.ico)
  CMAKE_PATH(NATIVE_PATH _ARG_ICON  NORMALIZE _ARG_ICON)
  string(REPLACE "\\" "\\\\" _ARG_ICON ${_ARG_ICON})
endif()  

# Use main entry for Windows GUI app.
if (MINGW)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-subsystem,windows")
  # Static link MinGW standard libraries
  set(CMAKE_CXX_STANDARD_LIBRARIES
    "-static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive")
endif ()

if (MSVC)
    if (EXISTS ${_ARG_MANIFESTS})
      target_sources(${_ARG_TARGET_NAME} PRIVATE ${_ARG_MANIFESTS})
    endif()
    #target_link_options(${SC_APP_NAME} PRIVATE "/SUBSYSTEM:WINDOWS")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /subsystem:windows /entry:mainCRTStartup")
endif ()

# Copy .dll files on Windows to the target App build folder.
# For development:

# set _RC_PRODUCT_VERSION_STR/_RC_PROJECT_VERSION_STR for rc file
string(REPLACE "." "," _RC_PRODUCT_VERSION_STR ${SC_PRODUCT_NAME})
string(REPLACE "." "," _RC_PROJECT_VERSION_STR ${SC_PRODUCT_VERSION})

if (NOT _ARG_RC_FILE)
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/manifests/app.rc.in)
    set(_RC_FILE_IN "${CMAKE_CURRENT_SOURCE_DIR}/manifests/app.rc.in")
  else()
    set(_RC_FILE_IN "${SIDECMAKE_DIR}/manifests/app.rc.in")
  endif()
  set(_ARG_RC_FILE "${CMAKE_BINARY_DIR}/manifests/app.rc")
  configure_file("${_RC_FILE_IN}" "${_ARG_RC_FILE}" @ONLY)
endif()

target_sources(${_ARG_TARGET_NAME} 
  PRIVATE
    ${_ARG_RC_FILE}
)


foreach(my_target ${_ARG_SHARED_TARGETS})
  # For build
  add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    $<TARGET_FILE:${my_target}>
    $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>)

  # For distribution:
  install(FILES $<TARGET_FILE:${my_target}> DESTINATION ${CMAKE_INSTALL_BINDIR})
endforeach()


# Copy resources into app bundle
foreach(my_rc ${_ARG_RESOURCES})

  if (NOT IS_ABSOLUTE ${my_rc})
    set(my_formalize_rc "${CMAKE_CURRENT_SOURCE_DIR}/${my_rc}")
  else()
    set(my_formalize_rc "${my_rc}")  
  endif()

  string(REGEX REPLACE ".*resources/" "" my_rel_dest ${my_rc})

  if (IS_DIRECTORY ${my_formalize_rc})
    message(STATUS "Copying directory ${my_formalize_rc} to ${CMAKE_CURRENT_BINARY_DIR}/resources/${my_rel_dest}")
    # For build
    add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${my_formalize_rc}
        ${CMAKE_CURRENT_BINARY_DIR}/resources/${my_rel_dest})
    # For distribution:
    install(DIRECTORY ${my_formalize_rc} DESTINATION ${CMAKE_INSTALL_BINDIR}/resources/${my_rel_dest})

    # add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
    #     COMMAND ${CMAKE_COMMAND} -E copy_directory
    #     ${my_formalize_rc}
    #     $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>/resources/${my_rel_dest})
  else()
    cmake_path(GET my_rel_dest PARENT_PATH my_rel_dest)
    message(STATUS "Copying file ${my_formalize_rc} to ${CMAKE_CURRENT_BINARY_DIR}/resources/${my_rel_dest}")
    # For build
    add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${my_formalize_rc}
        ${CMAKE_CURRENT_BINARY_DIR}/resources/${my_rel_dest})
    # For distribution:
    install(FILES ${my_formalize_rc} DESTINATION ${CMAKE_INSTALL_BINDIR}/resources/${my_rel_dest})
    # add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
    #     COMMAND ${CMAKE_COMMAND} -E copy_if_different
    #     ${my_formalize_rc}
    #     $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>/resources/${my_rel_dest})

  endif()

endforeach()  

endforeach()


foreach(my_font ${_ARG_FONTS})  
  get_filename_component(my_filename ${my_font} NAME)
  # For build
  configure_file(${my_font} $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>/../resources/fonts/${my_filename} COPYONLY)
  # For distribution:
  install(FILES ${my_font} DESTINATION ${CMAKE_INSTALL_BINDIR}/resources/fonts/)
endforeach()

endfunction()


