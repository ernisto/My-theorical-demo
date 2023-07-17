--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Character = require(Packages.Server.Classes.Character)
local RemoteObject = require(Packages.Server.RemoteObject)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local isA = Package.IsA

--// Class
local CharacterInventory = Package.class("Inventory").extends(RemoteObject).implements(Character)

--// Remote Functions
function CharacterInventory.client.equipRightItem(player, item: Item?)
    
    local character = expect(player.Character, "Character not spawned")
    expect(item == nil or isA(item, "Item"), "Invalid item")
    
    return character:EquipRightItem(item)
end
function CharacterInventory.client.equipBag(player, bag: Bag)
    
    local character = expect(player.Character, "Character not spawned")
    expect(bag == nil or isA(bag, "Bag"), "Invalid bag")
    
    return character:EquipRightItem(bag)
end

--// Constructor
function CharacterInventory.prototype:constructor()
    
    self.client.Item = nil  :: Item?
    self.client.Bag = nil   :: Bag?
    
    return self
end

--// Methods
function CharacterInventory.prototype:EquipItem(item: Item?)
    
    _expect(item).is.some("Item", "nil"):Argument(1, "item")
    
    if self.Item then
        
        self.Item:Drop()
    end
    
    if item then
        
        item.Unhandled:Once(self._setState, self, "Item", nil)
        item:Handle(self)
    end
    
    self:_setState("Item", item)
end
function CharacterInventory.prototype:EquipBag(bag: Bag?)
    
    _expect(bag).is.some("Bag", "nil"):Argument(1, "bag")
    
    if self.Bag then
        
        self.Bag:Drop()
    end
    
    if bag then
        
        bag.Unequipped:Once(self._setState, self, "Bag", nil)
        bag:Equip(self)
    end
    
    self:_setState("Bag", bag)
end

--// End
export type CharacterInventory = typeof(CharacterInventory.prototype:constructor()) & Package.Object

return CharacterInventory