function check(pattern, ...)
	if type(pattern) ~= 'string' then check('s', pattern) end
	local types = {s = "string", n = "number", b = "boolean", f = "function", t = "table", u = "userdata"}
	for i=1, #pattern do
		local c = pattern:sub(i, i)
		local t = arg.n > 0 and type(arg[i])
		if not t then error('got pattern but missing args') end
		if t ~= types[c] then error("bad argument #"..i.. " to '"..debug.getinfo(2, "n").name.."' ("..types[c].." expected, got "..tostring(t)..")", 3) end
	end
end

function clearTable(t)
	for k, v in pairs(t) do
		if type(v) == 'userdata' and getUserdataType(v) ~= 'player' then
			if isElement(v) or isTimer(v) then
				v:destroy()
			end
		end
		if type(v) == 'table' and k ~= 'root' then
			clearTable(v)
		end
		t[k] = nil
	end
end

local function getFileContents(filePath)
	if filePath and fileExists(filePath) then
		local f = fileOpen(filePath)
		local content = f:read(f.size)
		f:close()
		return content
	end
	return false
end

function require(filePath) -- need to require before Scripts are parsed and loaded OR need to parse the file contents here
	if type(filePath) ~= 'string' then
		error("bad arg #1 to 'require' (string expected)", 3)
	end

	local content = getFileContents(filePath)

	if not content then
		error("can't require '"..filePath.."' (doesn't exist)", 2)
	end

	return loadstring('return function() '..content..' end')()()
end
