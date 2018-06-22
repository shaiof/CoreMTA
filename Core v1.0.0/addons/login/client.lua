addCommandHandler('d', function() print('client', s.name) end)

setTimer(function()
	print('hello')
end, 7000, 1)

addEventHandler('onClientRender', root, function()
	dxDrawRectangle(500, 500, 500, 500, tocolor(255, 0, 0, 100))
	dxDrawRectangle(0, 500, 25, 125, tocolor(255, 255, 0))
end)

addEvent('mama', true)
addEventHandler('mama', resourceRoot, function(name)
	print('client', name)
end)