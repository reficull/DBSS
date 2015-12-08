# DBSS 
is a luajit client for ssdb 
make use of ssdb cpp api
src/DBSS.cc is a C wrapper of cpp
DB.lua is a ffi wrapper for DBSS.cc

#INSTALL
first make sure you have cmake
then

run
./build.sh

will make build dir in current dir
the lib file located in lib/libDBSS.so

#EXAMPLE
edit config.lua set ssdb server ip and port
include DB.lua

more info please
see luatest.lua

#SEE ALSO
ssdb
https://github.com/ideawu/ssdb
