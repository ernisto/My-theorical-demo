--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local Droppable = require(Packages.Client.Classes.Item.Droppable)
local Accessory = require(Packages.Client.Classes.Item.Accessory)
local Item = require(Packages.Client.Classes.Item)

--// Class
local Bag = Package.class("Bag").extends(ServerObject, Item, Accessory, Droppable)
:: Package.Class<Bag>

--// Constructor
function Bag.prototype:constructor(serverData, items: {Item})
    
    --// Instance
    Item(self, serverData)
    Droppable(self)
    Accessory(self)
    
    self._items = items
    
    --// Listeners
    self.ItemAdded:Connect(self._itemAdded, self)
    return self
end

--// Listeners
function Bag.prototype:_itemAdded(item: Item, slot: integer)
    
    self._items[slot] = item
end

--// End
export type Bag = typeof(Bag.prototype:constructor()) & Item.Item & ServerObject.ServerObject

return Bag.ready() :: typeof(Bag)