local write, writeIndent, writers, refCount;

persistence =
{
	store = function (path, ...)
		local buffer = {}
		local n = select("#", ...);

		-- Count references
		local objRefCount = {}; -- Stores reference that will be exported
		for i = 1, n do
			refCount(objRefCount, (select(i,...)));
		end;

		-- Export Objects with more than one ref and assign name
		-- First, create empty tables for each
		local objRefNames = {};
		local objRefIdx = 0;
		table.insert(buffer, "-- Persistent Data\n");
		table.insert(buffer, "local multiRefObjects = {\n");
		for obj, count in pairs(objRefCount) do
			if count > 1 then
				objRefIdx = objRefIdx + 1;
				objRefNames[obj] = objRefIdx;
				table.insert(buffer, "{};"); -- table objRefIdx
			end;
		end;
		table.insert(buffer, "\n} -- multiRefObjects\n");

		-- Then fill them (this requires all empty multiRefObjects to exist)
		for obj, idx in pairs(objRefNames) do
			for k, v in pairs(obj) do
				table.insert(buffer, "multiRefObjects["..idx.."][");
				write(buffer, k, 0, objRefNames);
				table.insert(buffer, "] = ");
				write(buffer, v, 0, objRefNames);
				table.insert(buffer, ";\n");
			end;
		end;

		-- Create the remaining objects
		for i = 1, n do
			table.insert(buffer, "local ".."obj"..i.." = ");
			write(buffer, (select(i,...)), 0, objRefNames);
			table.insert(buffer, "\n");
		end

		-- Return them
		if n > 0 then
			table.insert(buffer, "return obj1");
			for i = 2, n do
				table.insert(buffer, " ,obj"..i);
			end;
			table.insert(buffer, "\n");
		else
			table.insert(buffer, "return\n");
		end;

		-- Write the file
		local content = table.concat(buffer)
		local file = File(path)
		file:write_string(content)
	end;

	load = function (path)
		local file = File(path);
		if file:exists() then
			local content = file:read_to_string()
			local f, e = loadstring(content);
			if f then
				return f();
			else
				return nil, e;
			end;
		else
			return nil, "File doesn't exist"
		end
	end;
}

-- Private methods

-- write thing (dispatcher)
write = function (buffer, item, level, objRefNames)
	writers[type(item)](buffer, item, level, objRefNames);
end;

-- write indent
writeIndent = function (buffer, level)
	for i = 1, level do
		table.insert(buffer, "\t");
	end;
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;

-- Format items for the purpose of restoring
writers = {
	["nil"] = function (buffer, item)
			table.insert(buffer, "nil");
		end;
	["number"] = function (buffer, item)
		table.insert(buffer, tostring(item));
		end;
	["string"] = function (buffer, item)
		table.insert(buffer, string.format("%q", item));
		end;
	["boolean"] = function (buffer, item)
			if item then
				table.insert(buffer, "true");
			else
				table.insert(buffer, "false");
			end
		end;
	["table"] = function (buffer, item, level, objRefNames)
			local refIdx = objRefNames[item];
			if refIdx then
				-- Table with multiple references
				table.insert(buffer, "multiRefObjects["..refIdx.."]");
			else
				-- Sort keys alphabetically
				local sortedKeys = {}
				for k in pairs(item) do
					table.insert(sortedKeys, k)
				end
				table.sort(sortedKeys)

				-- Single use table
				table.insert(buffer, "{\n");
				for _, k in ipairs(sortedKeys) do
					local v = item[k]
					writeIndent(buffer, level+1);
					table.insert(buffer, "[");
					write(buffer, k, level+1, objRefNames);
					table.insert(buffer, "] = ");
					write(buffer, v, level+1, objRefNames);
					table.insert(buffer, ";\n");
				end
				writeIndent(buffer, level);
				table.insert(buffer, "}");
			end;
		end;
	["function"] = function (buffer, item)
			-- Does only work for "normal" functions, not those
			-- with upvalues or c functions
			local dInfo = debug.getinfo(item, "uS");
			if dInfo.nups > 0 then
				table.insert(buffer, "nil --[[functions with upvalue not supported]]");
			elseif dInfo.what ~= "Lua" then
				table.insert(buffer, "nil --[[non-lua function not supported]]");
			else
				local r, s = pcall(string.dump,item);
				if r then
					table.insert(buffer, string.format("loadstring(%q)", s));
				else
					table.insert(buffer, "nil --[[function could not be dumped]]");
				end
			end
		end;
	["thread"] = function (buffer, item)
			table.insert(buffer, "nil --[[thread]]\n");
		end;
	["userdata"] = function (buffer, item)
			if type(item.GetString) == "function" then
				table.insert(buffer, item:GetString());
			else
				table.insert(buffer, "nil --[[userdata]]\n");
			end
		end;
}