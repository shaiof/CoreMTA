addCommandHandler('test', function(_, _, ...)
	print(math.round(12.35434634626324, tonumber(arg[1])))
end)

print(getFPSLimit())