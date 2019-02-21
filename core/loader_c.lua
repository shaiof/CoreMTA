Res = {}
local clientResources = {}
local resources = {}
--test

function Res.new(name)
	local self = setmetatable({}, {__index = Res})
	self.name = name
	self.client = {}
	return self
end

function Res:loadClientScript(fileName, buffer)
	-- get function that will run and return the script object (see Script.create)
	local script = Script.create(self.name, buffer)
	-- setup a globals table that will hold all the global vars/functions from the script file
	local globals = {}
	-- temporarily allow access to the Lua _G table through the globals table in order to access the global vars/functions in the script
	setmetatable(globals, {__index = _G})
	-- set the environment of the script function to sandbox everything that's executed by/through it
	setfenv(script, globals)
	-- execute the script function
	script = script()
	-- store the script's globals into the script object
	script.globals = globals
	-- store the script object in the server table in the resource object
	self.client[fileName] = script
end

function Res:unload()
	for fileName, script in pairs(self.client) do
		script:unload()
	end
end

function Res.start(clientRes)
	for i=1, #clientRes do
		local name = clientRes[i].name
		local urls = clientRes[i].urls
		local res = resources[name] or Res.new(name)
		resources[name] = res
		if clientRes[i].urls[1] then
			table.insert(clientResources, clientRes[i].name)
		end

		for i=1, #urls do
			local url = urls[i]
			Script.download(url, function(data, err)
				if err > 0 then
					print('err', err)
				else
					if data then
						res:loadClientScript(url, data)
					end
				end
			end)
		end
	end

	--setTimer(function() triggerServerEvent('onClientReady', resourceRoot, name) end, 500, 1)
end
addEvent('onResStart', true)
addEventHandler('onResStart', resourceRoot, Res.start)

function Res.stop(name)
	local res = resources[name]
	if res then
		res:unload()
		resources[name] = nil
		for i=1, 2 do collectgarbage() end
	end
end
addEvent('onResStop', true)
addEventHandler('onResStop', resourceRoot, Res.stop)

function Res.inspect(name)
	local name = name:lower()
	local res = resources[name]
	if res then
		iprint('client', res)
	end
end

function Res.get(name)
	return name and resources[name]
end

Script = {}

function Script.new(name)
	local self = setmetatable({}, {__index = Script})
	self.name = name:lower()
	self.events = {}
	self.cmds = {}
	self.timers = {}
	return self
end

function Script:event(name, root, func, ...)
	addEventHandler(name, root, func, ...)
	table.insert(self.events, {name, root, func})
end

function Script:timer(callback, interval, times, ...)
	local timer = setTimer(callback, interval, times, ...)
	table.insert(self.timers, timer)
	return timer
end

function Script:cmd(cmd, callback, restricted)
	addCommandHandler(cmd, callback, restricted or false, false)
	table.insert(self.cmds, {cmd, callback})
end

function Script:unload()
	for i=1, #self.events do
		removeEventHandler(unpack(self.events[i]))
		self.events[i] = nil
	end

	for i=1, #self.cmds do
		removeCommandHandler(unpack(self.cmds[i]))
		self.cmds[i] = nil
	end

	clearTable(self)
end

function Script.download(url, callback)
	if not url then return end
	requestBrowserDomains({url}, true, function()
		if isBrowserDomainBlocked(url, true) then
			Script.download(url, callback)
		else
			fetchRemote(url, callback)
		end
	end)
end

function Script.create(name, buffer)
	local str = buffer:gsub('addCommandHandler', 's:cmd')
	str = str:gsub('addEventHandler', 's:event')
	str = str:gsub('setTimer', 's:timer')
	str = ('return function() local s = Script.new("%s") %s return s end'):format(name, str)

	local fnc, err = loadstring(str)
	
	local suc = pcall(fnc)
	if not suc then
		local _, last, lineNum = err:find(':(%d+):')
		err = err:sub(last+2)
		error(('[%s][%s]:%s: %s'):format(name, fileName, lineNum, err), 0)
	else
		return fnc()
	end
end

addCommandHandler('inspectres', function(...) if not arg[2] then return end Res.inspect(arg[2]) end)
