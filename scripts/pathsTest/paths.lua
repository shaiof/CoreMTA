local sx, sy = guiGetScreenSize()
local dx, dy = 1920, 1080
local keys = {
	cameraForward = 'num_8',
	cameraBackward = 'num_2',
	cameraLeft = 'num_4',
	cameraRight = 'num_6',
	cameraSlow = 'lalt',
	cameraFast = 'lctrl',
	cameraUp = 'num_sub',
	cameraDown = 'num_add',
	cameraTeleport = 'num_5',
	showMouse = 'num_7'
}

print('some test shit')

-- Path/Road Creation
local Road = {}
Road.__index = Road

local roadsDB = {}

local currentRoad = nil

function Road.newRoad(name)
	local self = setmetatable({}, Road)
	
	self.firstPos = nil
	self.secondPos = nil
	
	self.roadName = name
	
	self.currentPath = nil
	
	self.editing = false
	
	currentRoad = self
	
	self.paths = {}
	
	roadsDB[#roadsDB+1] = self
	return self
end

function Road:startPath(position, position2)
	if not self.currentPath then
		local pathSelf = {startPosition = position, endPosition = position2}
		self.paths[#self.paths+1] = pathSelf
		self.currentPath = pathSelf
		self.editing = true
	end
end

function Road:addPath(position)
	if self.currentPath then
		local startPos = self.paths[#self.paths].endPosition
		local pathSelf = {startPosition = startPos, endPosition = position}
		self.paths[#self.paths+1] = pathSelf
		self.editing = true
		iprint(self.paths)
	end
end

function Road:endPath(position)
	if self.currentPath then
		self.currentPath.endPosition = position
		self.paths[#self.paths+1] = self.currentPath
		self.currentPath = nil
		self.editing = false
	end
end

function Road:getDistance()
	local totalDistance = 0
	for i, path in pairs(self.paths) do
		local distance = getDistanceBetweenPoints3D(path.startPosition.x, path.startPosition.y, path.startPosition.z, path.endPosition.x, path.endPosition.y, path.endPosition.z)
		totalDistance = totalDistance+distance
	end
	return totalDistance
end
	
function Road:setPathStart(pathID, position)
	self.startPosition = position
end

function Road:setPathEnd(pathID, position)
	self.endPosition = position
end

function Road:removePath(pathID)
	self.paths[pathID] = nil
end

local test = Road.newRoad('shitnugget ave')

-- Camera Control
local cameraEnabled = false
local progressX = 0
local progressY = 0
local progressZ = 0
local x, y, z = 0, 0, 0

bindKey('o', 'down', function()
	if cameraEnabled then
		setCameraTarget(localPlayer)
		cameraEnabled = false
		toggleAllControls(true, true, false)
		setCloudsEnabled(true)
		showCursor(false)
	else
		cameraEnabled = true
		local position = localPlayer.position
		local lookAt = localPlayer.position
		setCameraMatrix(position, lookAt)
		x, y, z = getCameraMatrix()
		progressX, progressY, progressZ = 0, 0, 0
		toggleAllControls(false, true, false)
		setCloudsEnabled(false)
	end
end)

addEventHandler('onClientPreRender', root, function()
	if cameraEnabled then
		-- Forward
		if getKeyState(keys.cameraForward) and getKeyState(keys.cameraFast) then
			progressY = progressY+0.05
		end
		if getKeyState(keys.cameraForward) and getKeyState(keys.cameraSlow) then
			progressY = progressY+0.001
		end
		if getKeyState(keys.cameraForward) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressY = progressY+0.01
		end
		
		-- Backward
		if getKeyState(keys.cameraBackward) and getKeyState(keys.cameraFast) then
			progressY = progressY-0.05
		end
		if getKeyState(keys.cameraBackward) and getKeyState(keys.cameraSlow) then
			progressY = progressY-0.001
		end
		if getKeyState(keys.cameraBackward) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressY = progressY-0.01
		end
		
		-- Right
		if getKeyState(keys.cameraRight) and getKeyState(keys.cameraFast) then
			progressX = progressX+0.05
		end
		if getKeyState(keys.cameraRight) and getKeyState(keys.cameraSlow) then
			progressX = progressX+0.001
		end
		if getKeyState(keys.cameraRight) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressX = progressX+0.01
		end
		
		-- Left
		if getKeyState(keys.cameraLeft) and getKeyState(keys.cameraFast) then
			progressX = progressX-0.05
		end
		if getKeyState(keys.cameraLeft) and getKeyState(keys.cameraSlow) then
			progressX = progressX-0.001
		end
		if getKeyState(keys.cameraLeft) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressX = progressX-0.01
		end
		
		-- Up
		if getKeyState(keys.cameraUp) and getKeyState(keys.cameraFast) then
			progressZ = progressZ+0.05
		end
		if getKeyState(keys.cameraUp) and getKeyState(keys.cameraSlow) then
			progressZ = progressZ+0.001
		end
		if getKeyState(keys.cameraUp) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressZ = progressZ+0.01
		end
		
		-- Down
		if getKeyState(keys.cameraDown) and getKeyState(keys.cameraFast) then
			progressZ = progressZ-0.05
		end
		if getKeyState(keys.cameraDown) and getKeyState(keys.cameraSlow) then
			progressZ = progressZ-0.001
		end
		if getKeyState(keys.cameraDown) and not getKeyState(keys.cameraFast) and not getKeyState(keys.cameraSlow) then
			progressZ = progressZ-0.01
		end
		
		local newx, _, _ = interpolateBetween(x, y, z, 6000, 6000, 6000, progressX/100, 'Linear')
		local _, newy, _ = interpolateBetween(x, y, z, 6000, 6000, 6000, progressY/100, 'Linear')
		local _, _, newz = interpolateBetween(x, y, z, 6000, 6000, 6000, progressZ/100, 'Linear')
		if newx < -6000 then newx = -6000 end
		if newx > 6000 then newx = 6000 end
		if newy < -6000 then newy = 6000 end
		if newy > 6000 then newy = 6000 end
		if newz < 5 then newz = 5 end
		if newz > 6000 then newz = 6000 end
		local newHeight = getGroundPosition(newx, newy, 6000)+newz
		setCameraMatrix(newx, newy, newHeight, newx, newy, getGroundPosition(newx, newy, 6000))
		
		dxDrawText('Path Maker by ShayF\nNUM_8 Forward / NUM_2 Backward\nNUM_4 Left / NUM_6 Right\nNUM_- Down / NUM_+ Up\nLCTRL Fast / LALT Slow\nNUM_5 Teleport', 300/sx*sx, 400/sy*dy, 150/sx*dx, 150/sy*dy, tocolor(0, 255, 255, 200), 2, 'default-bold', 'center', 'center')
	end
	
	for i, v in pairs(test.paths) do
		dxDrawLine3D(v.startPosition, v.endPosition, tocolor(255, 0, 0, 255), 4)
	end
	
	for id, veh in pairs(getElementsByType('vehicle')) do
		local front = veh.matrix:transformPosition(0, 6, 0)
		local frontLeft = veh.matrix:transformPosition(-3, 6, 0)
		local frontRight = veh.matrix:transformPosition(3, 6, 0)
		local left = veh.matrix:transformPosition(-3, 0, 0)
		local right = veh.matrix:transformPosition(3, 0, 0)
		local rear = veh.matrix:transformPosition(0, -6, 0)
		local rearLeft = veh.matrix:transformPosition(-3, -6, 0)
		local rearRight = veh.matrix:transformPosition(3, -6, 0)
		dxDrawLine3D(veh.position, front, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, frontLeft, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, frontRight, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, left, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, right, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, rear, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, rearLeft, tocolor(0, 255, 255, 255), 3)
		dxDrawLine3D(veh.position, rearRight, tocolor(0, 255, 255, 255), 3)
	end
end)

bindKey(keys.cameraTeleport, 'down', function()
	if cameraEnabled then
		local x, y, z = getCameraMatrix()
		if localPlayer.vehicle then
			localPlayer.vehicle.position = Vector3(x, y, getGroundPosition(x, y, z)+0.5)
		else
			localPlayer.position = Vector3(x, y, getGroundPosition(x, y, z)+0.5)
		end
	end
end)

bindKey(keys.showMouse, 'down', function()
	showCursor(not isCursorShowing())
end)

addEventHandler('onClientClick', root, function(click, down, _, _, x, y, z)
	if click == 'left' and down == 'down' then
		if currentRoad then
			local cx, cy, cz = getCameraMatrix()
			local hit, hx, hy, hz = processLineOfSight(cx, cy, cz, x, y, z-0.1)
			if hit then
				print(1)
				if not currentRoad.editing then
					print(2)
					if currentRoad.firstPos then
						currentRoad.secondPos = Vector3(hx, hy, hz+0.22)
					else
						currentRoad.firstPos = Vector3(hx, hy, hz+0.22)
					end
					if currentRoad.firstPos and currentRoad.secondPos then
						currentRoad:startPath(currentRoad.firstPos, currentRoad.secondPos)
					end
				elseif currentRoad.editing then
					print(3)
					currentRoad:addPath(Vector3(hx, hy, hz+0.22))
				end
				if getKeyState('rctrl') then
					print(4)
					if currentRoad.editing then
						print(5)
						currentRoad:endPath(Vector3(hx, hy, hz+0.22))
					end
				end
			end
		end
	end
end)

addCommandHandler('npc', function()
	vehicle = Vehicle(411, test.paths[1].startPosition)
	ped = Ped(218, 0, 0, 0)
	warpPedIntoVehicle(ped, vehicle)
end)


