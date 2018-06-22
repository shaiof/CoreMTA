-- Notes:
--
-- should we put a users table here and insert straight from within the user framework?
-- should we use the user framework to cache data fetched from the db or should we implement caching into the sql framework?
-- should we build a small cache framework around the sql instead of modifying the sql framework?
-- do we need this user framework at all if caching is done through the sql framework?
-- an sql cache would also help with fetching data from the database other than user data.

User = {}

function User.new(client)
	local self = setmetatable({}, {__index = User})
	self.client = client
	return self
end

function User:login(ready)
	Acc.getBySerial(self.client.serial, function(results)
		if #results > 0 then -- Check if the player has any accounts
			-- Login player / Load data from db
			for k,v in pairs(results[1]) do
				self[k] = v
			end
			
			-- Check if player changed his name and update it in the db
			if player.name ~= results[1].name then
				self.save('name', player.name)
			end

			-- Call the ready function when everything is done
			ready(self)
		else -- Create an account for player
			connection:insert('accounts', {serial=player.serial, name=player.name}, function()
				-- Call the ready function when the account is created
				ready(self)
			end)
		end
	end)
end

function User:save(key, value)
	if type(key) == 'table' then
		for k, v in pairs(key) do
			self[k] = v
		end
		connection:update('accounts', key, {serial=self.serial, id=self.id})
	elseif type(key) == 'string' and value then
		connection:update('accounts', {[key] = value}, {serial=self.serial, id=self.id})
	end
end

function User:getAccounts(ready)
	Acc.getBySerial(self.serial, ready)
end

--[[

local clientCache = {}
local Client = {}

function Client.login(client, ready)
	Client.getAccounts(client, function(accounts)
		if #accounts > 0 then -- Check if the player has any accounts
			-- Login player / Load data from db
			for k,v in pairs(accounts[1]) do
				self[k] = v
			end
			
			-- Check if player changed his name and update it in the db
			if player.name ~= accounts[1].name then
				self:save('name', player.name)
			end

			-- Call the ready function when everything is done
			ready(self)
		else -- Create an account for player
			Client.addAccount(client, ready)
		end
	end)
end
addEventHandler('client.login', root, Client.login)

function Client.getAccounts(client, ready)
	connection:select('accounts', {serial=client.serial}, ready)
end

function Client.addAccount(client, ready)
	connection:insert('accounts', {serial=client.serial, name=client.name}, ready)
end

Plr = {}
Plr.__index = Plr

function Plr.new(player, onReady)
	check('uf', player, onReady)

	local self = setmetatable({}, Plr)
	self.player = player

	self:getAccounts(function(results)
		if #results > 0 then -- Check if the player has any accounts
			-- Login player / Load data from db
			for k,v in pairs(results[1]) do
				self[k] = v
			end
			
			-- Check if player changed his name and update it in the db
			if player.name ~= results[1].name then
				self:save('name', player.name)
			end

			-- Call the ready function when everything is done
			onReady(self)
		else -- Create an account for player
			connection:insert('accounts', {serial=player.serial, name=player.name}, function()
				-- Call the ready function when the account is created
				onReady(self)
			end)
		end
	end)

	return self
end

function Plr:getAccounts(callback)
	connection:select('accounts', {serial=self.serial}, callback)
end

function Plr:get(k)
	return self[k]
end

function Plr:save(key, value)
	assert(key and type(key) == 'table' or type(key) == 'string', 'save: arg #1 not a key or table')
	
	if type(key) == 'table' then
		for k, v in pairs(key) do
			self[k] = v
		end
		connection:update('accounts', key, {serial=self.serial, id=self.id})
	elseif type(key) == 'string' and value then
		connection:update('accounts', {[key] = value}, {serial=self.serial, id=self.id})
	end
end

function posToJSON(plr)
	local x,y,z = getElementPosition(plr)
	local rx,ry,rz = getElementRotation(plr)
	return toJSON({x,y,z,rx,ry,rz})
end



local players = {}

addEventHandler('onResourceStart', resourceRoot, function()
	local plrs = getElementsByType('player')

	for i=1, #plrs do
		Plr.new(plrs[i], function(plr)
			players[plr.serial] = plr
			triggerClientEvent('onReady', resourceRoot, plr)
		end)
	end
end)

addEventHandler('onPlayerJoin', root, function()
	Plr.new(source, function(data)
		players[data.serial] = data
		triggerClientEvent('onReady', resourceRoot, data)
	end)
end)


function savePlayerData(player)
	players[player.serial]:save({
		pos = posToJSON(player),
		dim = player.dimension,
		intId = player.interior,
		skin = player.model
	})
	players[player.serial] = nil
end

addEventHandler('onPlayerQuit', root, function()
	savePlayerData(source)
end)

addEventHandler('onResourceStop', resourceRoot, function()
	for _, plr in ipairs(getElementsByType('player')) do
		savePlayerData(plr)
	end
end)


addEventHandler('onPlayerSpawn', root, function()
	local playerData = players[source.serial]
	local plr = playerData:get('player')
	local x,y,z,rx,ry,rz = unpack(fromJSON(playerData:get('pos')))

	setElementPosition(plr, x,y,z)
	setTimer(function()
		setElementRotation(plr, rx,ry,rz)
		setElementModel(plr, playerData:get('skin'))
	end, 500, 1)
end)

addEventHandler('onPlayerChangeNick', root, function(old, new)
	players[source.serial]:save({name=new})
end)
]]