local coremta = {}
coremta.version = 'version 2.0'

local file = fileOpen('au.lua') or fileCreate('au.lua')
local buffer = fileRead(file, fileGetSize(file))
fileClose(file)
if buffer == 'true' then buffer = true elseif buffer == 'false' then buffer = false else buffer = true end
coremta.au = buffer

function coremta.update()
	fetchRemote('http://www.coremta.ga/projectfiles/files', function(data, errorNum)
		if errorNum == 0 and data then
			local files = split(data, '/n')
			if files[1] ~= coremta.version then
				local n = 1
				local function stepFunc()
					n = n+1
					fetchRemote('http://www.coremta.ga/projectfiles/'..files[n], function(data, errorNum, file, startNext)
						if errorNum == 0 and data then
							local f = fileOpen(file) or fileCreate(file)
							fileWrite(f, data)
							fileClose(f)
							startNext()
						end
					end, files[n], stepFunc)
				end
				coremta.version = files[1]
				stepFunc()
			end
		end
	end)
end

function coremta.autoupdate(enable)
	if type(enable) == 'boolean' then
		local file = fileOpen('au.lua')
		fileWrite(tostring(enable), file)
		fileClose(file)
	end
end

if coremta.au then
	coremta.update()
end

function execCoreCmd(cmd, ...)
	local fn = coreCmds[cmd:lower()]
	if fn then
		for i=1, #arg do
			local n = tonumber(arg[i])
			if n then
				arg[i] = n
			elseif arg[i] == 'true' then
				arg[i] = true
			elseif arg[i] == 'false' then
				arg[i] = false
			end
		end
		fn(unpack(arg))
	end
end
addCommandHandler('coremta', execCoreCmd)