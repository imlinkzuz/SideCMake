# Get dynamic SDL3 lib into Frameworks folder in app bundle.
function(sc_darwin_install)

set(_oneValueArgs
  PROJECT_NAME # The project name, this is the name of the project to be created
  TARGET_NAME # The target name, this is the name of the project to be created
  MANIFESTS # The manifests to be added to the target
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

# We have to set the default icon for macOS, if not specified.
if (NOT _ARG_ICON) 
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.icns)
    set(_ARG_ICON ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.icns)
  else()
    set(_ARG_ICON ${SIDECMAKE_DIR}/resources/icons/app.icns)
  endif()  
  if (NOT EXISTS ${_ARG_ICON})
    unset(_ARG_ICON)
  endif()
endif()  

if (_ARG_ICON)
  get_filename_component(SC_MACOSX_BUNDLE_ICON_NAME_WLE ${_ARG_ICON} NAME_WLE)
  get_filename_component(MACOSX_BUNDLE_ICON_FILE ${_ARG_ICON} NAME)
  # Define the path to your icon file
#  set(MACOSX_BUNDLE_ICON_FILE ${_APP_ICON_NAME}) 
  # Set source file properties to ensure the icon is copied to the Resources folder
  target_sources(${_ARG_TARGET_NAME} PRIVATE ${_ARG_ICON})
  set_source_files_properties(${_ARG_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
endif()

foreach(my_target ${_ARG_SHARED_TARGETS})
   target_sources(${_ARG_TARGET_NAME} PRIVATE $<TARGET_FILE:${my_target}>)
   set_source_files_properties($<TARGET_FILE:${my_target}>
       PROPERTIES
       MACOSX_PACKAGE_LOCATION "Frameworks" 
   )
endforeach()

foreach(my_rc ${_ARG_RESOURCES})

  if (NOT IS_ABSOLUTE ${my_rc})
    set(my_formalize_rc "${CMAKE_CURRENT_SOURCE_DIR}/${my_rc}")
  else()
    set(my_formalize_rc "${my_rc}")  
  endif()

  string(REGEX REPLACE ".*resources/" "" my_rel_dest ${my_rc})

  if (IS_DIRECTORY ${my_formalize_rc})
    # For build
    add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${my_formalize_rc}
        ${CMAKE_CURRENT_BINARY_DIR}/Resources/${my_rel_dest})
    # For distribution:
    add_custom_command(TARGET ${_ARG_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${my_formalize_rc}
        $<TARGET_BUNDLE_CONTENT_DIR:${_ARG_TARGET_NAME}>/Resources/${my_rel_dest})
  else()
    cmake_path(GET my_rel_dest PARENT_PATH my_rel_dest)
    target_sources(${_ARG_TARGET_NAME} PRIVATE ${my_formalize_rc})
    set_source_files_properties(${my_formalize_rc}
      PROPERTIES
      MACOSX_PACKAGE_LOCATION "Resources/${my_rel_dest}"
    )    
  endif()


endforeach()

# RESOURCE in set_target_properties can not copy font into the subdirectory under directory 'Resources'
# Note that RESOURCE also overrides MACOSX_PACKAGE_LOCATION
target_sources(${_ARG_TARGET_NAME} PRIVATE ${_ARG_FONTS})
set_source_files_properties(${_ARG_FONTS}
    PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources/fonts"
)

if (NOT _ARG_MANIFESTS)
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/manifests/Info.plist.in)
    set(_INFO_LIST_IN ${CMAKE_CURRENT_SOURCE_DIR}/manifests/Info.plist.in)
    else()
    set(_INFO_LIST_IN ${SIDECMAKE_DIR}/manifests/Info.plist.in)
    endif()
    set(_ARG_MANIFESTS "${CMAKE_BINARY_DIR}/manifests/Info.plist")
    configure_file("${_INFO_LIST_IN}" "${_ARG_MANIFESTS}" @ONLY)
endif()



# macOS package settings
string(TIMESTAMP CURR_YEAR "%Y")
set_target_properties(${_ARG_TARGET_NAME} 
  PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/manifests/Info.plist"
    EXECUTABLE_NAME "${_ARG_TARGET_NAME}"
    MACOSX_BUNDLE_BUNDLE_NAME "${_ARG_TARGET_NAME}"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${SC_PROJECT_NAMESPACE}.${_ARG_PROJECT_NAME}"
    MACOSX_BUNDLE_COPYRIGHT "(c) ${SC_PROJECT_COPYRIGHT}"
    MACOSX_BUNDLE_ICON_FILE "${MACOSX_BUNDLE_ICON_FILE}"
    INSTALL_RPATH @executable_path/../Frameworks
  )


endfunction()