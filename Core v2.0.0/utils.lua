function check(pattern, ...)
	if not pattern or type(pattern) ~= 'string' then check('s', pattern) end
	local types = {s = "string", n = "number", b = "boolean", f = "function", t = "table", u = "userdata"}
	for i=1, #pattern do
		local c = pattern:sub(i,i)
		local t = arg.n > 0 and type(arg[i])
		if not t then error('got pattern but missing args') end
		if t ~= types[c] then error("bad argument #"..i.. " to '"..debug.getinfo(2, "n").name.."' ("..types[c].." expected, got "..tostring(t)..")", 3) end
	end
end

function round(num, numDecimalPlaces)
	local numDec = numDecimalPlaces or 0
	check('nn', num, numDecimalPlaces)
	local mult = 10 ^ numDec
	return math.floor(num * mult + 0.5) / mult
end

function clearTable(t)
	check('t', t)
	for k, v in pairs(t) do
		if type(v) == 'userdata' then
			if getUserdataType(v) ~= 'player' then
				if isElement(v) or isTimer(v) then
					v:destroy()
				end
			end
		end
		if type(v) == 'table' then
			clearTable(v)
		end
		t[k] = nil
	end
end

function posToJSON(plr)
	check('u', plr)
	local x,y,z = getElementPosition(plr)
	local rx,ry,rz = getElementRotation(plr)
	return toJSON({x,y,z,rx,ry,rz})
end

function getColumnIdFromTitle(gridlist, title)
	check('us', gridlist, title)
	for id=1, gridlist:getColumnCount() do
		if gridlist:getColumnTitle(id) == title then
			return id
		end
	end
	return false
end

function checkDomain(link,callback)
	callback = callback or function() end
	check('sf',link,callback)
	if not isBrowserDomainBlocked(link,true) then
		return requestBrowserDomains({link},true,callback)
	end
	return false
end
