--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)

local Item = require(Packages.Client.Classes.Item)
local Droppable = require(script.Parent.Parent.Droppable)
local Weapon = require(script.Parent.Weapon)

--// Class
local Sword = Package.class("Sword").extends(ServerObject, Item, Weapon, Droppable)
:: Package.Class<Sword>

--// Constructor
function Sword.prototype:constructor(serverData)
    
    --// Instance
    Item(self, serverData)
    Droppable(self)
    Weapon(self)
    
    return self
end

--// End
export type Sword = typeof(Sword.prototype:constructor()) & Item.Item & Weapon.Weapon & ServerObject.ServerObject

return Sword.ready() :: typeof(Sword)