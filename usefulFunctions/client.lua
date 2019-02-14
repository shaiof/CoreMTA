local sx, sy = guiGetScreenSize()
local sw, sh = 1366, 768

function dxSetRelativeRes(x, y)
	assert(type(x) == 'number' and type(y) == 'number', 'dxSetRelativeRes invalid x or y resolution size')
	sw, sh = x, y
end

_dxDrawRectangle, _dxDrawImage, _dxDrawText, _dxDrawLine = dxDrawRectangle, dxDrawImage, dxDrawText, dxDrawLine

function dxDrawRectangle(...)
	arg[1], arg[2], arg[3], arg[4] = arg[1]/sw*sx, arg[2]/sh*sy, arg[3]/sw*sx, arg[4]/sh*sy
	return _dxDrawRectangle(unpack(arg))
end

function dxDrawImage(...)
	arg[1], arg[2], arg[3], arg[4] = arg[1]/sw*sx, arg[2]/sh*sy, arg[3]/sw*sx, arg[4]/sh*sy
	return _dxDrawImage(unpack(arg))
end

function dxDrawText(...)
	arg[2], arg[3], arg[4], arg[5], arg[7] = arg[2]/sw*sx, arg[3]/sh*sy, (arg[4]+arg[2])/sw*sx, (arg[5]+arg[3])/sh*sy, (arg[7] or 1)/sw*sx
	return _dxDrawText(unpack(arg))
end

function dxDrawLine(...)
	arg[1], arg[2], arg[3], arg[4] = arg[1]/sw*sx, arg[2]/sh*sy, arg[3]/sw*sx, arg[4]/sh*sy
	return _dxDrawLine(unpack(arg))
end

function processLine(t, showline)
    local hit, x, y, z, elem, mx, my, mz, mat, light, piece, wmId, wmpX, wmpY, wmpZ, wmrX, wmrY, wmrZ, wlmId = processLineOfSight(
        t.a, -- startPos
        t.b, -- endPos
        t.buildings or true, --checkBuildings
        t.vehicles or true, --checkVehicles
        t.players or true, --checkPlayers
        t.objects or true, --checkObjects
        t.dummies or true, --checkDummies
        t.seeThrough or false, --seeThroughStuff
        t.ignoreSomeObjectsForCamera or true, --ignoreSomeObjectsForCamera
        t.shootThrough or false, --shootThroughStuff
        t.ignoredElement or nil, --ignoredElement
        t.includeWorldModelInfo or false, --includeWorldModelInformation
        t.inCludeCarTyres or false --bIncludeCarTyres
    )
	
    local hitdata = {
        pos = Vector3(x, y, z),
        element = elem,
        normal = Vector3(mx, my, mz),
        material = mat,
        lighting = light,
        piece = piece,
        worldModelId = wmId,
        worldModelPos = Vector3(wmpX, wmpY, wmpZ),
        worldModelRot = Vector3(wmrX, wmrY, wmrZ),
        worldLODModelId = wlmId
    }
	
    if showline then
        dxDrawLine3D(a, b, tocolor(255, 255, 255), 3)
        if hit then
            dxDrawLine3D(a, hitdata.pos, tocolor(255, 0, 0), 3)
        end
    end
	
    return hit and hitdata
end

local sm = {}
sm.moov = 0
sm.object1, sm.object2 = nil, nil
 
function removeCamHandler()
	if sm.moov == 1 then
		sm.moov = 0
	end
end
 
function camRender()
	if sm.moov == 1 then
		local x1, y1, z1 = getElementPosition(sm.object1)
		local x2, y2, z2 = getElementPosition(sm.object2)
		setCameraMatrix(x1, y1, z1, x2, y2, z2)
	else
		removeEventHandler('onClientPreRender', root, camRender)
	end
end
 
function smoothMoveCamera(x1, y1, z1, x1t, y1t, z1t, x2, y2, z2, x2t, y2t, z2t, time)
	if sm.moov == 1 then
		return false
	end
	sm.object1 = createObject(1337, x1, y1, z1)
	sm.object2 = createObject(1337, x1t, y1t, z1t)
	setElementAlpha(sm.object1, 0)
	setElementAlpha(sm.object2, 0)
	setObjectScale(sm.object1, 0.01)
	setObjectScale(sm.object2, 0.01)
	moveObject(sm.object1, time, x2, y2, z2, 0, 0, 0, 'InOutQuad')
	moveObject(sm.object2, time, x2t, y2t, z2t, 0, 0, 0, 'InOutQuad')
	sm.moov = 1
	setTimer(removeCamHandler, time, 1)
	setTimer(destroyElement, time, 1, sm.object1)
	setTimer(destroyElement, time, 1, sm.object2)
	addEventHandler('onClientPreRender', root, camRender)
	return true
