if not isObjectInACLGroup('resource.'..getResourceName(getThisResource()), aclGetGroup('Admin')) then error(getResourceName(getThisResource())..' needs to be added to admin acl before it can run!', 3) end
addEvent('onResStart')
addEvent('onClientResStart', true)

Res = {}
local resources = {}
local clientResources = {}

function Res.new(name)
	local self = setmetatable({}, {__index = Res})
	self.name = name
	self.client = {}
	self.server = {}
	self.meta = {}
	self.globals = {}
	self.elements = {}
	self.files = {}
	self.resourceRoot = Element('resource', name)
	self.globals['resourceRoot'] = self.resourceRoot
	setmetatable(self.globals, {__index = _G})
	return self
end

function Res.downloadScripts(urls, callback)
	local progress = {}
    local completed = {}

    for i=1, #urls do
		local url = urls[i]		
        fetchRemote(url, function(data, err)
            progress[i] = {url=url, data=data, err=err}

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

function Res:loadExternal(files)
	Res.downloadScripts(files, function(completed)
		for i=1, #completed do
			local file = completed[i]
			local parts = split(file.url, '/')
			local fileName = parts[#parts]

			if file.err > 0 then
				print(i, 'error downloading file:', fileName, file.url)
			else
				local suc, err = self:loadServerScript(fileName, file.data) -- need to handle error here
			end
		end
	end)
end

function Res:loadServerScript(fileName, buffer)
	local script, err = Script.create(self.name, fileName, buffer)
	if err then
		return false, err
	end	

	if not script then
		error('error loading file', fileName, 'in', self.name)
	end

	setfenv(script, self.globals)
	script = script()
	script.globals = globals
	self.server[fileName] = script

	return true, err
end

function Res:unload()
	for fileName, script in pairs(self.server) do
		script:unload()
	end
end

local function updateResourcesList(name)
	local path = 'scripts/resources.json'
	local f = File(path)
	local list = fromJSON(f:read(f.size)) or {}

	if not list[name] then
		list[name] = {}
	end

	f:setPos(0)
	f:write(toJSON(list))
	f:close()
end

function Res.start(name)
	local oName = ''..name
	local name = name:lower()

	if resources[name] then
		return print("resource '"..name.."' already started")
	end

	local meta = Res.getMeta(oName)

	if not meta then
		return print("no meta found for resource '"..name.."'")
	end

	local res = Res.new(name)
	resources[name] = res
	res.meta = meta
	res.info = meta.info or {}
	
	-- sort out meta info
	res.info.name, res.info.author, res.info.version, res.info.description, res.info.type, res.info.gamemodes = res.info.name or name, res.info.author or 'CoreMTA', res.info.version or '0.1', res.info.description or '', res.info.type or '', res.info.gamemodes or ''

	local serverScripts, clientScripts, serverFiles, clientFiles = {}, {}, {}, {}
	for i, v in pairs(meta.server) do
		if v:find('.lua') then
			serverScripts[#serverScripts+1] = v
		else
			serverFiles[#serverFiles+1] = v
		end
	end
	
	for r, t in pairs(meta.client) do
		if t:find('.lua') then
			clientScripts[#clientScripts+1] = t
		else
			clientFiles[#clientFiles+1] = t
		end
	end
	
	for e=1, #serverFiles do
		resources[name].files[serverFiles[e]] = true
	end
	
	Script.loadServer(name, serverScripts, serverFiles)
	triggerClientEvent('onResStart', resourceRoot, name, res.resourceRoot, {clientScripts, clientFiles})

	updateResourcesList(name)
	
	print(name..' sucessfully started.')
end

function Res.stop(name)
	local name = name:lower()
	local res = resources[name]
	if not res then return end

	res:unload()

	res.resourceRoot:destroy()

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
	local json = 'scripts/'..name..'/meta.json'
	local xml = 'scripts/'..name..'/meta.xml'
	if fileExists(json) then
		local f = File(json)
		local meta = fromJSON(f:read(f.size))
		f:close()
		return meta
	elseif fileExists(xml) then
		local meta = {info = {}, server = {}, client = {}}
		local node = xmlLoadFile(xml)
		local info = xmlFindChild(node, 'info', 0)
		
		if info then
			for k, v in pairs(xmlNodeGetAttributes(info)) do
				meta.info[k] = v
			end
		end
		
		local others = xmlNodeGetChildren(node)
		for i, o in pairs(others) do
			if xmlNodeGetName(o) == 'script' or xmlNodeGetName(o) == 'file' then
				local attr = xmlNodeGetAttributes(o)
				if attr.type == 'client' then
					meta.client[#meta.client+1] = attr.src
				elseif attr.type == 'shared' then
					meta.client[#meta.client+1] = attr.src
					meta.server[#meta.server+1] = attr.src
				else
					meta.server[#meta.server+1] = attr.src
				end
			end
		end
		xmlUnloadFile(node)
		
		local f = File(json)
		f:write(toJSON(meta))
		f:close()
		fileDelete(xml)
		
		return meta
	end
	return false
end

function Res.inspect(name)
	local name = name:lower()
	local res = resources[name]
	if res then
		iprint('server', res)
		local f = fileCreate('temp.txt')
		f:write(toJSON(res.server))
		f:close()
	end
end

function Res.get(name)
	return resources[name]
end

function Res.getAll()
	return resources
end

function import(name)
    return resources[name].globals
end

addEventHandler('onClientResStart', resourceRoot, function(name, files)
	local res = resources[name]
	Script.loadClient(name, files, client)
end)

addEvent('onClientJoin', true)
addEventHandler('onClientJoin', resourceRoot, function()
	for name, res in pairs(resources) do
		triggerClientEvent(client, 'onResStart', resourceRoot, name, res.resourceRoot, {res.client, res.clientFiles})
	end
end)

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

function Script.create(resName, fileName, buffer)
	for b, c in pairs(resources[resName].files) do
		if c then
			buffer = buffer:gsub(b, 'scripts/'..resName..'/'..b)
		end
	end
	buffer = Script.parseBuffer(buffer)
	local testBuffer = ''..buffer
	buffer = ('return function() local s = Script.new("%s", "%s"); s:replaceFuncs();\n%s\nreturn s end'):format(resName, fileName, buffer)

	local fnc, err2 = loadstring(testBuffer)
	local fnc2, err3 = loadstring(buffer)
	
	local suc, err = pcall(fnc)
	if not suc then
		local _, lastChar, lineNum = err:find(':(%d+):')
		err = err:sub(lastChar+2)
		
		return nil, ('%s/%s:%s: %s'):format(resName, fileName, lineNum, err)
	else
		return type(fnc2) == 'function' and fnc2(), err
	end
end

function Script.get(resName, fileName)
	local script = resources[resName].server[fileName]
	return script
end

function Script.parseBuffer(buffer)
	local gt = {
		{'addCommandHandler', 's:cmd'},
		{'addEventHandler', 's:event'},
		{'setTimer', 's:timer'},
		{'Timer', 's:timer'},
		{'onResourceStart', 'onResStart'}
	}
	
	for i=1, #gt do
		buffer = buffer:gsub(unpack(gt[i]))
	end

	return buffer
end

function Script.loadClient(name, files, player)
	local target = player or root

	-- send files
	for k=1, #files[2] do
		local data = {
			resourceName = name,
			path = 'scripts/'..name..'/'..files[2][k]
		}

		if files[2][k]:find('http') then
			data.url = files[2][k]
		else
			local f = fileOpen(data.path)
			data.buf = f:read(f.size)
			f:close()
		end

		triggerClientEvent(target, 'sendFile', resourceRoot, data)
	end

	-- send scripts
	for i=1, #files[1] do
		local data = {
			resourceName = name,
			path = 'scripts/'..name..'/'..files[1][i]
		}
		
		if files[1][i]:find('http') then
			data.url = files[1][i]
		else
			local f = fileExists(data.path) and fileOpen(data.path)
			if f then
				data.buf = f:read(f.size)
				f:close()
			end
		end

		triggerClientEvent(target, 'sendScript', resourceRoot, data)
	end
end

function Script.loadServer(name, scripts, files)
	local external = {}
	for i=1, #scripts do
		local fileName = scripts[i]
		if string.find(fileName, 'http') then
			external[#external+1] = fileName
		else
			local path = 'scripts/'..name..'/'..fileName
			if File.exists(path) then
				local f = File(path)
				local b = f:read(f.size)
				local suc, err = resources[name]:loadServerScript(fileName, b)
				f:close()
				if not suc then
					error(err, 0)
				end
			end
		end
	end
	resources[name]:loadExternal(external)
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

	setmetatable(self, nil)

	--@TODO: elements are not being removed with clearTable? (for now it's fine cause they're parented to the resourceRoot and the resourceRoot is destroyed)
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

function Script:replaceFuncs()
	local elemFuncs = {'Ped', 'createPed', 'Vehicle', 'createVehicle', 'Object', 'createObject', 'Marker', 'createMarker', 'Sound', 'playSound', 'playSound3D', 'Pickup', 'createPickup', 'createColCircle', 'ColShape.Circle', 'createColCuboid', 'ColShape.Cuboid', 'createColPolygon', 'ColShape.Polygon', 'createColRectangle', 'ColShape.Rectangle', 'createColSphere', 'ColShape.Sphere', 'createColTube', 'ColShape.Tube', 'createBlip', 'Blip', 'createBlipAttachedTo', 'Blip.createAttachedTo', 'createRadarArea', 'RadarArea', 'Sound', 'Sound3D', 'playSFX', 'playSFX3D', 'createProjectile', 'Projectile', 'createTeam', 'Team.create', 'guiCreateFont', 'GuiFont', 'guiCreateBrowser', 'GuiBrowser', 'guiCreateButton', 'GuiButton', 'guiCreateCheckBox', 'GuiCheckBox', 'guiCreateComboBox', 'GuiComboBox', 'guiCreateEdit', 'GuiEdit', 'guiCreateGridList', 'GuiGridList', 'guiCreateMemo', 'GuiMemo', 'guiCreateProgressBar', 'GuiProgressBar', 'guiCreateRadioButton', 'GuiRadioButton', 'guiCreateScrollBar', 'GuiScrollBar', 'guiCreateScrollPane', 'GuiScrollPane', 'guiCreateStaticImage', 'GuiStaticImage', 'guiCreateTabPanel', 'GuiTabPanel', 'guiCreateTab', 'GuiTab', 'guiCreateLabel', 'GuiLabel', 'guiCreateWindow', 'GuiWindow', 'dxCreateTexture', 'DxTexture', 'dxCreateRenderTarget', 'DxRenderTarget', 'dxCreateScreenSource', 'DxScreenSource', 'dxCreateShader', 'DxShader', 'dxCreateFont', 'DxFont', 'createWeapon', 'Weapon', 'createEffect', 'Effect', 'Browser', 'createBrowser', 'createLight', 'Light', 'createSearchLight', 'SearchLight', 'createWater', 'Water'}
	for i=1, #elemFuncs do
		local origFunc = self.root.globals[elemFuncs[i]]
		self.root.globals[elemFuncs[i]] = function(...)
			local elem = origFunc(...)
			elem:setParent(self.root.resourceRoot)
			table.insert(self.root.elements, elem)
			return elem
		end
	end
	local origFunc = self.root.globals['require']
	self.root.globals['require'] = function(...)
		return unpack({origFunc(self, ...)})
	end
end

addCommandHandler('startres', function(...) if not arg[3] then return end Res.start(arg[3]) end)
addCommandHandler('stopres', function(...) if not arg[3] then return end Res.stop(arg[3]) end)
addCommandHandler('restartres', function(...) if not arg[3] then return end Res.restart(arg[3]) end)
addCommandHandler('inspectres', function(...) if not arg[3] then return end Res.inspect(arg[3]) end)

-- autostart
addEventHandler('onResourceStart', resourceRoot, function()
	local f = fileOpen('autostart.json')
	local buffer = fromJSON(f:read(f.size))
	f:close()
	for i=1, #buffer.resources do
		Res.start(buffer.resources[i])
	end
end)