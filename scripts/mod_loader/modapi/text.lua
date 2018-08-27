
--[[
	Returns true if this string starts with the prefix string
--]]
function modApi:stringStartsWith(str, prefix)
	return string.sub(str,1,string.len(prefix)) == prefix
end

--[[
	Returns true if this string ends with the suffix string
--]]
function modApi:stringEndsWith(str, suffix)
	return suffix == "" or string.sub(str,-string.len(suffix)) == suffix
end

--[[
	Trims leading and trailing whitespace from the string.

	trim11 from: http://lua-users.org/wiki/StringTrim
--]]
function modApi:trimString(str)
	local n = str:find"%S"
	return n and str:match(".*%S", n) or ""
end

function modApi:splitString(test,sep)
	if sep == nil then
		sep = "%s"
	end

	local t = {}
	for str in string.gmatch(test, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	return t
end

--[[
	Same as modApi:splitString, but includes empty strings

	http://lua-users.org/wiki/SplitJoin
--]]
function modApi:splitStringEmpty(str, sep)
	if sep == nil then
		sep = "%s"
	end

	local ret = {}
	local n = 1
	for w in str:gmatch("([^"..sep.."]*)") do
		ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
		if w == "" then
			n = n + 1
		end -- step forwards on a blank but not a string
	end
	return ret
end

function modApi:overwriteTextTrue(id,str)
	return self:overwriteText(id,str)
end

function modApi:overwriteText(id,str)
	assert(type(id) == "string")
	assert(type(str) == "string")
	self.textOverrides[id] = str
end

function modApi:addWeapon_Texts(tbl)
	assert(type(tbl) == "table")
	for k,v in pairs(tbl) do
		Weapon_Texts[k] = v
	end
end

function modApi:addPopEvent(event, msg)
	assert(type(event) == "string")
	assert(type(msg) == "string")
	if not self.PopEvents[event] then
		self.PopEvents[event] = {}
	end
	
	table.insert(self.PopEvents[event],msg)
end

function modApi:setPopEventOdds(event, odds)
	assert(type(event) == "string")
	assert(self.PopEvents[event])
	assert(odds == nil or type(odds) == "number")
	
	self.PopEvents[event].Odds = odds
end

function modApi:addOnPopEvent(fn)
	assert(type(fn) == "function")
	table.insert(self.onGetPopEvent,fn)
end
