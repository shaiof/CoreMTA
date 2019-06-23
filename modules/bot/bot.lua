-- Test module

Bot = {}
Bot.__index = Bot

function Bot.new(id, x, y, z, rz)
    local self = setmetatable({}, Bot)
    self.ped = Ped(id, x, y, z, rz)
    return self
end

function Bot:destroy()
    self.ped:destroy()
end

return Bot