Sql = {}
Sql.connections = {}
Sql.__index = Sql

function Sql.createConnection(info)
	check('t', info)
	assert(info.host and info.user and info.password and info.dbname,'Incorrect Table Format and or Missing Information')
	local self = setmetatable({}, Sql)
	self.info = info
	self:connect()
	return self
end

function Sql.getConnection(host, dbname)
	check('s', host, dbname)
	for i=1, #Sql.connections do
		local connection = Sql.connections[i]
		if connection.host == host and connection.dbname == dbname then
			return connection
		end
	end
end

function Sql:connect()
	local info = self.info
	local options = ''
	for k, v in pairs(info) do
		if k ~= 'user' and k ~= 'password' then
			options = options..k..'='..v..';'
		end
	end
	self.connection = Connection('mysql', options, info.user, info.password)
	table.insert(Sql.connections, self)
end

function Sql:disconnect()
	self.connection:destroy()
	table.remove(Sql.connections, self)
end

function Sql:query(query, callback, ...)
	check('s', query)
	self.connection:query(function(q)
		local result = q:poll(0)
		if callback and type(callback) == 'function' then
			callback(result)
		end
	end, query, ...)
end

function Sql:insert(tbl, set, callback)
	check('st', tbl, set)
	local str = self.connection:prepareString('INSERT INTO ?? SET ', tbl)
	for k, v in pairs(set) do
		str = str..self.connection:prepareString('??=?, ', k, v)
	end
	self:query(str:sub(1,-3), callback)
end

function Sql:delete(tbl, where, callback)
	check('st', tbl, where)
	local str = self.connection:prepareString('DELETE FROM ??', tbl)
	local w = ' WHERE'
	for k, v in pairs(where) do
		w = w..self.connection:prepareString(' ??=? AND', k, v)
	end
	self:query(str..w:sub(1,-5), callback)
end

function Sql:createTable(tbl, columns)
	check('st', tbl, columns)
	local str = self.connection:prepareString('CREATE TABLE ?? (', tbl)
	for k, v in pairs(columns) do
		str = str..self.connection:prepareString('?? ??,', k, v)
	end
	str = str:sub(1,-2)..')'
	self:query(str, callback)
end

function Sql:dropTable(tbl, callback)
	check('s', tbl)
	self:query('DROP TABLE IF EXISTS ??', callback, tbl)
end

function Sql:update(tbl, update, where, callback)
	check('st', tbl, update)
	local str = self.connection:prepareString('UPDATE ?? SET ', tbl)
	for k, v in pairs(update) do
		str = str..self.connection:prepareString('??=?, ', k, v)
	end
	local w = ''
	if where then
		check('t', where)
		w = ' WHERE '
		for k, v in pairs(where) do
			w = w..self.connection:prepareString('??=? AND ', k, v)
		end
	end
	self:query(str:sub(1,-3)..w:sub(1,-6), callback)
end

function Sql:addColumn(tbl, cols, callback)
	check('st', tbl, cols)
	local str = self.connection:prepareString('ALTER TABLE ?? ADD (', tbl)
	for k,v in pairs(cols) do
		str = str..self.connection:prepareString('?? ??,', k, v)
	end
	self:query(str:sub(1, -2)..')', callback)
end

function Sql:select(tbl, selection, where, callback)
	check('s', tbl)
	if not selection then return end
	
	if type(selection) == 'function' then
		return self:query('SELECT * FROM ??', selection, tbl)
	end
	
	if type(selection) == 'table' then
		if #selection == 0 then
			assert(where and type(where) == 'function', 'Missing Callback At Arg #3')
			local str = self.connection:prepareString('SELECT * FROM ?? WHERE ', tbl)
			local n = 0
			for k, v in pairs(selection) do
				str = str..self.connection:prepareString('??=? AND ', k, v)
				n = n + 1
			end
			str = n > 0 and str:sub(1,-6) or str:sub(1,-8)
			return self:query(str, where)
		end
		
		str = self.connection:prepareString('SELECT ??', selection[1])
		for i=2, #selection do
			str = str..self.connection:prepareString(',??', selection[i])
		end
		str = str..self.connection:prepareString(' FROM ??', tbl)
		
		if where then 
			if type(where) == 'function' then
				return self:query(str, where)
			end
			local w = ' WHERE '
			for k, v in pairs(where) do
				w = w..self.connection:prepareString('??=? AND ', k, v)
			end
			str = str..w:sub(1,-6)
		end
	
		self:query(str, callback)
	end
end

--[[
connection:createTable('users',{id='INT AUTO_INCREMENT PRIMARY KEY', serial='varchar(255) NOT NULL UNIQUE', name='varchar(255)', age='INT'})
connection:insert('users', {name='jill', age=17, serial='1234'})
connection:update('users', {age=12}, {age=5})
connection:delete('players',{name='dude'})
connection:select('accounts', {serial=plr.serial}, function(result) iprint(result) end)
connection:addColumn('accounts', {rot='text'})
]]