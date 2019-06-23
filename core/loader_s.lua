if not isObjectInACLGroup('resource.'..getResourceName(getThisResource()), aclGetGroup('Admin')) then error(getResourceName(getThisResource())..' needs to be added to admin acl before it can run!', 3) end
addEvent('onResStart')
addEvent('onClientResStart', true)

Res = {}
local resources = {}
local clientResources = {}

function Res.new(name) -- create a parent table being the resource
	local self = setmetatable({}, {__index = Res})
	self.name = name -- resource name
	self.client = {} -- clientside scripts
	self.server = {} -- serverside scripts
	self.meta = {} -- list meta contents
	self.globals = {} -- this holds all the global variables/funcs of every script file in the resource
	self.elements = {}
	self.resourceRoot = Element('resource', name)
	self.globals['resourceRoot'] = self.resourceRoot
	setmetatable(self.globals, {__index = _G}) -- share mta and native functions with every script cause they all run in their own env
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
	-- get function that will run and return the script object
	local script, err = Script.create(self.name, fileName, buffer)
	if err then
		return false, err
	end	

	if not script then
		error('error loading file', fileName, 'in', self.name)
	end
	-- set the environment of the script function to sandbox everything that's executed by it
	setfenv(script, self.globals)
	-- execute the script function
	script = script()
	-- store the resource's globals into the script object
	script.globals = globals
	-- store the script object in the server table in the resource object
	self.server[fileName] = script

	return true, err
end

function Res:unload()
	for fileName, script in pairs(self.server) do
		script:unload()
	end
end

local function updateResourcesList(name)
	local path = 'addons/resources.json'
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
	res.meta = meta

	-- Script.loadClient(name, meta)
	Script.loadServer(name, meta.server)
	
	triggerEvent('onResStart', resourceRoot, res)
	triggerClientEvent('onResStart', resourceRoot, name, res.resourceRoot)

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

addEventHandler('onClientResStart', resourceRoot, function(name)
	local res = resources[name]
	Script.loadClient(name, res.meta, client)
end)

addEvent('onClientJoin', true)
addEventHandler('onClientJoin', resourceRoot, function()
	for name, res in pairs(resources) do
		triggerClientEvent(client, 'onResStart', resourceRoot, name, res.resourceRoot)
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

function Script.create(name, fileName, buffer)
	buffer = Script.parseBuffer(buffer)
	buffer = ('return function() local s = Script.new("%s", "%s"); s:replaceFuncs(); %s\nreturn s end'):format(name, fileName, buffer)

	local fnc, err = loadstring(buffer)
	
	local suc = pcall(fnc)
	if not suc then
		local _, lastChar, lineNum = err:find(':(%d+):')
		err = err:sub(lastChar+2)
		
		return nil, ('%s/%s:%s: %s'):format(name, fileName, lineNum, err)
	else
		return type(fnc) == 'function' and fnc(), err
	end
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

function Script.loadClient(name, meta, player)
	local target = player or root

	-- send files
	for i=1, #meta.files do
		local data = {
			resourceName = name,
			path = 'addons/'..name..'/'..meta.files[i]
		}

		if meta.files[i]:find('http') then
			data.url = meta.files[i]
		else
			local f = fileOpen(data.path)
			data.buf = f:read(f.size)
			f:close()
		end

		print(meta.files[i])

		triggerClientEvent(target, 'sendFile', resourceRoot, data)
	end

	-- send scripts
	for i=1, #meta.client do
		local data = {
			resourceName = name,
			path = 'addons/'..name..'/'..meta.client[i]
		}

		if meta.client[i]:find('http') then
			data.url = meta.client[i]
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

function Script.loadServer(name, files)
	local external = {}
	for i=1, #files do
		local fileName = files[i]
		if string.find(fileName, 'http') then
			external[#external+1] = fileName
		else
			local path = 'addons/'..name..'/'..fileName
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
end

addCommandHandler('startres', function(...) if not arg[3] then return end Res.start(arg[3]) end)
addCommandHandler('stopres', function(...) if not arg[3] then return end Res.stop(arg[3]) end)
addCommandHandler('restartres', function(...) if not arg[3] then return end Res.restart(arg[3]) end)
addCommandHandler('inspectres', function(...) if not arg[3] then return end Res.inspect(arg[3]) end)


-- function Script.loadFiles(name, files)
-- 	for i=1, #files do
-- 		local f = fileOpen('addons/'..name..'/'..files[i])
-- 		local buf = f:read(f.size)
-- 		for _, plr in pairs(getElementsByType('player')) do
-- 			plr:setData('fileBuffer', {
-- 				path = files[i],
-- 				buf = base64Encode(buf),
-- 				name = name,
-- 				done = fileIsEOF(f)
-- 			})
-- 		end
-- 		f:close()
-- 	end
-- end

-- function sendClientScripts()
--     if not source then source = getElementsByType('player') end
--     local clientScripts = {}
    
--     for name, res in pairs(resources) do
--         if not res.clientLoaded then
--             local external = {}
--             local localClient = {}
--             for i=1, #res.client do
--                 if string.find(res.client[i], 'http') then
--                     external[#external+1] = res.client[i]
--                 else
--                     local file = fileOpen('addons/'..name..'/'..res.client[i])

--                     localClient[#localClient+1] = file:read(file.size)
--                     file:close()
--                 end
--             end
--             table.insert(clientScripts, {
--                 name = name,
--                 external = external,
--                 localClient = localClient
--             })
--             res.clientLoaded = true
--         end
--     end
    
--     if type(source) == 'table' then
--         for _, plr in pairs(source) do
--             -- if isElement(plr) and getElementType(plr) == 'player' then
--                 plr:setData('clientScripts', clientScripts)
--             -- end
--         end
--     else
--         source:setData('clientScripts', clientScripts)
--     end
-- end
-- addEventHandler('onPlayerJoin', root, sendClientScripts)