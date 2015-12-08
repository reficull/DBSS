module(..., package.seeall)


tbStringToCharArray = tbStringToCharArray or {}
--字符串常量用这个，现在可以废掉这个了
--[[function GetTableFromString(str)--记忆化，转换前先查找
    if tbStringToCharArray[str] then return #str, tbStringToCharArray[str] end
    tbStringToCharArray[str] = {}
    local tbStr = tbStringToCharArray[str]
    for i = 1, #str do
        tbStr[i] = str:byte(i)
    end
    return #str, tbStr
end--]]

--字符串变量用这个
--[[function SetTableFromString(tb, str)
	for i = 1, #str do
		tb[i] = str:byte(i)
	end
	return #str
end--]]

tbCharArrayToString = tbCharArrayToString or {}
function GetStringFromTable(tbLen, tb)
    for i = 1, tbLen do
        tbCharArrayToString[i] = string.char(tb[i] % 256)
    end
    return table.concat(tbCharArrayToString, "", 1, tbLen)
end

function NewEnum(tb, nStartFrom)	--创建一个枚举类型
    nStartFrom = nStartFrom or 1
    local o = {m_begin = nStartFrom, m_end = nStartFrom + #tb}
    for i = 1, #tb do
		o[tb[i]] = i - 1 + nStartFrom
    end
    o.__index = function(t, k) assert(nil, k .. " not exist") end
    setmetatable(o, o)
    return o
end

function Div(a, b)
    return (a - a % b) / b
end

--获取一个整形的第几位是什么
function GetBit(n, bitIndex)
    return Div(n, 2^bitIndex) % 2
end

--设置一个整形的第几位为0或1
function SetBit(n, bitIndex, zeroOrOne)
   local bit = GetBit(n, bitIndex)
   if bit == 0 and zeroOrOne == 1 then
    return n + 2 ^ bitIndex
   end
   if bit == 1 and zeroOrOne == 0 then
    return n - 2 ^ bitIndex
   end
   return n
end

function getValue(tb)
    local ret = {}
    if type(tb) == "table" then
        local i = 1
        for k, v in pairs(tb) do
            ret[i] = v
            i = i + 1
        end
    else
        table.insert(ret,tb)
    end
    return ret
end

function PrintTable(tb, step)
	step = step or 0
    if type(tb) == "table" then
        for k, v in pairs(tb) do
            print(string.rep("	", step), k, "=", v)
            if type(v) == "table" then
                PrintTable(v, step + 1)
            end
        end
    else
        print(tb)
    end
end

function print_r(table)
    print('{')
    local cnt=0
    for v in pairs(table) do
        if cnt > 0 then
            print(',')
        end
        cnt = cnt+1
        if type(v) == 'string' then
            print(string.format("%s=", v)) 
        end 
        if type(table[v]) == 'table' then
            print_r(table[v])
        else
            print(table[v])
        end 
    end 
    print('}')
end

function GDB()
	print("\n--------Begin GDB\n")
	local level = 2
	local info = debug.getinfo(level)
	print(info.source, info.name, info.currentline)	
	for i = 1, math.huge do
		local name, value = debug.getlocal(level, i)
		if not name then break end
		print(name, "=", value)
	end
	print("\n--------End GDB\n")
end

function IncludeClassHeader(moduleName)
	--loadfile("../scripts/common/ClassHeader.lua")(moduleName)
    local helper   = require 'scripts/helper'
    local basepath = helper.basepath
    LUA_SCRIPT_ROOT = basepath()
	loadfile(LUA_SCRIPT_ROOT.."common/ClassHeader.lua")(moduleName)
end


function findFunction(x)
    assert(type(x) == "string")
    local f=_G
    for v in x:gmatch("[^%.]+") do
        print(v)
        if type(f) ~= "table" then
            return nil, "looking for '"..v.."' expected table, not "..type(f)
        end
        f=f[v]
    end
    if type(f) == "function" then
        return f
    else
        return nil, "expected function, not "..type(f)
    end
end

function scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    --local num = debug.getinfo(1).currentline
    return str..':' --str:match("(.*/)")..":"..num
end

function table.isEmpty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function string.mpack(str)
    local ret = ""
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local c1,c2,c3= c:byte(1, -1)
       -- print("c1:"..c1..",c2:"..assert(c2 or -1 , " not multitye")..",c3:"..assert(c3 or -1,"not multibyte char"))
        local char = DEC_HEX(c1)..DEC_HEX(assert(c2 or -1,"not miltibyte")) .. DEC_HEX(assert(c3 or -1,"not mbyte"))

        ret = ret .. char
        --print('tostring:'..hex2string(char))
    end
    --print(sp()..debug.getinfo(1).currentline .. ":hex:"..ret)
    return ret
end

function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end
function hex2string(hex)
    local str, n = hex:gsub("(%x%x)[ ]?", function (word)
        return string.char(tonumber(word, 16))
    end)
    return str
end

function string.trim (s)
    if not s == "" then
        return assert(string.gsub(s, "^%s*(.-)%s*$", "%1") or s)
    else
        return ""
    end
end

function string.mtrim (s)
    if not s == "" then
        return assert(string.gsub(s, "^%s*([%S]+)%s*$", "%1") or s)
    else
        return ""
    end
end

function getRand(tb)
    if #tb > 1 then
        local num = math.random(1,#tb)
        return table.remove(tb,num)
    else
        return tb[1]
    end
end
function string.split(str, delimiter,greedy)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    if greedy == nil or greedy == '' then
        for match in (str..delimiter):gmatch("(.-)"..delimiter.."+(.-)") do
            table.insert(result, match)
        end
    else
        for match in (str..delimiter):gmatch("(.*)"..delimiter) do
            table.insert(result, match)
        end

    end
    return result
end

function extractDict(fileName)
    local ret = {}
    local i = 1 
    local k = ""
    local v = ""
    for line in io.lines(fileName) do
        if i%3 == 1 then
            k = line
        elseif i%3 == 2 then
            v  = line
        elseif i%3 == 0 then
            if string.trim(line) == "" then
                --print(k..":"..v)
                table.insert(ret,k..'|'..v.."\n")
            else
                --print("not empty line:"..line)
            end
        end
        i=i+1
    end
    print(#ret,i)
    return ret
end

function line2table(fileName)
    local ret = {}
    for line in io.lines(fileName) do
        table.insert(ret,line)
    end
    return ret 
end


