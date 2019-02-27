local sw,sh = guiGetScreenSize()
local maxWidth = 75

function getFPS(fn)
	local maxFps = getFPSLimit()
	local fps = 0
	local refreshRate = 3
	local prev = {}

	addEventHandler('onClientPreRender', root, function(dt)
		if #prev == refreshRate then
			fps = math.ceil(table.reduce(prev, function(a, b) return a + b end) / #prev)
			table.remove(prev, 1)
		else
			prev[#prev+1] = math.min(maxFps, math.ceil(1000 * (1 / dt)))
		end
		if not fn or type(fn) ~= 'function' then error('missing callback @ arg 1') end
		fn(fps)
	end)
end

function table.reduce(t, fn)
	local prev = 0
	for i=#t, 1, -1 do prev = fn(prev, t[i]) end
	return prev
end

getFPS(function(fps)
	local width = maxWidth*(fps/getFPSLimit())
	dxDrawText(fps.." FPS", 4 + 1, 986 + 1, 145 + 1, sh + 1, tocolor(0, 0, 0, 255), 1, "default", "left", "bottom", false, false, false, false, false)
	dxDrawText(fps.." FPS", 4, 986, 145, sh, tocolor(255, 255, 255, 155), 1, "default", "left", "bottom", false, false, false, false, false)
	dxDrawRectangle(46, sh-13, maxWidth, 12, tocolor(55, 55, 55, 156), false)
	dxDrawRectangle(46, sh-13, width, 12, tocolor(179, 179, 179, 156), false)
end)

addEventHandler("onClientChatMessage", root, function(msg)
	setWindowFlashing(true)
	createTrayNotification(msg, "default")
end)