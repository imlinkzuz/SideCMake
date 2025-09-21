macro(sc_init_variables)
# Project Information

include(${SIDECMAKE_DIR}/SCUtilities.cmake)

if (NOT DEFINED SC_PRODUCT_NAME)
  set(SC_PRODUCT_NAME ${SC_PROJECT_NAME} CACHE STRING "The name of the product.")
endif()

if (NOT DEFINED SC_PRODUCT_VERSION)
  set(SC_PRODUCT_VERSION ${SC_PROJECT_NAME} CACHE STRING "The current version of the product.")
endif()

set(SC_PROJECT_NAME "Untitle" CACHE STRING "The name of the project.")

set(SC_PROJECT_DESCRIPTION "" CACHE STRING "A brief description of the project.")

set(SC_PROJECT_VERSION "0.0.1.0" CACHE STRING "The current version of the project.")

set(SC_PROJECT_NAMESPACE "com.example" CACHE STRING "The namespace of the project.")

set(SC_PROJECT_LANGUAGES "C;CXX" CACHE STRING "The languages used in the project, according to the definitions in CMake project(), separated with ';', for example: 'C;CXX'")

set(SC_PROJECT_LOCALES "en;zh-CN" CACHE STRING "A list of locale used in the project, separated with ';', for example: 'en;de'")

set(SC_PROJECT_LINK "" CACHE STRING "The project's homepage url.")

set(SC_PROJECT_EMAIL "" CACHE STRING "Optional, email address for the project.")

set(SC_PROJECT_AUTHOR "" CACHE STRING "Optional's name for the project.")

set(SC_PROJECT_COMPANY "" CACHE STRING "Optional, company's name for the project.")

set(SC_PROJECT_COPYRIGHT "" CACHE STRING "The project's copyright declaration.")

#set(SC_GUI_BACKEND "" CACHE STRING "Set the backend for the GUI application in the project.")

set(SC_ENABLE_DEVELOPER_MODE OFF CACHE INTERNAL "Enable developer mode")

set(SC_TARGET_OS_NAME "" CACHE INTERNAL "The CMAKE_SYSTEM_NAME in uppercase.")

set(SC_TARGET_ARCH_64 OFF CACHE INTERNAL "Determine architecture (32/64 bit) for the machine the compiler produces code for.")

set(SC_TARGET_ARCH_BIG_ENDIAN OFF CACHE INTERNAL "If byte order of target architecture is big-endian, set this to ON.")

set(SC_TARGET_ARCH_LITTLE_ENDIAN ON CACHE INTERNAL "If byte order of target architecture is little-endian, set this to ON.")
  
option(SC_ENABLE_DEVELOPER_MODE "Enable develper mode" OFF)

option(SC_ENABLE_DOC "Enable generation of documentation" OFF)

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