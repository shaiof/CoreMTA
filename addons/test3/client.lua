print('the client')


local p = Ped(32, Player('morty').position)
local p2 = Ped(35, Player('morty').position)

addEventHandler('onClientPedWasted', resourceRoot, function()
    iprint('clientwasted', source or 'nada', source.model)
end)