end

local cP = {x = 0, y = 0, move = 'nil', timer = false}

function getCursorMovedOn()
    return cP
end

addEventHandler('onClientCursorMove', root, function(cursorX, cursorY)
	if not isCursorShowing() then
		return
	end

	if cursorX > cP.x then
		cP.move = 'right'
	elseif cursorX < cP.x then
		cP.move = 'left'
	elseif cursorY > cP.y then
		cP.move = 'up'
	elseif cursorY < cP.y then
		cP.move = 'down'
	end

	cP.x = cursorX
	cP.y = cursorY

	if isTimer(cP.timer) then
		killTimer(cP.timer)
	end

	cP.timer = setTimer(function()
		cP.move = 'nil'
	end, 50, 1)
end)

function dxDrawAnimWindow(text, height, width, color, font, anim)
    local x, y = guiGetScreenSize()
    btwidth = width
    btheight = height/20
    local now = getTickCount()
    local elapsedTime = now - start
    local endTime = start + 1500
    local duration = endTime - start
    local progress = elapsedTime / duration
    local x1, y1, z1 = interpolateBetween(0, 0, 0, width, height, 255, progress, anim)
    local x2, y2, z2 = interpolateBetween(0, 0, 0, btwidth, btheight, btheight/11, progress, anim)
 
    posx = (x/2)-(x1/2)
    posy = (y/2)-(y1/2)

    dxDrawRectangle(posx, posy-y2, x2, y2, color)
    dxDrawRectangle(posx, posy, x1, y1, tocolor(0, 0, 0, 200))
    dxDrawText(text, 0, -(y1)-y2, x, y, tocolor(255, 255, 255, 255), z2,font, 'center', 'center')
end

function dxDrawBorderedRectangle(x, y, width, height, color1, color2, _width, postGUI)
    local _width = _width or 1
    dxDrawRectangle(x+1, y+1, width-1, height-1, color1, postGUI)
    dxDrawLine(x, y, x+width, y, color2, _width, postGUI) -- Top
    dxDrawLine(x, y, x, y+height, color2, _width, postGUI) -- Left
    dxDrawLine(x, y+height, x+width, y+height, color2, _width, postGUI) -- Bottom
    dxDrawLine(x+width, y, x+width, y+height, color2, _width, postGUI) -- Right
end

