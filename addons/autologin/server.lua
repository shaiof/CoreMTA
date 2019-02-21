addEvent("loginPlayer", true)
addEventHandler("loginPlayer", resourceRoot, function(player, details)
	local acc = Account(details[1], details[2]) -- expected string at arg 1 got nil??
	if acc then
		logIn(player, acc, details[2])
	else
		outputChatBox("login: The account details are incorrect. You may have to save your login again by typing /login user pass", player, 255, 0, 0)
	end
end)

addEventHandler("onPlayerCommand", root, function(cmd)
	if cmd == "login" then
		cancelEvent()
	end
end)