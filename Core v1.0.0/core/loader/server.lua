loadedResources = {}
clientLoadedScripts = {}

Script = {}
Script.__index = Script

function Script.new(name)
	check('s', name)
	local self = setmetatable({}, Script)
	self.name = string.lower(name)
	self.events = {}
	self.cmds = {}
	self.timers = {}
	return self
end

function Script:event(name, root, func, ...)
	addEventHandler(name, root, func, ...)
	table.insert(self.events, {name, root, func})
end

function Script:cmd(cmd, callback, restricted)
	addCommandHandler(cmd, callback, restricted or false, false)
	table.insert(self.cmds, {cmd, callback})
end

function Script:timer(callback, interval, times, ...)
	local timer = setTimer(callback, interval, times, ...)
	table.insert(self.timers, timer)
	return timer
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

function convertBuffer(buffer)
	local s = string.gsub(buffer, 'addCommandHandler', 's:cmd')
	s = string.gsub(s, 'addEventHandler', 's:event')
	s = string.gsub(s, 'setTimer', 's:timer')
	return s
end

function Script:stop()
	local name = self.name
	self:unload()
	loadedResources[string.lower(name)] = nil
	clientLoadedScripts[string.lower(name)] = nil
	for i=1, 2 do
		collectgarbage()
	end
	triggerClientEvent('onScriptStop', resourceRoot, string.lower(name))
	print(string.lower(name)..' has been stopped.')
end

function Script.restart(name)
	local res = loadedResources[string.lower(name)]
	if res then
		res:stop()
		Script.start(string.lower(name))
	end
end

function Script.start(name)
	local name = name:lower()
	if Script.get(name) then return print('That resource is already started.') end
	
	local data = Script.getMeta(name)
	
	if not data then
		print('Cant find meta for "'..name..'"')
	else
		if data.server and type(data.server) == 'table' then
			for i=1, #data.server do
				local path = 'addons/'..name..'/'..data.server[i]
				if fileExists(path) then
					local f = fileOpen(path)
					local b = fileRead(f, fileGetSize(f))
					local str = ('return function() local s = Script.new("%s") %s return s end'):format(name, convertBuffer(b))
					loadedResources[name] = loadstring(str)()
					fileClose(f)
				end
			end
		end
		if data.client and type(data.client) == 'table' then
			for i=1, #data.client do
				triggerClientEvent('onScriptStart', resourceRoot, name, data.client[i])
				clientLoadedScripts[name] = data.client[i]
			end
		end
		print(name..' has been started.')
	end
end

function Script.getMeta(name)
	local path = 'addons/'..string.lower(name)..'/meta.json'
	if fileExists(path) then
		local f = fileOpen(path)
		local meta = fromJSON(fileRead(f, fileGetSize(f)))
		fileClose(f)
		return meta
	end
end

function Script.get(name)
	return loadedResources[name]
end

addEventHandler('onPlayerJoin', root, function()
	for k, v in pairs(clientLoadedScripts) do
		triggerClientEvent(source, 'onScriptStart', resourceRoot, k, v)
	end
end)

addEventHandler('onResourceStart', resourceRoot, function()
	addCommandHandler('restartres', function(...) Script.restart(string.lower(arg[3])) end)
	addCommandHandler('startres', function(...) Script.start(string.lower(arg[3])) end)
	addCommandHandler('stopres', function(...) local res = Script.get(string.lower(arg[3])) if res then res:stop() end end)
end)