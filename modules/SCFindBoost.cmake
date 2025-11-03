function(sc_find_boost) 
  cmake_parse_arguments(_ARG "" "" "COMPONENTS;OPTIONS" ${ARGN})
  if(NOT Boost_FOUND)
    #set(Boost_USE_RELEASE_LIBS ON)
    #set(Boost_USE_DEBUG_LIBS ON)
    set(Boost_USE_STATIC_LIBS ON)
    # Force don't 
    set(Boost_NO_SYSTEM_PATHS ON)
    #message("------------------- _ARG_COMPONENTS = ${_ARG_COMPONENTS}")
    #message("------------------- _ARG_OPTIONS = ${_ARG_OPTIONS}")
    find_package(Boost 1.89.0 ${_ARG_OPTIONS} COMPONENTS ${_ARG_COMPONENTS})
    include_directories(${Boost_INCLUDE_DIRS})
    if (Boost_FOUND) 
      include(FeatureSummary)
      set(_boost_libraries ${Boost_LIBRARIES})
      list(REMOVE_DUPLICATES _boost_libraries)
      foreach(_boost_lib ${_boost_libraries})
        get_target_property(_boost_lib_path ${_boost_lib} LOCATION)
        if (_boost_lib_path MATCHES ".*-NOTFOUND$")
          string(APPEND _boost_lib_dirs "\n\tlib : ${_boost_lib}")
        else()
          # Maybe it's a static library
          find_library(_boost_lib_path NAMES ${_boost_lib} PATHS ${Boost_LIBRARY_DIRS} NO_DEFAULT_PATH)
          string(APPEND _boost_lib_dirs "\n\tlib : ${_boost_lib_path}")
        endif()
      endforeach()
      set(_boost_include_dirs ${Boost_INCLUDE_DIRS})
      list(REMOVE_DUPLICATES _boost_include_dirs)
      foreach(_boost_inc_dir ${_boost_include_dirs})
        string(APPEND _boost_inc_dirs "\n\tinclude : ${_boost_inc_dir}")
      endforeach()
      set_package_properties("Boost" 
          PROPERTIES DESCRIPTION 
            "(version == ${Boost_VERSION}) ${_boost_lib_dirs} ${_boost_inc_dirs}" 
          TYPE 
            REQUIRED
      )
      sc_add_project_dependency("Boost" 
        TARGETS 
          ${Boost_LIBRARIES} 
        VERSION
          "${Boost_VERSION}"
        OPTIONS
          ${_boost_options}
      )
      add_compile_definitions(BOOST_LOCALE_ENABLE_CHAR32_T)
    endif()
  endif() 
endfunction()