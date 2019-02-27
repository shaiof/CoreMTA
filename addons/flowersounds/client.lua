local sx,sy = guiGetScreenSize()
local sw,sh = 1366,768
local sound = {}
local draw = {}
local volume = 1
local publicSound
local publicSoundOwner
local publicSoundName
local publicSoundChannel

-- Useful Functions --
function url_decode(str)
	str = string.gsub(str,'+',' ')
	str = string.gsub(str,'%%(%x%x)',function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub(str,'\r\n','\n')
	return str
end

function addText(player,text,static,song)
	removeText(player)
	local temp = {player=player,text=text,static=static,song=song}
	table.insert(draw,temp)
end

function removeText(player)
	for k,v in ipairs(draw) do
		if v.player == player then
			table.remove(draw,k)
			break
		end
	end
end

function convertTime(seconds)
	local seconds = tonumber(seconds)
	if seconds > 0 then
		hours = string.format('%02.f',math.floor(seconds/3600))
		mins = string.format('%02.f',math.floor(seconds/60-(hours*60)))
		secs = string.format('%02.f',math.floor(seconds-hours*3600-mins*60))
		if tonumber(hours) < 1 then hours = '' end
		return hours..mins..':'..secs
	end
	return '00:00'
end
----------------------
local events = {'playSound','play','tRemove','stopAllSongs','stopPlayerSongs'}
for i=1,#events do
	addEvent(events[i],true)
end

addCommandHandler('l',function()
	outputChatBox(convertTime(getSoundPosition(publicSound)*1000))
end)

addEventHandler('playSound',root,function(player,veh,x,y,z,theSound,songName,static)
	if string.find(tostring(theSound),'http://') == nil and string.find(tostring(theSound),'https://') == nil then
		theSound = string.format('http://%s',tostring(theSound))
	end
	local newSound = url_decode(theSound)
	if veh then
		local vehicle = getPedOccupiedVehicle(player)
		local dimension = getElementDimension(vehicle)
		if sound[player] then
			if isElement(sound[player]) then
				destroyElement(sound[player])
				removeText(player)
			end
		end
		sound[player] = playSound3D(theSound,x,y,z,true)
		setElementDimension(sound[player],dimension)
		setSoundMinDistance(sound[player],1)
		setSoundMaxDistance(sound[player],50)
		attachElements(sound[player],vehicle,0,0,0)
		addText(player,songName,vehicle,sound[player])
		addEventHandler('onClientElementDestroy',vehicle,function()
			if isElement(sound[player]) then
				destroyElement(sound[player])
				removeText(player)
			end
		end)
		return
	elseif not veh then
		if static == true then
			local dimension = getElementDimension(player)
			if isElement(sound[player]) then
				destroyElement(sound[player])
				removeText(player)
			end
			sound[player] = playSound3D(theSound,x,y,z,true)
			setElementDimension(sound[player],dimension)
			setSoundMinDistance(sound[player],1)
			setSoundMaxDistance(sound[player],50)
			addText(player,songName,sound[player],sound[player])
		else
			local dimension = getElementDimension(player)
			if isElement(sound[player]) then
				destroyElement(sound[player])
				removeText(player)
			end
			sound[player] = playSound3D(theSound,x,y,z,true)
			setElementDimension(sound[player],dimension)
			setSoundMinDistance(sound[player],1)
			setSoundMaxDistance(sound[player],50)
			attachElements(sound[player],player,0,0,0)
			addText(player,songName,player,sound[player])
		end
	end
end)

addEventHandler('play',root,function(player,realSound,songName,author)
	if string.find(tostring(realSound),'http://') == nil and string.find(tostring(realSound),'https://') == nil then
		realSound = string.format('http://%s',tostring(realSound))
	end
	if publicSound then
		destroyElement(publicSound)
	end
	publicSound = playSound(realSound,true)
	publicSoundOwner = player
	publicSoundName = songName
	publicSoundChannel = author or 'None'
	if volume < 1 then
		setSoundVolume(publicSound,volume)
	end
end)

addEventHandler('onClientRender',root,function()
	if draw then
		for k,v in ipairs(draw) do
			if isElement(v.static) then
				local x,y,z
				if v.static then
					x,y,z = getElementPosition(v.static)
					z = z+0.8
				end
				local cx,cy,cz = getCameraMatrix()
				local distance = getDistanceBetweenPoints3D(cx,cy,cz,x,y,z)
				local posx,posy = getScreenFromWorldPosition(x,y,z+0.020*distance+0.10)
				local ignore = getPedOccupiedVehicle(v.player) or v.player
				if posx and distance <= 45 and (isLineOfSightClear(cx,cy,cz,x,y,z,true,true,false,true,false,true,false,ignore)) and (isLineOfSightClear(cx,cy,cz,x,y,z,true,true,false,true,false,true,false,ignore)) then
					local p = getSoundPosition(v.song) or 0
					local l = getSoundLength(v.song) or 0
					if p and l then
						local width = dxGetTextWidth(v.text..' ['..convertTime(p)..'/'..convertTime(l)..']',1,'default')
						dxDrawText(v.text..' ['..convertTime(p)..'/'..convertTime(l)..']',posx-(0.5*width),posy,posx-(0.5*width),posy,tocolor(0,255,255,255),1,'default','left','top',false,false,false)
					end
				end
			end
		end
	end
	if isElement(publicSound) then
		dxDrawRectangle(354/sw*sx,0/sh*sy,755/sw*sx,50/sh*sy,tocolor(0,0,0,100),false)
		local p = getSoundPosition(publicSound) or 0
		local l = getSoundLength(publicSound) or 0
		if p and l then
			dxDrawText(publicSoundName..' ['..convertTime(p)..'/'..convertTime(l)..']\n Author: '..publicSoundChannel..' | Added By: '..getPlayerName(publicSoundOwner)..'\n Volume: '..math.floor(getSoundVolume(publicSound)*100)..'%',354/sw*sx,0/sh*sy,1109/sw*sx,50/sh*sy,tocolor(0,255,255,255),1.00,'default','center','center',false,false,false,false,false)
		end
	end
end)

addEventHandler('tRemove',root,removeText,player)

addEventHandler('stopAllSongs',root,function(player)
	for k,v in ipairs(getElementsByType('sound')) do
		destroyElement(v)
	end
	draw = {}
end)

addEventHandler('stopPlayerSongs',root,function(player)
	if publicSoundOwner == getPlayerName(player) then
		if isElement(publicSound) then
			destroyElement(publicSound)
		end
	end
	if isElement(sound[player]) then
		destroyElement(sound[player])
		removeText(player)
	end
end)

addCommandHandler('vol',function(cmd,lVolu)
	if tonumber(lVolu) then
		if tonumber(lVolu) > 100 or tonumber(lVolu) < 0 then
			outputChatBox('Please enter a number from 0-100',255,0,0)
		end
		local volume = (tonumber(lVolu)/100)
		setSoundVolume(publicSound,volume)
	end
end)