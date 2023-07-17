--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Player = require(Packages.Server.Classes.Player)
local Tree = require(Packages.Server.Libraries.Tree)
local Item = require(Packages.Server.Classes.Item)

task.defer(Tree.OakTree, CFrame.new(0, 5, 0))

--// Script
Player.PlayerJoined:Connect(function(player)
    
    local axe = Item.create("Axe")
    
    player.CharacterSpawning:Connect(function(character)
        
        character:EquipItem(axe)
    end)
end)

--// End
return nil