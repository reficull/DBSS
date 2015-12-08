cmake_minimum_required(VERSION 2.6)

project(ssdbtest CXX)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()


set(CXX_FLAGS
    -DNDEBUG -D__STDC_FORMAT_MACROS -Wall -O2 -Wno-sign-compare -fPIC
 )
set(C_FLAGS
    -DNDEBUG -D__STDC_FORMAT_MACROS -Wall -O2 -Wno-sign-compare -fPIC 
 )
if(CMAKE_BUILD_BITS EQUAL 32)
  list(APPEND CXX_FLAGS "-m32")
endif()
string(REPLACE ";" " " CMAKE_CXX_FLAGS "${CXX_FLAGS}")

SET(CMAKE_BUILD_TYPE Release ON)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

include_directories(${PROJECT_SOURCE_DIR})

string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
message(STATUS "CXX_FLAGS = " ${CMAKE_CXX_FLAGS} " " ${CMAKE_CXX_FLAGS_${BUILD_TYPE}})
######################################
add_subdirectory(src)


