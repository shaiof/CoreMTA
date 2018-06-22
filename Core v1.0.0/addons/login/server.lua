addCommandHandler('c', function() print(s.name) end)

s.elements = {}

for i=1,330 do
	s.elements[i] = createPed(40, 153.614, 186.025 + i, 1.998)
end

print(s)