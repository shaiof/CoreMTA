function deleteAccount(id)
	Acc.delete(id, requestAccounts)
end
addEvent('deleteAccount', true)
addEventHandler('deleteAccount', resourceRoot, deleteAccount)

function requestAccounts()
	Acc.getAll(function(accounts)
		triggerClientEvent('onGetAccounts', resourceRoot, accounts)
	end)
end
addEvent('requestAccounts', true)
addEventHandler('requestAccounts', resourceRoot, requestAccounts)
