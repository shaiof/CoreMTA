Script = {}
Script.__index = Script
local loadedResources = {}

local links = {'discord.com', 'discordapp.com'}
addEventHandler('onClientPlayerJoin', root, function()
	if source == localPlayer then
		for i=1, #links do
			checkDomain(links[i])
		end
	end
end)

function Script.new(name)
	check('s', string.lower(name))
	local self = setmetatable({}, Script)
	self.name = string.lower(name)
	self.events = {}
	self.cmds = {}
	self.timers = {}
	return self
end

function Script.start(name, link)
	fetchRemote(link, function(data,err)
		if data then
			print('1',data,err)
			addEventHandler('onClientReady', root, function()
				print('2',data)
				local script = loadstring('return function() local s = Script.new("'..string.lower(name)..'") '..convertBuffer(data)..' return s end')()
				loadedResources[string.lower(name)] = script()
			end)
		end
	end)
end
addEvent('onScriptStart', true)	
addEventHandler('onScriptStart', resourceRoot, Script.start)

function Script.stop(name)
	loadedResources[string.lower(name)]:unload()
	loadedResources[string.lower(name)] = nil
	for i=1, 2 do collectgarbage() end
end
addEvent('onScriptStop', true)
addEventHandler('onScriptStop', resourceRoot, Script.stop)

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