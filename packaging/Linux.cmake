function(sc_linux_install)

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

set(_EXECUTABLE_NAME "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${_ARG_TARGET_NAME}")

if (NOT _ARG_PROJECT_NAME)
  set(_ARG_PROJECT_NAME ${PROJECT_NAME})
endif()

# Copy .so files on Linux to the target App build folder.
foreach(my_target ${_ARG_SHARED_TARGETS})
  # For development:
  add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    $<TARGET_FILE:${my_target}>
    $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>)
  # For distribution:
  install(FILES $<TARGET_FILE:${my_target}>
    DESTINATION ${CMAKE_INSTALL_BINDIR})
endforeach()

if (NOT _ARG_MANIFESTS)
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/manifests/App.desktop.in)
    set(_ARG_MANIFESTS "${CMAKE_CURRENT_SOURCE_DIR}/manifests/App.desktop.in")
  else()
    set(_ARG_MANIFESTS "${SIDECMAKE_DIR}/manifests/App.desktop.in")
  endif()
endif ()

# Icons 
if (NOT _ARG_ICON) 
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.png)
    set(_ARG_ICON ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.png)
  else()
    set(_ARG_ICON ${SIDECMAKE_DIR}/resources/icons/app.png)
  endif()
else()
  if (NOT EXISTS ${_ARG_ICON})
    message(WARNING "Application icon not found : ${_ARG_ICON}")
  endif()
endif()  

if (NOT EXISTS ${_ARG_ICON})
  unset(_ARG_ICON)
endif()


if (_ARG_ICON)
  # For development:
  configure_file(${_ARG_ICON} $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>/../resources/icons/${_ARG_TARGET_NAME}_icon.png COPYONLY)

  # For build
  install(FILES ${_ARG_ICON}
    DESTINATION ~/.local/share/icons
    RENAME "${_ARG_TARGET_NAME}_icon.png")

endif()

foreach(my_font ${_ARG_FONTS})  
  get_filename_component(my_filename ${my_font} NAME)
  # For build
  configure_file(${my_font} $<TARGET_FILE_DIR:${_ARG_TARGET_NAME}>/../resources/fonts/${my_filename} COPYONLY)
  # For distribution:
  install(FILES ${my_font} DESTINATION ${CMAKE_INSTALL_BINDIR}/resources/fonts/)
endforeach()


# Linux app icon setup
configure_file(
  ${_ARG_MANIFESTS}
  "${CMAKE_CURRENT_BINARY_DIR}/${_ARG_TARGET_NAME}.desktop"
  @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${_ARG_TARGET_NAME}.desktop"
  DESTINATION ~/.local/share/applications)

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

endfunction()