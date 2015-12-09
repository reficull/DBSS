# DBSS 
 a luajit client for ssdb 
make use of ssdb cpp api
src/DBSS.cc is a C wrapper of cpp api
DB.lua is a ffi wrapper for DBSS.cc

#INSTALL
first make sure you have cmake
then


1. BUILD

* run

./build.sh

 will make build dir in current dir


* copy lib file and DB.lua to your project 

the lib file located in build/release/lib/libDBSS.so, you should copy or to link it to your /usr/local/lib/ or any other proper directory

* copy DB.lua config.lua helper.lua to your project, the later two are not required,you can easily edit DB.lua to get rid of them or use your project file to feed DB.lua

* in DB.lua make sure the libSSDB.so path is correct

default is 

        ssdb = assert(ffi.load(LUA_SCRIPT_ROOT .. 'build/release/lib/libDBSS.so'),"load libDBSS.so failed")    

if copy to /usr/local/lib then

        ssdb = assert(ffi.load("/usr/local/lib/libDBSS.so"),"load libDBSS failed")    

* edit last line of DB.lua, make sure the ip and port is correct        

#TEST

make sure you have luajit

        luajit luatest.lua

#USAGE
edit config.lua set ssdb server ip and port,default is local host and 8888

then in your lua file:

        DB = require("DB").DB

it would connect ssdb,and you r good to go

#EXAMPLE

        DB = require("DB").DB

        DB:set("key","value")

        local ret = DB:get("key")

more usage please
see luatest.lua and DB.lua

#SEE ALSO
ssdb
https://github.com/ideawu/ssdb

luajit
http://luajit.org/


