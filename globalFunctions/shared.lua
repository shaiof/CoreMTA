function math.round(num, numDecimalPlaces)
	local numDec = numDecimalPlaces or 0
	check('nn', num, numDecimalPlaces)
	local mult = 10 ^ numDec
	return math.floor(num * mult + 0.5) / mult
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

function isValueInTable(theTable, value, columnID)
    assert(theTable, 'Bad argument 1 @ isValueInTable (table expected, got '..type(theTable)..')')
    local checkIsTable = type(theTable)
    assert(checkIsTable == 'table', 'Invalid value type @ isValueInTable (table expected, got '..checkIsTable..')')
    assert(value, 'Bad argument 2 @ isValueInTable (value expected, got '..type(value)..')')
    assert(columnID, 'Bad argument 3 @ isValueInTable (number expected, got '..type(columnID)..')')
    local checkIsID = type(columnID)
    assert(checkIsID == 'number', 'Invalid value type @ isValueInTable (number expected, got '..checkIsID..')')
    for i, v in ipairs (theTable) do
        if v[columnID] == value then
            return true, i
        end
    end
    return false
end

function rangeToTable(range)
	assert(range, type(range) == 'string', 'Bad argument @ rangeToTable. Expected string, got '..type(range))
	local numbers = split(range, ',')
	local output = {}
	for k, v in ipairs(numbers) do
		if tonumber(v) then
			table.insert(output, tonumber(v))
		else
			local st, en = tonumber(gettok(v, 1, '-')), tonumber(gettok(v, 2, '-'))
			if st and en then
				for i = st, en, (st < en and 1 or -1) do
					table.insert(output, tonumber(i))
				end
			end
		end
	end
	return output
end

function setTableProtected(tbl)
	return setmetatable({}, {__index = tbl, __newindex = function(t, n, v)
		error('attempting to change constant '..tostring(n)..' to '..tostring (v), 2)
	end})
end

function insertSortingByIndex(array, e)
	local data = array
	for i = 2, #data do
		local j = i - 1
		local ass = data[i]
		while j > 0 and data[j][e] > ass[e] do
			data[j + 1] = data[j]
			j = j - 1
		end
		data[j + 1] = ass
	end
	return data
end

function fixedBubbleSortingByIndex(array, e)
	local data = array
	local i = #data
	while i >= 2 do
		local idx = 0
		for j = 1, (i - 1) do
			if data[j][e] > data[j + 1][e] then
				local holder = data[j][e]
				data[j][e] = data[j + 1][e]
				data[j + 1][e] = holder
				idx = j
			end
		end
		i = idx
	end
	return data
end

function table.compare(a1, a2)
	if type(a1) == 'table' and type(a2) == 'table'then
		local function size(t)
			if type(t) ~= 'table' then
				return false 
			end
			local n = 0
			for _ in pairs(t) do
				n = n + 1
			end
			return n
		end

		if size(a1) == 0 and size(a2) == 0 then
			return true
		elseif size(a1) ~= size(a2) then
			return false
		end
		
		for _, v in pairs(a1) do
			local v2 = a2[_]
			if type(v) == type(v2) then
				if type(v) == 'table' and type(v2) == 'table' then
					if size(v) ~= size(v2) then
						return false
					end
					if size(v) > 0 and size(v2) > 0 then
						if not table.compare(v, v2) then 
							return false 
						end
					end	
				elseif type(v) == 'string' or type(v) == 'number' and type(v2) == 'string' or type(v2) == 'number' then
					if v ~= v2 then
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end
		return true
	end
	return false
end

function table.empty(a)
    if type(a) ~= 'table' then
        return false
    end
    
    return next(a) == nil
end

function table.merge(table1, ...)
    for _, table2 in ipairs(arg) do
        for key, value in pairs(table2) do
            if (type(key) == 'number') then
                table.insert(table1, value)
            else
                table1[key] = value
            end
        end
    end
    return table1
end

