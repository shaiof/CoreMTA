local root = getRootElement()

function newCar(player,cmd,carName,value,value2)
	if getAccountData(getPlayerAccount(source),'jailed') == false or getAccountData(getPlayerAccount(source),'jailed') == nil then
	if tonumber(carName) then
		if isBanned(tonumber(carName)) == true then
			outputChatBox("This vehicle is not allowed!",player,255,0,0)
			return
		else
			spawnVehicle(player,tonumber(carName))
		end
	else
		if carName == "super" then
			if value == "gt" then
				spawnVehicle(player,506)
			end
		elseif carName == "blista" then
			if value == "compact" then
				spawnVehicle(player,496)
			end
		elseif carName == "news" then
			if value == "chopper" then
				spawnVehicle(player,488)
			elseif value == "van" then
				spawnVehicle(player,582)
			end
		elseif carName == "police" then
			if value == "maverick" then
				spawnVehicle(player,497)
			elseif value == "ls" then
				spawnVehicle(player,596)
			elseif value == "sf" then
				spawnVehicle(player,597)
			elseif value == "lv" then
				spawnVehicle(player,598)
			elseif value == "ranger" then
				spawnVehicle(player,599)
			end
		elseif carName == "mountain" then
			if value == "bike" then
				spawnVehicle(player,510)
			end
		elseif carName == "utility" then
			if value == "van" then
				spawnVehicle(player,552)
			end
		elseif carName == "fbi" then
			if value == "rancher" then
				spawnVehicle(player,490)
			elseif value == "truck" then
				spawnVehicle(player,528)
			end
		elseif carName == "combine" then
			if value == "harvester" then
				spawnVehicle(player,532)
			end
		elseif carName == "black" then
			if value == "boxville" then
				spawnVehicle(player,609)
			end
		elseif carName == "mr" then
			if value == "whoopee" then
				spawnVehicle(player,423)
			end
		elseif carName == "hotring" then
			if value == "racer" then
				if value2 == "2" then
					spawnVehicle(player,502)
				elseif value2 == "3" then
					spawnVehicle(player,503)
				elseif not value2 or value2 == "1" then
					spawnVehicle(player,494)
				end
			end
		elseif carName == "monster" then
			if value == "2" then
				spawnVehicle(player,556)
			elseif value == "3" then
				spawnVehicle(player,557)
			elseif not value or value == "1" then
				spawnVehicle(player,444)
			end
		elseif carName == "trailer" then
			if value == "2" then
				spawnVehicle(player,608)
			elseif value == "3" then
				spawnVehicle(player,435)
			elseif value == "4" then
				spawnVehicle(player,450)
			elseif value == "5" then
				spawnVehicle(player,591)
			elseif not value or value == "1" then
				spawnVehicle(player,611)
			end
		elseif carName == "baggage" then
			if value == "trailer" then
				if value2 == "2" then
					spawnVehicle(player,607)
				elseif not value2 or value2 == "1" then
					spawnVehicle(player,606)
				end
			end
		elseif carName == "farm" then
			if value == "trailer" then
				spawnVehicle(player,610)
			end
		elseif carName == "petrol" then
			if value == "trailer" then
				spawnVehicle(player,584)
			end
		elseif carName == "rc" then
			if value == "bandit" then
				spawnVehicle(player,441)
			elseif value == "baron" then
				spawnVehicle(player,464)
			elseif value == "cam" then
				spawnVehicle(player,594)
			elseif value == "goblin" then
				spawnVehicle(player,501)
			elseif value == "raider" then
				spawnVehicle(player,495)
			elseif value == "tiger" then
				spawnVehicle(player,564)
			elseif value == "van" then
				spawnVehicle(player,459)
			end
		elseif carName == "box" then
			if value == "freight" then
				spawnVehicle(player,590)
			end
		elseif carName == "brown" then
			if value == "streak" then
				if value2 == "carriage" then
					spawnVehicle(player,570)
				elseif not value2 then
					spawnVehicle(player,538)
				end
			end
		elseif carName == "flat" then
			if value == "freight" then
				spawnVehicle(player,569)
			end
		elseif carName == "bloodring" then
			if value == "banger" then
				spawnVehicle(player,504)
			end
		elseif carName == "bf" then
			if value == "injection" then
				spawnVehicle(player,424)
			end
		else
			local vehicleID = getVehicleModelFromName(carName)
			spawnVehicle(player,vehicleID)
		end
	end
	end
end
addCommandHandler("vi",newCar)

function isBanned(id)
	if id == 520 or id == 432 or id == 447 or id == 425 then
		return true
	else
		return false
	end
end

function spawnVehicle(player,ID)
	local account = getAccountName(getPlayerAccount(player))
	local currentVeh = getPedOccupiedVehicle(player)
	if currentVeh then
		local driver = getVehicleOccupant(currentVeh,0)
		if driver == player then
			if isBanned(ID) == false then
				local car = createVehicle(ID,0,0,0)
				local dim = getElementDimension(player)
				local int = getElementInterior(player)
				local x,y,z = getElementPosition(currentVeh)
				local rx,ry,rz = getElementRotation(currentVeh)
				local vx,vy,vz = getElementVelocity(currentVeh)
				setElementInterior(car,int)
				setElementDimension(car,dim)
				setElementPosition(car,x,y,z)
				setElementRotation(car,rx,ry,rz)
				setElementVelocity(car,vx,vy,vz)
				for seat,plr in pairs(getVehicleOccupants(currentVeh)) do
					if (plr and getElementType(plr) == "player") then
						warpPedIntoVehicle(plr,car,seat)
					end
				end
				destroyElement(currentVeh)
			else
				outputChatBox("This vehicle is not allowed!",player,255,0,0)
				return
			end
		end
	else
		if isBanned(ID) == false then
			local car = createVehicle(ID,0,0,0)
			local dim = getElementDimension(player)
			local int = getElementInterior(player)
			local x,y,z = getElementPosition(player)
			local rx,ry,rz = getElementRotation(player)
			setElementInterior(car,int)
			setElementDimension(car,dim)
			setElementPosition(car,x,y,z+1)
			setElementRotation(car,rx,ry,rz)
			warpPedIntoVehicle(player,car)
		
		else
			outputChatBox("This vehicle is not allowed!",player,255,0,0)
			return
		end
	end
end

function lock(player,cmd)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		if getVehicleOccupant(vehicle,0) == player then
			if isVehicleLocked(vehicle) then
				setVehicleLocked(vehicle,false)
				outputChatBox("Unlocked!",player,0,255,255)
			else
				setVehicleLocked(vehicle,true)
				outputChatBox("Locked!",player,0,255,255)
			end
		end
	end
end
addCommandHandler("lock",lock)

function engine(player,cmd)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		if getVehicleOccupant(vehicle,0) == player then
			if getVehicleEngineState(vehicle) == true then
				setVehicleEngineState(vehicle,false)
				outputChatBox("Off!",player,0,255,255)
			else
				setVehicleEngineState(vehicle,true)
				outputChatBox("On!",player,0,255,255)
			end
		end
	end
end
addCommandHandler("engine",engine)