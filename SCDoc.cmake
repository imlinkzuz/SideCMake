function(sc_generate_doc)
    include(${SIDECMAKE_DIR}/SCUtilities.cmake)
    set(oneValueArgs DOC_IN_DIR)
    set(multiValueArgs INPUTS)
    cmake_parse_arguments(_ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    message(STATUS "Generating documentation with Doxygen and Sphinx")
    
    # You can customize Doxygen and Sphinx configuration by placing config files in the doc directory
    if (_ARG_DOC_IN_DIR AND EXISTS ${_ARG_DOC_IN_DIR})
        set(_MY_DOC_IN_DIR ${_ARG_DOC_IN_DIR})
    else()
        if (EXISTS ${CMAKE_SOURCE_DIR}/src/doc)
            set(_MY_DOC_IN_DIR ${CMAKE_SOURCE_DIR}/src/doc)
        else()
            if (EXISTS ${SIDECMAKE_DIR}/doc)
                set(_MY_DOC_IN_DIR ${SIDECMAKE_DIR}/doc)
            else()
                message(FATAL_ERROR "Could not find a doc directory to use for documentation configuration files.")
            endif()
        endif()
    endif()
    # Fallback to the ${SIDECMAKE_DIR}/doc directory when _MY_DOC_IN_DIR does not existj
    set(_DEFAULT_DOC_IN_DIR ${SIDECMAKE_DIR}/doc)
    # The working directory for building the documentation will be in the build tree
    # Using a hash of the input directories to avoid conflicts
    sc_list_sha256("${_ARG_INPUTS}" _inputs_sha256)
    set(_BUILD_DOC_DIR ${CMAKE_CURRENT_BINARY_DIR}/doc/${_inputs_sha256})

    if (NOT DEFINED _ARG_INPUTS)
        list(APPEND _ARG_INPUTS "${CMAKE_SOURCE_DIR}/src" "${CMAKE_SOURCE_DIR}/include")
    endif()
    set(DOXYGEN_INPUTS ${_ARG_INPUTS})
    message(STATUS "Using documentation input directories: ${_ARG_INPUTS}")

    foreach(_input ${_ARG_INPUTS})
        if(NOT EXISTS ${_input})
            message("============== FATAL ERROR ===============")
            message(FATAL_ERROR "Input '${_input}' not found! Generate documentation has failed.")
            return() # be strictly paranoid for Template Janitor github action! CK
        endif()
    endforeach()

    # Doxygen generation
    # ==================
    find_package(Doxygen REQUIRED)
    find_package(Sphinx REQUIRED)
    

    set(DOXYGEN_OUTPUT_DIR ${_BUILD_DOC_DIR})
    set(DOXYGEN_INDEX_XML ${DOXYGEN_OUTPUT_DIR}/xml/index.xml)
    if (EXISTS ${_MY_DOC_IN_DIR}/Doxyfile.in}) 
        set(DOXYGENFILE_IN ${_MY_DOC_IN_DIR}/Doxyfile.in)
    else()
        set(DOXYGENFILE_IN ${_DEFAULT_DOC_IN_DIR}/Doxyfile.in)
    endif()
    set(DOXYGENFILE_OUT ${_BUILD_DOC_DIR}/Doxyfile)

    # Replace variables in the Doxyfile         
    configure_file(${DOXYGENFILE_IN} ${DOXYGENFILE_OUT} @ONLY)
    file(MAKE_DIRECTORY ${DOXYGEN_OUTPUT_DIR}) #Doxygen won't create the output directory itself

    # This will be the main output of our command
    add_custom_command(OUTPUT ${DOXYGEN_INDEX_XML}
                       DEPENDS ${_ARG_INPUTS}
                       COMMAND ${DOXYGEN_EXECUTABLE}
                       WORKING_DIRECTORY ${_BUILD_DOC_DIR}        
                       MAIN_DEPENDENCY ${DOXYGENFILE_OUT} ${DOXYGENFILE_IN}
                       COMMENT "Generating ${_ARG_TARGET_NAME} API documentation with Doxygen"
                       VERBATIM)  

    add_custom_target(Doxygen ALL DEPENDS ${DOXYGEN_INDEX_XML})

    # Sphinx documentation generation
    # ################################

#    if (NOT Sphinx_BUILD_EXECUTABLE)
#        message(FATAL_ERROR "Sphinx executable not found. Please install Sphinx to generate the documentation.")
#    endif()
#    add_custom_command(OUTPUT ${_BUILD_DOC_DIR}/source/conf.py
#                       COMMAND "sphine-quickstart" -sep 
#                       WORKING_DIRECTORY ${_BUILD_DOC_DIR}
#                       COMMENT "Generating Sphinx boilerplate with sphinx-quickstart")
    

    set(_SPHINX_INDEX_RST_IN "${_DEFAULT_DOC_IN_DIR}/index.rst.in")
    if (EXISTS ${_MY_DOC_IN_DIR}/index.rst.in) 
        set(_SPHINX_INDEX_RST_IN "${_MY_DOC_IN_DIR}/index.rst.in")
    endif()
    message(STATUS "Using Sphinx index template: ${_SPHINX_INDEX_RST_IN}")
    set(_SPHINX_INDEX_RST_OUT ${_BUILD_DOC_DIR}/source/index.rst)
    file(MAKE_DIRECTORY ${_BUILD_DOC_DIR}/build) #Sphinx won't create the output directory itself
    file(MAKE_DIRECTORY ${_BUILD_DOC_DIR}/source) #Sphinx won't create the output directory itself
    configure_file(${_SPHINX_INDEX_RST_IN} ${_SPHINX_INDEX_RST_OUT} @ONLY)

    set(_SPHINX_CONF_PY_IN "${_DEFAULT_DOC_IN_DIR}/conf.py.in")
    if (EXISTS ${_MY_DOC_IN_DIR}/conf.py.in)
       set(_SPHINX_CONF_PY_IN "${_MY_DOC_IN_DIR}/conf.py.in")
    endif()
    set(_SPHINX_CONF_PY_OUT ${_BUILD_DOC_DIR}/source/conf.py)
    configure_file(${_SPHINX_CONF_PY_IN} ${_SPHINX_CONF_PY_OUT} @ONLY)
    
    set(SPHINX_SOURCE ${_BUILD_DOC_DIR}/source)
    set(SPHINX_BUILD ${_BUILD_DOC_DIR}/build)
    set(SPHINX_INDEX_FILE ${SPHINX_BUILD}/html/index.html)
    add_custom_command(OUTPUT ${SPHINX_INDEX_FILE}
                       COMMAND ${Sphinx_BUILD_EXECUTABLE} -b html 
                               ${SPHINX_SOURCE} ${SPHINX_BUILD}
                       DEPENDS ${DOXYGEN_INDEX_XML} 
                       WORKING_DIRECTORY ${_BUILD_DOC_DIR}
                       MAIN_DEPENDENCY $${_SPHINX_INDEX_RST_OUT} ${_SPHINX_CONF_PY_OUT}
                       COMMENT "Generating documentation with Sphinx")
    add_custom_target(Sphinx ALL
                      DEPENDS ${SPHINX_INDEX_FILE}
                      COMMENT "Generating  documentation with Sphinx")
                       
# install doc
# =============
include(GNUInstallDirs)
install(DIRECTORY ${SPHINX_BUILD}/html DESTINATION ${CMAKE_INSTALL_DOCDIR})

endfunction()