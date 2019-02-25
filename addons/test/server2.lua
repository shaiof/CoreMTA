function hi()
	print('c2')
end

addCommandHandler('c2', function()
	hi()
end)