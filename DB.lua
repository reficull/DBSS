module(..., package.seeall)
require "config"
local ffi      = require 'ffi'
local helper   = require 'helper'
local basepath = helper.basepath
local random   = helper.random
local shuffle  = helper.C_random_shuffle
local C        = ffi.C
LUA_SCRIPT_ROOT = basepath()
ssdb = assert(ffi.load("/usr/local/lib/libDBSS.so"),"load libDBSS failed")
--ssdb = assert(ffi.load(LUA_SCRIPT_ROOT .. 'build/release/lib/libDBSS.so'),"load libDBSS.so failed")
ffi.cdef[[
    typedef struct {
        char const** ptr;
        uint64_t count;
    } vec_t;
    typedef struct {
        char const *str;
        int64_t num;
    } si_t;

    double** get_pointer(); 
    
    typedef struct DBSS DBSS;
    DBSS *DBSS_new(char const* ip, int port); 
    void DBSS_gc(void *this_);
    
    int DBSS_get(DBSS* this_,char const * key,void* v);
    int DBSS_set(DBSS* this_,char const * key,char const * val);
    int DBSS_seti(DBSS* this_,char const * key,int val);
    int DBSS_setxi(DBSS* this_,char const * key,int val,int ttl);
    int DBSS_setx(DBSS* this_,char const * key,char const * val,int ttl);
    int DBSS_keys(DBSS* this_,vec_t* vec,uint64_t limit,uint64_t vlen,char const *key_start,char const *key_end);
    int DBSS_scan(DBSS* this_,vec_t* vec,uint64_t limit ,uint64_t vlen,char const *key_start,char const *key_end);
    int DBSS_rscan(DBSS* this_,vec_t* vec,uint64_t limit ,uint64_t vlen,char const *key_start,char const *key_end );
    int DBSS_del(DBSS* this_,char const* key);
	int DBSS_incr(DBSS* this_,char const *key, int64_t incrby, int64_t *ret);
	int DBSS_multi_get(DBSS* this_,vec_t *ret,char const **keys,uint64_t size,uint64_t vlen);
    int DBSS_multi_set(DBSS* this_,char const **kvs,uint64_t size);
    int DBSS_multi_del(DBSS* this_,char const **keys,uint64_t size);
	int DBSS_hget(DBSS* this_,char const *name, char const *key, char const *val);
	int DBSS_hset(DBSS* this_,char const *name, char const *key, char const *val);
	int DBSS_hdel(DBSS *_this_,char const *name, char const *key);
	int DBSS_hincr(DBSS *this_,char const *name, char const *key, int64_t incrby, int64_t *ret);
    int DBSS_hsize(DBSS *this_,char const *name, int64_t *ret);
	int DBSS_hclear(DBSS *this_,char const *name, int64_t *ret);
	int DBSS_hkeys(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end);
	int DBSS_hscan(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end );
	int DBSS_hrscan(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end );
	int DBSS_multi_hget(DBSS *this_,vec_t *ret,char const *name,char const **keys,uint64_t size,uint64_t vlen);
	int DBSS_multi_hset(DBSS *this_,char const *name,char const **kvs,uint64_t size);
	int DBSS_multi_hdel(DBSS *this_,char const *name, char const **keys,uint64_t size);
	int DBSS_zget(DBSS *this_,char const *name, char const *key, int64_t *ret);
	int DBSS_zset(DBSS *this_,char const *name, char const *key, int64_t score);
	int DBSS_zdel(DBSS *this_,char const *name, char const *key);
	int DBSS_zincr(DBSS *this_,char const *name, char const *key, int64_t incrby, int64_t *ret);
	int DBSS_zsize(DBSS *this_,char const *name, int64_t *ret);
	int DBSS_zclear(DBSS *this_,char const *name, int64_t *ret);
	int DBSS_zrank(DBSS *this_,char const *name, char const *key, int64_t *ret);
	int DBSS_zrrank(DBSS *this_,char const *name, char const *key, int64_t *ret);
	int DBSS_zrange(DBSS *this_,char const *name,vec_t *vec,uint64_t offset, uint64_t limit,uint64_t vlen);
	int DBSS_zrrange(DBSS *this_,char const *name,vec_t *vec,uint64_t offset, uint64_t limit,uint64_t vlen);
	int DBSS_zkeys(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen);
	int DBSS_zscan(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen);
	int DBSS_zrscan(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen);
	int DBSS_multi_zget(DBSS *this_,char const *name, char const **keys,vec_t *ret,uint64_t size,uint64_t vlen);
	int DBSS_multi_zset(DBSS *this_,char const *name, si_t **kss,uint64_t size);
	int DBSS_multi_zdel(DBSS *this_,char const *name, char const **keys,uint64_t size);
	int DBSS_qpush(DBSS *this_,char const *key, char const *val);
	int DBSS_qpop(DBSS *this_,char const *key, char *val);
    void dbss_version(int *major_, int *minor_, int *patch_);
]]
local aint_t          = ffi.typeof("int[1]")
local aint16_t        = ffi.typeof("int16_t[1]")
local aint64_t        = ffi.typeof("int64_t[1]")
local ptr_chss          = ffi.typeof("char const**")
local ptr_chs          = ffi.typeof("char const*")
local achar_t      = ffi.typeof("char[?]")
local pvoid_t           = ffi.typeof("void*") 
local vec_t             = ffi.typeof("vec_t")
local si_t              = ffi.typeof("si_t")
--local NULL              = ffi.cast(pvoid_t, 0)
--local NULL = ffi.new'void*'
--[[
function ptr(p)
    return p ~= NULL and p or nil
end
]]--
------------------------------ wrap into class like behavior
local mt = {}
mt.__index = mt
function mt.get_pointer()
    local ptr = ffi.new("double**")
    ptr = ssdb.get_pointer()
    print(ptr)
    local size_a = 10
    for i=0,size_a-1 do
        for j=0,size_a-1 do
            io.write(ptr[i][j], ' ')
        end
        io.write('\n')
    end