function table.getRandomRows(table, rowsCount)
	if #table > rowsCount then
		local t = {}
		local random
		while rowsCount > 0 do
			random = math.random(#table)
			if not t[random] then
				t[random] = random
				rowsCount = rowsCount - 1
			end
		end
		local rows = {}
		for i, v in pairs(t)do
			rows[#rows + 1] = v
		end
		return rows
	else
		return table
	end
end

local utils = {}

function utils.map(n, start1, stop1, start2, stop2)
    return ((n-start1)/(stop1-start1))*(stop2-start2)+start2
end

function utils.constrain(num, low, high)
    if not num or not low or not high then
		error('constrain missing arguments', 2)
	end
    return (num >= low and num <= high and num) or (num < low and low) or (num > high and high)
end

function table.removeValue(t, value)
	assert(type(value) ~= 'nil', 'arg 1 missing value')
	for i=#t, 1, -1  do
		if (t[i] == value) then
			t:remove(i)
			return true
		end
	end
	return false
end

function table.contains(t, value)
	assert(type(value) ~= 'nil', 'arg 1 missing value')
	for i=1, #t do
		if (t[i] == value) then
			return true
		end
	end
	return false
end

function table.map(t, func)
	assert(type(func) == 'function', 'arg 1 not a function')
	local new = {}
	for i=1, #t do
		new[i] = func(t[i], i, t)
	end
	return new
end

function table.filter(t, func)
	assert(type(func) == 'function', 'arg 1 not a function')
	local new = {}
	for i=1, #t do
		local value = t[i]
		if func(value, i, t) then
			new[#new+1] = value
		end
	end
	return new
end

function table.reduce(t, func, startval)
	assert(type(func) == 'function', 'arg 1 not a function')
	local value = startval or 0
	for i=1, #t do
		value = func(value, t[i], startval)
	end
	return value
end

function table.copy(t)
	local new = {}
	for k, v in pairs(t) do
		if type(v) == 'table' then
			v = v:copy()
		end
		new[k] = v
	end
	return new
end

function getPositionFromElementOffset(element, offX, offY, offZ)
	local m = getElementMatrix(element)
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z
end

function getElementSpeed(theElement, unit)
    assert(isElement(theElement), 'Bad argument 1 @ getElementSpeed (element expected, got '..type(theElement)..')')
    local elementType = getElementType(theElement)
    assert(elementType == 'player' or elementType == 'ped' or elementType == 'object' or elementType == 'vehicle' or elementType == 'projectile', 'Invalid element type @ getElementSpeed (player/ped/object/vehicle/projectile expected, got '..elementType..')')
    assert((unit == nil or type(unit) == 'string' or type(unit) == 'number') and (unit == nil or (tonumber(unit) and (tonumber(unit) == 0 or tonumber(unit) == 1 or tonumber(unit) == 2)) or unit == 'm/s' or unit == 'km/h' or unit == 'mph'), 'Bad argument 2 @ getElementSpeed (invalid speed unit)')
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == 'm/s') and 50 or ((unit == 1 or unit == 'km/h') and 180 or 111.84681456)
    return (Vector3(getElementVelocity(theElement)) * mult).length
end

function getElementsInDimension(theType, dimension)
	local elementsInDimension = {}
	for key, value in ipairs(getElementsByType(theType)) do
		if getElementDimension(value) == dimension then
			table.insert(elementsInDimension, value)
		end
	end
	return elementsInDimension
end

function getElementsWithinMarker(marker)
	if (not isElement(marker) or getElementType(marker) ~= 'marker') then
		return false
	end
	local markerColShape = getElementColShape(marker)
	local elements = getElementsWithinColShape(markerColShape)
	return elements
end

function isElementInRange(ele, x, y, z, range)
	if isElement(ele) and type(x) == 'number' and type(y) == 'number' and type(z) == 'number' and type(range) == 'number' then
		return getDistanceBetweenPoints3D(x, y, z, getElementPosition(ele)) <= range
	end
	return false
end

function isElementMoving(theElement)
	if isElement(theElement) then
		return Vector3(getElementVelocity(theElement)).length ~= 0
	end
	return false
end

function multi_check(source, ...)
	for _, argument in ipairs( arg ) do
		if argument == source then
			return true
		end
	end
	return false
end

function setElementSpeed(element, unit, speed)
	local unit = unit or 0
	local speed = tonumber(speed) or 0
	local acSpeed = getElementSpeed(element, unit)
	if acSpeed then
		local diff = speed/acSpeed
		if diff ~= diff then return false end
		local x, y, z = getElementVelocity(element)
		return setElementVelocity(element, x*diff, y*diff, z*diff)
	end
	return false
end

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

function require(script, filePath)
	if type(filePath) ~= 'string' then
		error("bad arg #1 to 'require' (string expected)", 3)
	end

	local buffer = getFileContents(filePath)

	if not buffer then
		error("can't require '"..filePath.."' (doesn't exist)", 2)
	end

	buffer = 'return function() '..buffer..' end'
	
	return loadstring(buffer)()()
end

function importModule(name) -- triggers this
	if name:sub(-4) == '.lua' then
		local path = '/modules/'..name
		
		if fileExists(path) then
			local f = fileOpen(path)
			local buffer = f:read(f.size)
			f:close()
			buffer = 'return function() '..buffer..' end'
			return loadstring(buffer)()() -- it returns the whole buffer AND executes it
		end
	end
	
	return false
end