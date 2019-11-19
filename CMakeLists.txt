cmake_minimum_required(VERSION 3.9)

project (i3ds_asn1)

set (PROJECT_AUTHOR "SINTEF Digital")
set (PROJECT_URL "http://i3ds-h2020.eu/")
set (PROJECT_LICENSE "MPLv2")
set (PROJECT_VERSION "1.0")
set (PROJECT_SOVERSION "1")
set (PROJECT_DESCRIPTION "i3ds ASN.1 bucket")

option(BUILD_EMBEDDED "Build for embedded systems" OFF)
option(BUILD_DEBUG "Debug-builds" ON)

if (BUILD_EMBEDDED)
  if(NOT DEFINED CMAKE_FIND_ROOT_PATH)
    MESSAGE(FATAL_ERROR "CMAKE_FIND_ROOT_PATH path must be set when compiling for embedded")
  endif(NOT DEFINED CMAKE_FIND_ROOT_PATH)
  SET(CMAKE_CXX_COMPILER "aarch64-linux-gnu-g++")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=${CMAKE_FIND_ROOT_PATH}")
endif (BUILD_EMBEDDED)

include (CheckCXXCompilerFlag REQUIRED)

# -------------------------------------------
if (NOT CMAKE_CXX_FLAGS)
  if (${BUILD_DEBUG})
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcast-align")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcast-qual")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wfatal-errors")

    # There are comparisions for floats. Now, this in itself is not a
    # good idea, but comparing floats to a set value is safe
    # (bit-comparison), comparing a sum/product of floats to another
    # float is not.
    # So, ignore this error for the time being.
    #
    # SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wfloat-equal")

    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wformat-nonliteral")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Winline")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wmissing-declarations")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-parameter")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wpointer-arith")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wshadow")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wundef")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wwrite-strings")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ansi")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pedantic")
  else ()
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
  endif ()

  SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

  check_cxx_compiler_flag ("-fpic" CXX_SUPPORT_FPIC_1)
  check_cxx_compiler_flag ("-fPIC" CXX_SUPPORT_FPIC_2)

  if (${CXX_SUPPORT_FPIC_1})
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic")
  elseif (${CXX_SUPPORT_FPIC_2})
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
  else ()
    message (WARNING "${CMAKE_CXX_COMPILER} does not support -fpic or -fPIC flags")
  endif ()

endif (NOT CMAKE_CXX_FLAGS)
#
# -------------------------------------------

set (GENPATH ${CMAKE_CURRENT_SOURCE_DIR}/generated)
include_directories(BEFORE ${GENPATH}/include)

file(GLOB SRCS ${GENPATH}/src/*.cpp)
# set (LIBS
#   )

add_library(i3ds_asn1 SHARED ${SRCS})
#target_link_libraries (i3ds_asn1 ${LIBS})

set_target_properties (
  i3ds_asn1 PROPERTIES
  VERSION ${PROJECT_VERSION}
  SOVERSION ${PROJECT_SOVERSION})

target_include_directories(i3ds_asn1 PRIVATE ${GENPATH}/src)

install(TARGETS i3ds_asn1
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install (DIRECTORY ${GENPATH}/include/ DESTINATION include FILES_MATCHING PATTERN "*.hpp")
