executeSQLQuery('CREATE TABLE IF NOT EXISTS Table_System (ID, myTable)')
function setTableToSql(id, theTable)
	local results = executeSQLQuery('SELECT myTable FROM `Table_System` WHERE ID=?', id) 
	if (type(results) == 'table' and #results == 0 or not results) then 
		executeSQLQuery('INSERT INTO `Table_System` ( ID, myTable ) VALUES(?, ?)', id, toJSON(theTable))
	else 
		executeSQLQuery('UPDATE `Table_System` SET myTable =? WHERE ID =?', toJSON(theTable), id) 
	end  
end

function getTableFromSql(id)
	local aRow = executeSQLQuery('SELECT myTable FROM `Table_System` WHERE ID=?', id)
	if (type(aRow) == 'table' and #aRow == 0) or not aRow then return {''} end
	return fromJSON(aRow[1]['myTable'])
end

function aclGroupClone(clonedGroup, groupName, aclsClone, objectsClone)
	if type(clonedGroup) ~= 'string' then 
		error('Bad argument @ aclGroupClone [Expected string at argument 1, got '..tostring(clonedGroup)..']')
		return false 
	end
	if aclsClone == true or aclsClone == false then 
		if objectsClone == true or objectsClone == false then 
			local cloned = aclGetGroup(clonedGroup)
			if cloned == false or not cloned then
				error('Bad argument @ aclGroupClone [Expected acl-group at argument 1, got string '..tostring(clonedGroup)..']')
				return false
			end
			local newGroup = aclCreateGroup(groupName)
			if newGroup == false or not newGroup then
				error('Bad argument @ aclGroupClone [Expected acl-group at argument 2, got string '..tostring(groupName)..']')
				return false
			end
			if aclsClone == true then
				for index, value in ipairs(aclGroupListACL(cloned)) do
					aclGroupAddACL(newGroup, value)
				end
			end
			if objectsClone == true then
				for index, value in ipairs(aclGroupListObjects(cloned)) do
					aclGroupAddObject(newGroup, value)
				end
			end
			error('aclGroupClone [The group '..clonedGroup..' has been cloned successfully to '..groupName..' .')
			return true
		else
			error('Bad argument @ aclGroupClone [Expected boolean at argument 4, got '..tostring(objectsClone)..']')
			return false
		end
	else
		error('Bad argument @ aclGroupClone [Expected boolean at argument 3, got '..tostring(aclsClone)..']')
		return false
	end
end

function getPlayerAcls(thePlayer)
	local acls = {}
	local account = getPlayerAccount(thePlayer)
	if account and not isGuestAccount(account) then
		local accountName = getAccountName(account)
		for i, group in ipairs(aclGroupList()) do
			if (isObjectInACLGroup('user.'..accountName, group)) then
				local groupName = aclGroupGetName(group)
				table.insert(acls, groupName)
			end
		end
	end
	return acls
end

function isPlayerInACL(player, acl)
	local accountName = getAccountName(getPlayerAccount(player))
	if accountName ~= 'guest' and type(aclGetGroup(acl)) == 'userdata' then
		return isObjectInACLGroup('user.'..accountName, aclGetGroup(acl))
	end
	return false
end

-- isPlayerStaff

function renameAclGroup(old, new)
	if old and new and type(old) == 'string' and type(new) == 'string' then
		local oldACLGroup = aclGetGroup(old)
		local newACLGroup = aclGetGroup(new)
		
		if oldACLGroup and not newACLGroup then
			local newACLGroup = aclCreateGroup(new)

			for _, acl in pairs(aclGroupListACL(oldACLGroup)) do
				aclGroupAddACL(newACLGroup, acl)
			end

			for _, object in pairs(aclGroupListObjects(oldACLGroup)) do
				aclGroupAddObject(newACLGroup, object)
			end

			aclDestroyGroup(oldACLGroup)
			aclSave()
			aclReload()

			return newACLGroup
		end
	end
	return false
end

function removeAccountData(playerAccount, data)
	if playerAccount ~= '' and data ~= '' then
		if getAccount(playerAccount) then
			local dataName = getAccountData(playerAccount, data)
			if dataName ~= nil or dataName ~= '' then
				return setAccountData(playerAccount, data, nil)
			end
		end
	end
	return false
end

function getPlayerFromAccountName(name) 
	local acc = getAccount(name)
	if name and acc and not isGuestAccount(acc) then
		return getAccountPlayer(acc)
	end
	return false
end

function isElementWithinAColShape(element)
	if element or isElement(element)then
		for _, colshape in ipairs(getElementsByType('colshape')) do
			if isElementWithinColShape(element, colshape) then
				return colshape
			end
		end
	end
	return false
end

