addEvent('onClientResStart')

Res = {}
local resources = {}

function Res.new(name)
	local self = setmetatable({}, {__index = Res})
	self.name = name
	self.client = {}
	return self
end

function Res:loadClientScript(fileName, buffer)
	-- get function that will run and return the script object (see Script.create)
	local script = Script.create(self.name, fileName, buffer)
	-- throw error if for some reason the script isn't a function
	if not script then
		error('error loading file', fileName, 'in', self.name)
	end
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

		Res.downloadScripts(urls, function(completed)
			for i=1, #completed do
				local file = completed[i]
				local parts = split(file.url, '/')
				local fileName = parts[#parts]

				if file.err > 0 then
					print(i, 'error downloading file:', fileName, file.url)
				else
					print(i, 'downloaded file:', fileName, file.url)
					res:loadClientScript(fileName, file.data)
				end
			end
			triggerEvent('onClientResStart', resourceRoot, res)
		end)
	end

	--setTimer(function() triggerServerEvent('onClientReady', resourceRoot, name) end, 500, 1)
end
addEvent('onResStart', true)
addEventHandler('onResStart', resourceRoot, Res.start)

function Res.downloadScripts(urls, callback)
	local progress = {}
    local completed = {}

    for i=1, #urls do
		local url = urls[i]		
        Script.download(url, function(data, err)
            progress[i] = {url=url, data=data, filename=filename, err=err}

            for j=1, #urls do
                local prog = progress[j]
                if prog then
                    completed[j] = progress[j]
                end
            end

            if #completed == #urls then
                callback(completed)
            end
        end)
    end
end

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

function Script.new(name, fileName)
	local self = setmetatable({}, {__index = Script})
	self.name = name:lower()
	self.root = resources[name]
	self.fileName = fileName
	self.events = {}
	self.cmds = {}
	self.timers = {}
	self.globals = {}
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

function Script.create(name, fileName, buffer)
	local gt = {
		{'addCommandHandler', 's:cmd'},
		{'addEventHandler', 's:event'},
		{'setTimer', 's:timer'},
		{'onClientResourceStart', 'onClientResStart'}
	}

	for i=1, #gt do
		buffer = buffer:gsub(unpack(gt[i]))
	end

	buffer = ('return function() local s = Script.new("%s", "%s") %s\nreturn s end'):format(name, fileName, buffer)

	local fnc, err = loadstring(buffer)
	
	local suc = pcall(fnc)
	if not suc then
		local _, lastChar, lineNum = err:find(':(%d+):')
		err = err:sub(lastChar+2)
		error(('%s/%s:%s: %s'):format(name, fileName, lineNum, err), 0)
	else
		return type(fnc) == 'function' and fnc()
	end
end

addCommandHandler('inspectres', function(...) if not arg[2] then return end Res.inspect(arg[2]) end)
