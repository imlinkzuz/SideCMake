macro(sc_init_variables)

# Project Information

include(${SIDECMAKE_DIR}/SCUtilities.cmake)

sc_global_set(SC_PROJECT_NAME "Untitle" "Project Name" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_DESCRIPTION "" "Project Description" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_VERSION "0.0.1.0" "Project Version" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_NAMESPACE "com.example" "Project Namespace" CACHE STRING GROUP "Project")

# Languages used in the project, according to the definitions in CMake project(), separated with ';', for example: 'C;CXX'
sc_global_set(SC_PROJECT_LANGUAGES "C;CXX" "Program Language" CACHE STRING GROUP "Project")

# List of locale used in the project, separated with ';', for example: 'en;de'
sc_global_set(SC_PROJECT_LOCALES "en;zh-CN" "Locales" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_LINK "" "Link" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_EMAIL "" "Contact Email" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_AUTHOR "" "Author" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_COMPANY "" "Company" CACHE STRING GROUP "Project")

sc_global_set(SC_PROJECT_COPYRIGHT "" "Copyright" CACHE STRING GROUP "Project")

if (NOT DEFINED SC_PRODUCT_NAME)
  sc_global_set(SC_PRODUCT_NAME ${SC_PROJECT_NAME} "Product Name" CACHE STRING GROUP "Project")
endif()

if (NOT DEFINED SC_PRODUCT_VERSION)
  sc_global_set(SC_PRODUCT_VERSION ${SC_PROJECT_VERSION} "Product Version" CACHE STRING GROUP "Project")
endif()

sc_global_set(SC_ENABLE_DOC OFF "Enable Doc" CACHE BOOL GROUP "Documentation")

# Only set the cxx_standard if it is not set by someone else
if (NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
endif()

if (NOT DEFINED CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# strongly encouraged to enable this globally to avoid conflicts between
# -Wpedantic being enabled and -std=c++20 and -std=gnu++20 for example
# when compiling with PCH enabled
if (NOT DEFINED CMAKE_CXX_EXTENSIONS)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

# don't know if this should be set globally from here or not...
if (NOT DEFINED CMAKE_CXX_VISIBILITY_PRESET)
   set(CMAKE_CXX_VISIBILITY_PRESET hidden)
endif()

set(GIT_SHA
  "Unknown"
  CACHE STRING "SHA this build was generated from")
find_package(Git QUIET)
if (GIT_FOUND AND (EXISTS "${CMAKE_SOURCE_DIR}/.git")) 
  execute_process(
     COMMAND git log -1 --format=%h
     WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
     OUTPUT_VARIABLE GIT_SHA
     OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

list(APPEND CMAKE_MODULE_PATH "${SIDECMAKE_DIR}")
    

endmacro()

sc_init_variables()