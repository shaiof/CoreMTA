local filePath = "@login.txt"

function saveLogin(user, pass)
	if user and pass then
		if File.exists(filePath) then
			File.delete(filePath)
		end
		local f = File.new(filePath)
		local suc = f and f:write(user..":"..pass)
		if suc then
			f:close()
			return true
		else
			return false
		end
	end
end

function getLogin()
	local f = File.exists(filePath) and fileOpen(filePath,true)
	if f then
		local details = split(f:read(f.size), ":")
		f:close()
		return details
	else
		return false
	end
end

addCommandHandler("login", function(_, ...)
	local suc = saveLogin(arg[1], arg[2])
	if not suc then
		outputChatBox("login: There was a problem saving your login details.", 255, 0, 0)
		return
	end
	triggerServerEvent("loginPlayer", resourceRoot, localPlayer, arg)
	outputChatBox("login: Your details have been saved", 255, 168, 0)
end,false,false)

local details = getLogin()
if details[1] and details[2] then
	triggerServerEvent("loginPlayer", resourceRoot, localPlayer, details)
else
	outputChatBox("login: Failed to get details. Please use /login user pass", 255, 0, 0)
end