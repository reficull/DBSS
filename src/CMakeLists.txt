add_library(DBSS  SHARED DBSS.cc  SSDB_impl.h SSDB_impl.cpp ./util/bytes.h ./util/bytes.cpp  ./net/link.h ./net/link.cpp)
add_executable(ssdbdemo demo.cpp) 
target_link_libraries(ssdbdemo DBSS)
