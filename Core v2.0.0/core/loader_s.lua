Res = {}
local resources = {}

function Res.new(name)
	local self = setmetatable({}, {__index = Res})
	self.name = name
	self.server = {}
	self.client = {}
	return self
end

function Res:loadServerScript(fileName, buffer)
	self.server[fileName] = Script.create(self.name, buffer)()
end

function Res:loadClientScript(url)
	table.insert(self.client, url)
end

function Res:unload()
	for fileName, script in pairs(self.server) do
		script:unload()
	end
end

function Res.start(name)
	local name = name:lower()

	if resources[name] then
		return print("resource '"..name.."' already started")
	end

	local meta = Res.getMeta(name)

	if not meta then
		return print("no meta found for resource '"..name.."'")
	end

	local res = Res.new(name)
	resources[name] = res

	Script.loadClient(name, meta.client)
	Script.loadServer(name, meta.server)
	--Res.loadShared(name, meta.shared)

	triggerClientEvent('onResStart', resourceRoot, name, res.client)
end

function Res.stop(name)
	local name = name:lower()
	local res = resources[name]
	if not res then return end

	res:unload()

	if #res.client > 0 then
		triggerClientEvent('onResStop', resourceRoot, name)
	end

	resources[name] = nil
	for i=1, 2 do collectgarbage() end
	print(name..' has been stopped.')
end

function Res.restart(name)
	local name = name:lower()
	if resources[name] then
		Res.stop(name)
		Res.start(name)
	end
end

function Res.getMeta(name)
	local path = 'addons/'..name..'/meta.json'
	if fileExists(path) then
		local f = File(path)
		local meta = fromJSON(f:read(f.size))
		f:close()
		return meta
	end
	return false
end

function Res.inspect(name)
	local name = name:lower()
	local res = resources[name]
	if res then
		iprint('server', res)
	end
end

function Res.get(name)
	return name and resources[name]
end


Script = {}

function Script.new(name)
	local self = setmetatable({}, {__index = Script})
	self.name = name
	self.events = {}
	self.cmds = {}
	self.timers = {}
	return self
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

function Script.create(name, buffer)
	local str = buffer:gsub('addCommandHandler', 's:cmd')
	str = str:gsub('addEventHandler', 's:event')
	str = str:gsub('setTimer', 's:timer')
	str = ('return function() local s = Script.new("%s") %s return s end'):format(name, str)
	return loadstring(str)()
end

function Script.loadServer(name, files)
	for i=1, #files do
		local fileName = files[i]
		local path = 'addons/'..name..'/'..fileName
		if File.exists(path) then
			local f = File(path)
			local b = f:read(f.size)
			resources[name]:loadServerScript(fileName, b)
			f:close()
		end
	end
end

function Script.loadClient(name, urls)
	for i=1, #urls do
		resources[name]:loadClientScript(urls[i])
	end
end

function Script.loadShared(name, files)
	Script.loadClient(name, files)
	Script.loadServer(name, files)
end

addEvent('onClientReady', true)

addEventHandler('onPlayerJoin', root, function()
	-- needs to be improved. should only do 1 trigger which passes all url at once.
	for name, res in pairs(resources) do
		triggerClientEvent(source, 'onResStart', resourceRoot, name, res.client)
	end
end)

addCommandHandler('startres', function(...) if not arg[3] then return end Res.start(arg[3]) end)
addCommandHandler('stopres', function(...) if not arg[3] then return end Res.stop(arg[3]) end)
addCommandHandler('restartres', function(...) if not arg[3] then return end Res.restart(arg[3]) end)
addCommandHandler('inspectres', function(...) if not arg[3] then return end Res.inspect(arg[3]) end)
