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
	self.client[fileName] = Script.create(self.name, buffer)()
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
	return loadstring(str)()
end


addCommandHandler('inspectres', function(...) if not arg[2] then return end Res.inspect(arg[2]) end)


addEvent('onClientReady')
function checkScripts()
	local server = getElementData(localPlayer, 'scripts')
	for i=1, #server do
		if not server[i] == clientResources[i] then
			return
		end
	end
	removeEventHandler('onClientRender', localPlayer, checkScripts)
	triggerServerEvent('onClientReady', localPlayer)
	triggerEvent('onClientReady', localPlayer)
end
addEventHandler('onClientRender', localPlayer, checkScripts)
