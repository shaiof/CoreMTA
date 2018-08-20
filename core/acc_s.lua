Acc = {}

function Acc.create(client, ready)
	connection:insert('users', {serial=client.serial, name=client.name}, ready)
end

function Acc.delete(id, ready)
	connection:delete('users', {id=id}, ready)
end

function Acc.getAll(ready)
	connection:select('users', ready)
end

function Acc.getBySerial(serial, ready)
	connection:select('users', {serial=serial}, ready)
end