function dxDrawBorderedText(outline, text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
	for oX = (outline * -1), outline do
		for oY = (outline * -1), outline do
			dxDrawText(text, left + oX, top + oY, right + oX, bottom + oY, tocolor(0, 0, 0, 255), scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
		end
	end
	dxDrawText(text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
end

function dxDrawDashedLine(sX, sY, eX, eY, lengthLine, lengthSpace, color, width, postGUI)
	lengthSpace = lengthSpace or lengthLine
	color = color or tocolor(255, 255, 255, 255)
	width = width or 1
	postGUI = postGUI or false
	local length = getDistanceBetweenPoints2D(sX, sY, eX, eY)
	local linePartLength = lengthLine + lengthSpace
	local lineParts = length / linePartLength
	local xToAdd = (eX - sX) / lineParts
	local yToAdd = (eY - sY) / lineParts
	local lineRatio = lengthSpace / lengthLine
	while (length > 0) do
		if (lengthLine > length) then
			dxDrawLine(sX, sY, eX, eY, color, width, postGUI)
			length = 0
		else
			dxDrawLine(sX, sY, sX + xToAdd - xToAdd * lineRatio, sY + yToAdd - yToAdd * lineRatio, color, width, postGUI)
			sX = sX + xToAdd
			sY = sY + yToAdd
			length = length - linePartLength
		end
	end
end


function dxDrawTextOnRectangle(posX, posY, whidth, height, texto, fuente, cite1, cite2, color, posGui)
	dxDrawRectangle( posX, posY, whidth, height, color, posGui or false )
	dxDrawText(texto, posX, posY, whidth+posX, height+posY, tocolor(255,255,255,255), 1, fuente or 'arial', cite1 or 'center', cite2 or 'center', false, true, posGui or false, false, false)
end

function dxDrawGifImage(x, y, w, h, path, iStart, iType, effectSpeed)
	local gifElement = createElement ( "dx-gif" )
	if ( gifElement ) then
		setElementData(gifElement, 'gifData', {x = x, y = y, w = w, h = h, imgPath = path, startID = iStart, imgID = iStart, imgType = iType, speed = effectSpeed, tick = getTickCount()}, false)
		return gifElement
	else
		return false
	end
end

addEventHandler('onClientRender', root, function()
	local currentTick = getTickCount()
	for index, gif in ipairs(getElementsByType('dx-gif')) do
		local gifData = getElementData(gif, 'gifData')
		if gifData then
			if currentTick - gifData.tick >= gifData.speed then
				gifData.tick = currentTick
				gifData.imgID = gifData.imgID + 1
				if fileExists(gifData.imgPath..gifData.imgID..'.'..gifData.imgType) then
					gifData.imgID = gifData.imgID
					setElementData(gif, 'gifData', gifData, false)
				else
					gifData.imgID = gifData.startID
					setElementData(gif, 'gifData', gifData, false)
				end
			end
			dxDrawImage(gifData.x, gifData.y, gifData.w, gifData.h, gifData.imgPath..gifData.imgID..'.'..gifData.imgType)
		end
	end
end)

function dxDrawImage3D(x, y, z, width, height, material, color, rotation, ...)
    return dxDrawMaterialLine3D(x, y, z, x + width, y + height, z + tonumber(rotation or 0), material, height, color or 0xFFFFFFFF, ...)
end

function dxDrawImageOnElement(TheElement, Image, distance, height, width, R, G, B, alpha)
	local x, y, z = getElementPosition(TheElement)
	local x2, y2, z2 = getElementPosition(localPlayer)
	local distance = distance or 20
	local height = height or 1
	local width = width or 1
	local checkBuildings = checkBuildings or true
	local checkVehicles = checkVehicles or false
	local checkPeds = checkPeds or false
	local checkObjects = checkObjects or true
	local checkDummies = checkDummies or true
	local seeThroughStuff = seeThroughStuff or false
	local ignoreSomeObjectsForCamera = ignoreSomeObjectsForCamera or false
	local ignoredElement = ignoredElement or nil
	if (isLineOfSightClear(x, y, z, x2, y2, z2, checkBuildings, checkVehicles, checkPeds, checkObjects, checkDummies, seeThroughStuff, ignoreSomeObjectsForCamera, ignoredElement)) then
		local sx, sy = getScreenFromWorldPosition(x, y, z+height)
		if sx and sy then
			local distanceBetweenPoints = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
			if distanceBetweenPoints < distance then
				dxDrawMaterialLine3D(x, y, z+1+height-(distanceBetweenPoints/distance), x, y, z+height, Image, width-(distanceBetweenPoints/distance), tocolor(R or 255, G or 255, B or 255, alpha or 255))
			end
		end
	end
end

local start = getTickCount()
function dxDrawLoading(x, y, width, height, x2, y2, size, color, color2, second)
	local now = getTickCount()
	local seconds = second or 5000
	local color = color or tocolor(0, 0, 0, 170)
	local color2 = color2 or tocolor(255, 255, 0, 170)
	local size = size or 1.00
	local with = interpolateBetween(0, 0, 0, width, 0, 0, (now - start) / ((start + seconds) - start), 'Linear')
	local text = interpolateBetween(0, 0, 0, 100, 0, 0, (now - start) / ((start + seconds) - start), 'Linear')
	dxDrawRectangle(x, y, width, height -10, color)
	dxDrawRectangle(x, y, with, height -10, color2)
end

function dxDrawOctagon3D(x, y, z, radius, width, color)
	if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then
		return false
	end

	local radius = radius or 1
	local radius2 = radius/math.sqrt(2)
	local width = width or 1
	local color = color or tocolor(255,255,255,150)

	point = {
		{x = x, y = y-radius}, -- 1
		{x = x+radius2, y = y-radius2}, -- 2
		{x = x+radius, y = y}, -- 3
		{x = x+radius2, y = y+radius2}, -- 4
		{x = x, y = y+radius}, -- 5
		{x = x-radius2, y = y+radius2}, -- 6
		{x = x-radius, y = y}, -- 7
		{x = x-radius2, y = y-radius2} -- 8
	}
		
	for i=1, 8 do
		if i ~= 8 then
			x, y, z, x2, y2, z2 = point[i].x, point[i].y, z, point[i+1].x, point[i+1].y, z
		else
			x, y, z, x2, y2, z2 = point[i].x, point[i].y, z, point[1].x, point[1].y, z
		end
		dxDrawLine3D(x, y, z, x2, y2, z2, color, width)
	end
	return true
end

function dxDrawPolygon(x, y, radius, sides, color, rotation, width)
	local last = {}
	for i=0, sides do
		local radian = math.rad((rotation or 0) + i*(360/sides))
		local lineX, lineY = x + radius * math.cos(radian), y + radius * math.sin(radian)
		if last[1] and last[2] then
			dxDrawLine(last[1], last[2], lineX, lineY, color, width or 1)
		end
		last[1], last[2] = lineX, lineY
	end
end

function dxDrawRectangle3D(x, y, z, w, h, c, r, ...)
	local lx, ly, lz = x+w, y+h, (z+tonumber(r or 0)) or z
	return dxDrawMaterialLine3D(x, y, z, lx, ly, lz, dxCreateTexture(1, 1), h, c or tocolor(255, 255, 255, 255), ...)
end

function dxDrawTextOnElement(TheElement, text, height, distance, R, G, B, alpha, size, font, ...)
	local x, y, z = getElementPosition(TheElement)
	local x2, y2, z2 = getCameraMatrix()
	local distance = distance or 20
	local height = height or 1

	if (isLineOfSightClear(x, y, z+2, x2, y2, z2, ...)) then
		local sx, sy = getScreenFromWorldPosition(x, y, z+height)
		if(sx) and (sy) then
			local distanceBetweenPoints = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
			if(distanceBetweenPoints < distance) then
				dxDrawText(text, sx+2, sy+2, sx, sy, tocolor(R or 255, G or 255, B or 255, alpha or 255), (size or 1)-(distanceBetweenPoints / distance), font or "arial", "center", "center")
			end
		end
	end
end

function dxDrawTriangle(x, y, width, height, color, _width, postGUI)
	if (type(x) ~= 'number') or (type(y) ~= 'number') then
		return false
	end

	_width = (type(_width) == 'number' and _width) or 1
	color = color or tocolor(255, 255, 255, 200)
	postGUI = (type(postGUI) == 'boolean' and postGUI) or false

	dxDrawLine(x+width/2, y, x, y+height, color, _width, postGUI) 
	dxDrawLine(x+width/2, y, x+width, y+height, color, _width, postGUI)
	return dxDrawLine(x, y+height, x+width, y+height, color, _width, postGUI)
end

function dxGetFontSizeFromHeight(height, font)
    if type( height ) ~= 'number' then
		return false
	end
    font = font or 'default'
    local ch = dxGetFontHeight(1, font)
    return height/ch
end 

function dxGetRealFontHeight(font)
    local cap, base = measureGlyph(font, 'S')
    local median, decend = measureGlyph(font, 'p')
    local ascend, base2 = measureGlyph(font, 'h')

    local ascenderSize = median - ascend
    local capsSize = median - cap
    local xHeight = base - median
    local decenderSize = decend - base

    return math.max(capsSize, ascenderSize) + xHeight + decenderSize
end

function measureGlyph(font, character)
    local rt = dxCreateRenderTarget(128, 128)
    dxSetRenderTarget(rt, true)
    dxDrawText(character, 0, 0, 0, 0, tocolor(255, 255, 255), 1, font)
    dxSetRenderTarget()
    local pixels = dxGetTexturePixels(rt)
    local first, last = 127, 0
    for y=0, 127 do
        for x=0, 127 do
            local r = dxGetPixelColor(pixels, x, y)
            if r > 0 then
                first = math.min(first, y)
                last = math.max(last, y)
                break
            end
        end
        if last > 0 and y > last+2 then
			break
		end
    end
    destroyElement(rt)
    return first, last
end 

local attachedEffects = {}

function attachEffect(effect, element, pos)
	attachedEffects[effect] = { effect = effect, element = element, pos = pos }
	addEventHandler('onClientElementDestroy', effect, function() attachedEffects[effect] = nil end)
	addEventHandler('onClientElementDestroy', element, function() attachedEffects[effect] = nil end)
	return true
end

addEventHandler('onClientPreRender', root, function()
	for fx, info in pairs(attachedEffects) do
		local x, y, z = getPositionFromElementOffset(info.element, info.pos.x, info.pos.y, info.pos.z)
		setElementPosition(fx, x, y, z)
	end
end)

function isElementInPhotograph(ele)
	local nx, ny, nz = getPedWeaponMuzzlePosition(localPlayer)
	if (ele ~= localPlayer) and (isElementOnScreen(ele)) then
		local px, py, pz = getElementPosition(ele)
		local _, _, _, _, hit = processLineOfSight(nx, ny, nz, px, py, pz)
		if (hit == ele) then
			return true
		end
	end
	return false
end

function isElementWithinAColShape(element)
	local element = element or localPlayer
	if element or isElement(element)then
		for _, colshape in ipairs(getElementsByType('colshape')) do
			if isElementWithinColShape(element, colshape) then
				return colshape
			end
		end
	end
	return false
end

