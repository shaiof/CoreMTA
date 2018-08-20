local accWin = guiCreateWindow(667, 317, 580, 447, "ST-RP Account Manager", false)
accWin.sizable = false
accWin.visible = false
local accList = guiCreateGridList(10, 68, 406, 369, false, accWin)
local addBtn = guiCreateButton(426, 27, 144, 55, "Create", false, accWin)
local delBtn = guiCreateButton(426, 92, 144, 55, "Delete", false, accWin)
local refBtn = guiCreateButton(426, 157, 144, 55, "Refresh", false, accWin)
local closeBtn = guiCreateButton(426, 382, 144, 55, "Close", false, accWin)
local accEdit = guiCreateEdit(10, 26, 406, 32, "", false, accWin)

local accounts = {}
local showing = false

addEventHandler('onClientResourceStart', resourceRoot, function()
	--toggleMgr()
	--requestAccounts()
end)

function toggleMgr()
	showing = not showing
	accWin.visible = showing
	showCursor(showing)
end

function requestAccounts()
	triggerServerEvent('requestAccounts', resourceRoot)
end

addEventHandler('onClientKey', root, function(key, down)
	if key == 'F10' and not down then
		toggleMgr()
	end
end)

addEventHandler('onClientGUIClick', guiRoot, function()
	if source == refBtn then
		requestAccounts()
	elseif source == closeBtn then
		toggleMgr()
	elseif source == delBtn then
		local row = accList:getSelectedItem()
		if row then
			local id = accList:getItemText(row, getColumnIdFromTitle(accList, 'id'))
			if id then
				triggerServerEvent('deleteAccount', resourceRoot, id)
			end
		end
	end
end)

addEventHandler('onClientGUIChanged', root, function()
	if source == accEdit then
		listAccounts(filterList(accounts, guiGetText(accEdit)))
	end
end)

addEvent('onGetAccounts', true)
addEventHandler('onGetAccounts', resourceRoot, function(accs)
	accounts = accs
	listAccounts(accs)
end)

function listAccounts(accs)
	local cols = {}
	local colCount = accList:getColumnCount()

	if colCount == 0 then
		for i=1, colCount do
			accList:removeColumn(1)
		end
	
		if #accs > 0 then
			for k,v in pairs(accs[1]) do
				cols[#cols+1] = accList:addColumn(k, 0.18)
			end
		end
	end

	accList:clear()

	for i=1, #accs do
		local row = accList:addRow()
		for k,v in pairs(accs[i]) do
			local val = type(v) == 'boolean' and '-' or tostring(v)
			accList:setItemText(row, getColumnIdFromTitle(accList, k), val, false, false)
		end
	end
end

function filterList(list, name)
	local filtered = {}
	for i=1, #list do
		if list[i].name:lower():find(name:lower()) then
			filtered[#filtered+1] = list[i]
		end
	end
	return filtered
end