end
function mt.set(self,key,val)
    local k = ffi.new(achar_t,string.len(key))
    k = key
    local ret
    if type(val) == 'number' then
        local v = ffi.new(aint64_t)
        v = val 
        ret = ssdb.DBSS_seti(self.super,k,v)
    else
        local v = ffi.new(achar_t,255)
        v = val 
        ret = ssdb.DBSS_set(self.super,k,v)
    end
    return ret
end
function mt.setx(self,key,val,ttl)
    local k = ffi.new(achar_t,string.len(key))
    local ttd = ffi.new(aint64_t)
    ttd = ttl
    k = key
    local ret
    if type(val) == 'number' then
        local v = ffi.new(aint64_t)
        v = val 
        ret = ssdb.DBSS_setxi(self.super,k,v,ttd)
    else
        local v = ffi.new(achar_t,255)
        v = val 
        ret = ssdb.DBSS_setx(self.super,k,v,ttd)
    end
    return ret
end


function mt.get(self,key)
    local k = ffi.new(achar_t,string.len(key))
    k = key
    local v = ffi.new(achar_t,255)
    ssdb.DBSS_get(self.super,k,v)
    local str = ffi.string(v)
    local err = ""
    if not str then
        err = "get failed"
    end
    return str,err
end

-- local ptr = ffi.new("char const**")
-- ptr = DB.keys(start,end,limit)
-- print(ptr[i][j])
function mt.keys(self,start,endd,limit,vlen)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    ssdb.DBSS_keys(self.super,v_ptr,l,len,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1 do
        k = table.insert(tb,ffi.string(vec.ptr[i]))
    end
    return tb
end
function mt.scan(self,start,endd,limit,vlen)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    ssdb.DBSS_scan(self.super,v_ptr,l,len,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
end
function mt.rscan(self,start,endd,limit,vlen)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    
    ssdb.DBSS_rscan(self.super,v_ptr,l,vlen,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
    
end

function mt.del(self,key)
    local ret = ssdb.DBSS_del(self.super,key)
    return ret
end

function mt.incr(self,key,num)
    local ret = ffi.new(aint64_t)
    ssdb.DBSS_incr(self.super,key,num,ret)
    return tonumber(ret[0])
end

function mt.multi_get(self,keys,vlen)
    if #keys == 1 then
        local ret = {}
        ret[keys[1]] = mt.get(self,keys[1])  
        return ret 
    end
    if not vlen then
        vlen = 128
    end

    local v = ffi.typeof("vec_t")
    local vec = v()
    local kvec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local k_ptr = ffi.cast("vec_t*",kvec)
    local i = 0
    local tb = {}
    local vla = ffi.new("char const*[?]",#keys,unpack(keys))
    local i64 = ffi.new("uint64_t",#keys)
    local vl = ffi.new("uint64_t",vlen)
    ssdb.DBSS_multi_get(self.super,v_ptr,vla,i64,vl)
    local k
    for i=0,#keys*2-1 do
        if i % 2 == 0 then
            k = ffi.string(vec.ptr[i])
        else
            tb[k] = ffi.string(vec.ptr[i])
        end
    end
    return tb
end

function mt.multi_set(self,kvs)
    local tb = {}
    for k,v in pairs(kvs) do
        print('kvs:',k,v)
        table.insert(tb,k)
        table.insert(tb,v.."")
    end
    local vla = ffi.new("char const*[?]",#tb,unpack(tb))
    local s = ffi.new("uint64_t",#tb)
    local ret = ssdb.DBSS_multi_set(self.super,vla,#tb)
    return ret 
end

function mt.multi_del(self,keys)
    local vla = ffi.new("char const*[?]",#keys,unpack(keys))
    local s = ffi.new("uint64_t",#keys)
    local ret = ssdb.DBSS_multi_del(self.super,vla,s)
    
    return ret
end

function mt.hget(self,name,key)
    local n = ffi.cast("char*",name)
    local k
    if type(key) == "table" then
        k = ffi.cast("char*",key[1])
    else
        k = ffi.cast("char*",key)
    end
    local val = ffi.new("char[1]")
    ssdb.DBSS_hget(self.super,n,k,val)
    return ffi.string(val)

end

function mt.hset(self,name,key,val)
    local vstr = val
    if type(val) == "number" then
       vstr = val .. "" 
    end
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local v = ffi.cast("char*",vstr)
    local ret = ffi.new("int")
    ret = ssdb.DBSS_hset(self.super,n,k,v) 
    return tonumber(ret)
end

function mt.hdel(self,name,key)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local ret = ffi.new("int")
    ret = ssdb.DBSS_hdel(self.super,n,k)
    return tonumber(ret)
end

function mt.hincr(self,name,key,num)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local numb = ffi.new("int64_t",num)
    local r = ffi.new(aint64_t)
    local res = ssdb.DBSS_hincr(self.super,n,k,numb,r)
    print('hincr res:',res)
    return tonumber(r[0])
end

function mt.hsize(self,name)
    local n = ffi.cast("char*",name)
    local r = ffi.new("uint64_t[1]")
    local res = ssdb.DBSS_hsize(self.super,n,r)
    return tonumber(r[0])
end
function mt.hclear(self,name)
    local n = ffi.cast("char*",name)
    local r = ffi.new(aint64_t)
    local res = ssdb.DBSS_hclear(self.super,n,r)
    return tonumber(r[0])
end

function mt.hkeys(self,name,start,endd,limit,vlen)
    if not name then
        print("name can not be empty\n")
        return
    end
    local n = ffi.cast("char*",name)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    ssdb.DBSS_hkeys(self.super,v_ptr,n,l,len,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1 do
        k = table.insert(tb,ffi.string(vec.ptr[i]))
    end
    return tb
end

function mt.hscan(self,name,start,endd,limit,vlen)
    if not name then
        print("name can not be empty\n")
        return
    end
    local n = ffi.cast("char*",name)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    ssdb.DBSS_hscan(self.super,v_ptr,n,l,len,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
end

function mt.hrscan(self,name,start,endd,limit,vlen)
    if not name then
        print("name can not be empty\n")
        return
    end
    local n = ffi.cast("char*",name)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local tb = {}
    local s,e,l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    if start then
        s = ffi.cast("char const*",start)
    end
    if endd then
        e = ffi.cast("char const*",endd)
    end
    ssdb.DBSS_hrscan(self.super,v_ptr,n,l,len,s,e)
    local count = tonumber(vec.count)
    local k
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
end
function mt.multi_hget(self,name,keys,vlen)
    if #keys == 1 then
        local ret = {}
        ret[keys[1]] = mt.hget(self,name,keys,vlen)  
        return ret 
    end
    if not vlen then
        vlen = 128
    end

    local v = ffi.typeof("vec_t")
    local vec = v()
    local kvec = v()
    local n = ffi.cast("char*",name)
    local v_ptr = ffi.cast("vec_t*",vec)
    local k_ptr = ffi.cast("vec_t*",kvec)
    local i = 0
    local tb = {}
    local vla = ffi.new("char const*[?]",#keys,unpack(keys))
    local i64 = ffi.new("uint64_t",#keys)
    local vl = ffi.new("uint64_t",vlen)
    ssdb.DBSS_multi_hget(self.super,v_ptr,n,vla,i64,vl)
    local k
    for i=0,#keys*2-1 do
        if i % 2 == 0 then
            k = ffi.string(vec.ptr[i])
        else
            tb[k] = ffi.string(vec.ptr[i])
        end
    end
    return tb
end
function mt.multi_hset(self,name,kvs)
    local n = ffi.cast("char*",name)
    local tb = {}
    for k,v in pairs(kvs) do
        print('kvs:',k,v)
        table.insert(tb,k)
        table.insert(tb,v.."")
    end
    local vla = ffi.new("char const*[?]",#tb,unpack(tb))
    local s = ffi.new("uint64_t",#tb)
    local ret = ssdb.DBSS_multi_hset(self.super,n,vla,#tb)
    return ret 
end

function mt.multi_hdel(self,name,keys)
    local n = ffi.cast("char*",name)
    local vla = ffi.new("char const*[?]",#keys,unpack(keys))
    local s = ffi.new("uint64_t",#keys)
    local ret = ssdb.DBSS_multi_hdel(self.super,n,vla,s)
    
    return ret
end

function mt.zget(self,name,key)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local r = ffi.new(aint64_t)
    local ret = ssdb.DBSS_zget(self.super,n,k,r)
    return tonumber(r[0]); 
end

function mt.zset(self,name,key,score)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local s = ffi.new("int64_t",score)
    local ret = ssdb.DBSS_zset(self.super,n,k,s)
end

function mt.zdel(self,name,key)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    return  ssdb.DBSS_zdel(self.super,n,k)
end
function mt.zincr(self,name,key,num)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local incr = ffi.new("int64_t",num)
    local r = ffi.new(aint64_t)
    ssdb.DBSS_zincr(self.super,n,k,incr,r)
    return tonumber(r[0])
end

function mt.zsize(self,name)
    local n = ffi.cast("char*",name)
    local r = ffi.new(aint64_t)
    ssdb.DBSS_zsize(self.super,n,r)
    return tonumber(r[0])
end

function mt.zclear(self,name)
    local n = ffi.cast("char*",name)
    local r = ffi.new(aint64_t)
    ssdb.DBSS_zclear(self.super,n,r)
    return tonumber(r[0])
end

function mt.zrank(self,name,key)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local r = ffi.new(aint64_t)
    local ret = ssdb.DBSS_zrank(self.super,n,k,r)
    return tonumber(r[0]); 
end

function mt.zrrank(self,name,key)
    local n = ffi.cast("char*",name)
    local k = ffi.cast("char*",key)
    local r = ffi.new(aint64_t)
    local ret = ssdb.DBSS_zrrank(self.super,n,k,r)
    return tonumber(r[0]); 
end

function mt.zrange(self,name,offset,limit,vlen)
    local n = ffi.cast("char*",name)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    o = ffi.new("uint64_t",offset)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    ssdb.DBSS_zrange(self.super,n,v_ptr,o,l,len) 
    local count = tonumber(vec.count)
    local k
    local tb = {}
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
end
function mt.zrrange(self,name,offset,limit,vlen)
    local n = ffi.cast("char*",name)
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local l,v
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    o = ffi.new("uint64_t",offset)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)
    ssdb.DBSS_zrrange(self.super,n,v_ptr,o,l,len) 
    local count = tonumber(vec.count)
    local k
    local tb = {}
    for i=0,count-1,2 do
        table.insert(tb,{ffi.string(vec.ptr[i]) , ffi.string(vec.ptr[i+1])})
    end
    return tb
end

function mt.zkeys(self,name,key_start,score_start,score_end,limit,vlen)
    local n = ffi.cast("char*",name)
    local ks = ffi.cast("char*",key_start   )
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local ss = ffi.new("int64_t",score_start)
    local se = ffi.new("int64_t",score_end)
    local l,len
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)

    local tb = {}
    local ret = ssdb.DBSS_zkeys(self.super,n,v_ptr,ks,ss,se,l,len) 
    local count = tonumber(vec.count)
    print("zkeysret:",count)
    for i=0,count-1 do
        table.insert(tb,ffi.string(vec.ptr[i]))
    end
    return tb

end

function mt.zscan(self,name,key_start,score_start,score_end,limit,vlen)
    local n = ffi.cast("char*",name)
    local ks = ffi.cast("char*",key_start   )
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local ss = ffi.new("int64_t",score_start)
    local se = ffi.new("int64_t",score_end)
    local l,len
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)

    local tb = {}
    local ret = ssdb.DBSS_zscan(self.super,n,v_ptr,ks,ss,se,l,len) 
    local count = tonumber(vec.count)
    print("zscanret:",count)
    for i=0,count-1 do
        table.insert(tb,ffi.string(vec.ptr[i]))
    end
    return tb
end
function mt.zrscan(self,name,key_start,score_start,score_end,limit,vlen)
    local n = ffi.cast("char*",name)
    local ks = ffi.cast("char*",key_start   )
    local v = ffi.typeof("vec_t")
    local vec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local ss = ffi.new("int64_t",score_start)
    local se = ffi.new("int64_t",score_end)
    local l,len
    if not limit then
        limit = 10 
    end
    l = ffi.new("uint64_t",limit)
    if not vlen then
        vlen = 128 
    end
    len =ffi.new("uint64_t",vlen)

    local tb = {}
    local ret = ssdb.DBSS_zrscan(self.super,n,v_ptr,ks,ss,se,l,len) 
    local count = tonumber(vec.count)
    print("zscanret:",count)
    for i=0,count-1 do
        table.insert(tb,ffi.string(vec.ptr[i]))
    end
    return tb
end

function mt.multi_zget(self,name,keys,vlen)
    local n = ffi.cast("char*",name)
    if #keys == 1 then
        local ret = {}
        ret[keys[1]] = mt.zget(self,name,keys[1])  
        return ret 
    end
    if not vlen then
        vlen = 128
    end

    local v = ffi.typeof("vec_t")
    local vec = v()
    local kvec = v()
    local v_ptr = ffi.cast("vec_t*",vec)
    local k_ptr = ffi.cast("vec_t*",kvec)
    local i = 0
    local tb = {}
    local vla = ffi.new("char const*[?]",#keys,unpack(keys))
    local i64 = ffi.new("uint64_t",#keys)
    local vl = ffi.new("uint64_t",vlen)
    ssdb.DBSS_multi_zget(self.super,name,vla,v_ptr,i64,vl)
    local k
    for i=0,#keys*2-1 do
        if i % 2 == 0 then
            k = ffi.string(vec.ptr[i])
        else
            tb[k] = ffi.string(vec.ptr[i])
        end
    end
    return tb
end

function mt.multi_zset(self,name,kvs)
    local i = 0
    local tmptb = {}
    for k,v in pairs(kvs) do 
        local  sit = si_t()
        sit.str = ffi.cast("char*",k)
        sit.num = ffi.new("int64_t",v)
        table.insert(tmptb,sit)
    end
    local size = #tmptb
    local asi_t = ffi.new("si_t*[?]",size,unpack(tmptb))
    local n = ffi.cast("char*",name)
    local s  =ffi.new("uint64_t",size)
    return ssdb.DBSS_multi_zset(self.super,n,asi_t,s)
end

function mt.multi_zdel(self,name,keys)
    local n = ffi.cast("char*",name)
    local s = ffi.new("uint64_t",#keys)
    local vla = ffi.new("char const*[?]",s,unpack(keys))
    return ssdb.DBSS_multi_zdel(self.super,n,vla,s)
end

function mt.qpush(self,key,val)
    local k = ffi.cast("char*",key)
    local v = ffi.cast("char*",val)
    return ssdb.DBSS_qpush(self.super,k,v) 
end

function mt.qpop(self,key,vlen)
    if not vlen then
        vlen = 128
    end
    local k = ffi.cast("char*",key)
    local val = ffi.new("char[?]",vlen)
    ssdb.DBSS_qpop(self.super,k,val)
    return ffi.string(val)
end

function mt.dbss_version()
    local major, minor, patch = ffi.new(aint_t, 0), ffi.new(aint_t, 0), ffi.new(aint_t, 0)
    ssdb.dbss_version(major, minor, patch)
    return major[0], minor[0], patch[0]
end


function DBSS(ip,port)
    local self = {super = ssdb.DBSS_new(ip,port)}
    ffi.gc(self.super,ssdb.DBSS_gc)
    return setmetatable(self,mt)
end

DB = DBSS(config.ssdbIP,config.ssdbPort)
