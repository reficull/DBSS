DB = require("DB").DB
local DBSS = require("DB")
printT = require("Util").PrintTable
local ffi      = require 'ffi'
local NULL = ffi.new'void*'
function ptr(p)
    return p ~= NULL and p or nil
end


----------------------------
start = ""
endd = ""
local limit = 10
local vlen = 128
--[[
DB:set('name','testserver')
local res,err = DB:set('k','wtf')  
print("set:",res,err)

local res,err = DB:get('k')  
print("get:",res,err)

-- long type,will fail bigger than this.
local res,err = DB:set('biggestNum',2147483647)  
print("set:",res,err)

local res,err = DB:get('biggestNum')  
print("get:",res,err)

local res,err = DB:set('biggerThenbiggestNum','2147483648')  
local res,err = DB:get('biggerThenbiggestNum')  
print("get:",res,err)

--DB:setx('timelimitk',9999,10)

DB:set('testNum',100)
local num = DB:incr('testNum',34)
print('testNum:',100,' incr by 34:',num)

local keys = {'testNum'}
print('multi_get:')
printT(rstb)

print('del k:',DB:del('k'))
print('del name:',DB:del('name'))
local p = ffi.typeof("const char**")
--DB:get_pointer()
--local rstb = DB:rscan(start,endd,limit,vlen)
--local rstb = DB:scan(start,endd,limit,vlen)
local settb = {
    key1 = "wtf1",
    key2 = "wtf2",
    key3 = "wtf3",
}
DB:multi_set(settb)
local dlist = {}
for k,v in pairs(settb) do
    print('insert Key:',k)
    table.insert(dlist,k)
end

local rstb = DB:multi_get(dlist)
printT(rstb)
local ret = DB:multi_del(dlist)
print('del ret:',ret)
local rstb = DB:scan(start,endd,limit,vlen)
printT(rstb)
local ret = DB:hset("testhash","hkey2","key2val2")
print("lua hset key2 ret:\n",ret)
local hgetret = DB:hget("testhash","hkey2")
print("lua hget hkey2:\n",hgetret)
local rstb = DB:keys(start,endd,limit,vlen)
print("keys:")
printT(rstb)
--local ret = DB:hdel("testhash","hkey1")
--print("hdel ret:",ret)

local ret = DB:hset("testhash","num1",100)
print('hset num1:',ret)
ret = DB:hincr("testhash","num1",-11)
print("hincr:",ret)
ret = DB:hsize("testhash")
print("hsize:",ret)
--ret = DB:hclear("testhash")
--print("hclear:",ret)
--ret = DB:hkeys("testhash","","",10,128)
local keys = {
    hkey1 = "hval1",
    hkey2 = "hval2",
    hkey3 = 343434,
}
local ret = DB:multi_hset("testhash",keys)
print('multi_hset:',ret)
ret = DB:hscan("testhash","","",10,128)
printT(ret)
ret = DB:hrscan("testhash","k","",10,128)
printT(ret)
local tb = {}
table.insert(tb,"num1")
--table.insert(tb,"hkey2")
print("num of tb:",#tb)
ret = DB:multi_hget("testhash",tb,128)
print('multi_hget:')
printT(ret)
keys = {"hkey1","hkey2","hkey3"}
print("hdel:",DB:multi_hdel("testhash",keys))

print('hscan after del:')
ret = DB:hscan("testhash","","",10,128)
printT(ret)

]]--
DB:zset("testzset","key1",187)
DB:zset("testzset","key2",7)
DB:zset("testzset","key3",87)
DB:zset("testzset","key4",65)
DB:zset("testzset","key5",32)
local r = DB:zget("testzset","key1")
print("zget:",r)
print("incr by 11:",DB:zincr("testzset","key1",11))
--DB:zdel("testzset","key1") --local r = DB:zget("testzset","key1")
local size = DB:zsize("testzset")
print("zsize:",size)
--print("zclear:", DB:zclear("testzset"))
local kn = "key3"
print("zrank:",kn,DB:zrank("testzset",kn))
print("zrrank:",kn,DB:zrrank("testzset",kn))
print("zrange:")
--local rstb = DB:zrange("testzset",0,10)
print("zrrange:")
--local rstb = DB:zrrange("testzset",0,10)
print("zkeys:")
local rstb = DB:zkeys("testzset","k",1,200,10)
printT(rstb)
print("zscan:")
local rstb = DB:zscan("testzset","k",1,200,10)
printT(rstb)
print("multi_zget:")
local keys = {"key1","key2","key3"}
local rstb = DB:multi_zget("testzset",keys)
printT(rstb)

local tb = {
    key4 = 4444,
    key5 = 5555,
    key6 = 6666
}
DB:multi_zset("testzset",tb)
print("zrscan:")
local rstb = DB:zrscan("testzset","k",200000,1,10)
printT(rstb)
DB:multi_zdel("testzset",{"key4","key5","key6"})
print("zrscan:")
local rstb = DB:zrscan("testzset","k",200000,1,10)
printT(rstb)
print("qpush:",DB:qpush("qtest",'234987987987wtf'))
local v = DB:qpop("qtest")
print("qpop:",v)
