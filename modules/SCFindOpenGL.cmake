    function (sc_find_opengl)
    cmake_policy(SET CMP0072 NEW) # ENABLE  CMP0072: FindOpenGL prefers GLVND by default when available.
    cmake_parse_arguments(_ARG "" "" "COMPONENTS;OPTIONS" ${ARGN})

    if(NOT TARGET OpenGL::OpenGL)
    # opengl
      # sc_find_package(PKG_TARGET OpenGL 
      #   PKG_OPTIONS 
      #     REQUIRED
      # )
      find_package(OpenGL ${_ARG_OPTIONS} COMPONENTS ${_ARG_COMPONENTS})

      set(_opengl_include_dirs ${OPENGL_INCLUDE_DIRS})
      list(REMOVE_DUPLICATES _opengl_include_dirs)
      foreach(_opengl_include_dir ${_opengl_include_dirs})
        string(APPEND _opengl_desc "\n\tinclude: ${_opengl_include_dir}")
      endforeach()

      set(_opengl_libraries ${OPENGL_LIBRARIES})
      list(REMOVE_DUPLICATES _opengl_libraries)
      foreach(_opengl_library ${_opengl_libraries})
        string(APPEND _opengl_desc "\n\tlib: ${_opengl_library}")
      endforeach()

      if (TARGET OpenGL::GL) 
        list(APPEND _opengl_targets_found OpenGL::GL)
      endif()
      if (TARGET OpenGL::GLU) 
        list(APPEND _opengl_targets_found OpenGL::GLU)
        string(APPEND _opengl_desc "\n\tOpenGL::GLU\n\t\tinclude : ${OPENGL_GLU_INCLUDE_DIR}\n\t\tlib: ${OPENGL_glu_LIBRARY}")
      endif()
      if (TARGET OpenGL::OpenGL) 
        list(APPEND _opengl_targets_found OpenGL::OpenGL)
        string(APPEND _opengl_desc "\n\tOpenGL::OpenGL\n\t\tlib: ${OPENGL_opengl_LIBRARY}")
      endif()
      if (TARGET OpenGL::GLX) 
        list(APPEND _opengl_targets_found OpenGL::GLX)
        string(APPEND _opengl_desc "\n\tOpenGL::GLXn\t\tlib: ${OPENGL_glx_LIBRARY}")
      endif()
      if (TARGET OpenGL::EGL) 
        list(APPEND _opengl_targets_found OpenGL::EGL)
        set(_opengl_egl_include_dirs ${OPENGL_EGL_INCLUDE_DIRS})
        list(REMOVE_DUPLICATES _opengl_egl_include_dirs)
        string(APPEND _opengl_desc "\n\tOpenGL::EGL\n\t\tinclude : ${_opengl_egl_include_dirs}\n\t\tlib : ${OPENGL_egl_LIBRARY}")
      endif()
      if (TARGET OpenGL::GLES2) 
        list(APPEND _opengl_targets_found OpenGL::GLES2)
        string(APPEND _opengl_desc "\n\tOpenGL::GLES2\t\tlib : ${OPENGL_gles2_LIBRARY}")
      endif()
      if (TARGET OpenGL::GLES3) 
        list(APPEND _opengl_targets_found OpenGL::GLES3)
        string(APPEND _opengl_desc "\n\tOpenGL::GLES3\t\tlib : ${OPENGL_gles3_LIBRARY}")
      endif()

      string(REPLACE ";" " , " _opengl_desc "${_opengl_desc}")

      set_package_properties("OpenGL" 
          PROPERTIES DESCRIPTION 
            "${_opengl_desc}" 
          TYPE 
            REQUIRED
      )      

      #link_libraries(${OPENGL_LIBRARIES})
      sc_add_project_dependency("OpenGL" TARGETS ${_opengl_targets_found} OPTIONS REQUIRED)
    endif()
    endfunction()