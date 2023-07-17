--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Droppable = require(Packages.Server.Classes.Item.Droppable)
local Accessory = require(Packages.Server.Classes.Item.Accessory)
local Item = require(Packages.Server.Classes.Item)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new
local isA = Package.IsA

--// Class
local Bag = Package.class("Bag").extends(RemoteObject, Item, Accessory, Droppable)
:: RemoteObject.Class<Bag>

--// Constructor
Bag:_register("Bag")

function Bag.prototype:constructor(settings)
    
    local items = {}
    
    for index, itemData in settings.Items do
        
        local item = Item.create(itemData.Name, itemData)
        items[index] = item
    end
    
    --// Instance
    RemoteObject(self, items)
    
    Item(self, settings)
    Accessory(self)
    
    self._items = items
    
    --// Listeners
    self.Equipped:Connect(self._equipped, self)
    return self
end

--// Remote Methods
function Bag.prototype.client:StoreItemRemote(player, item: Item)
    
    expect(self.Owner == player.Character, "Permission denied")
    
    expect(isA(item, "Item"), "Argument 'item' must to be a Item")
    expect(item.Owner == nil or item.Owner.Player == player, "New item cannot be owned by others players")
    
    local owner = self.Owner
    expect(owner and owner.Player == player, "Item must to be owned by yourself")
    
    self:AddItem(item)
end

--// Remote Signals
function Bag.prototype.client.signal.ItemRemoving(item: Item, slot: integer) end
function Bag.prototype.client.signal.ItemRemoved(item: Item, slot: integer) end
function Bag.prototype.client.signal.ItemAdding(item: Item, slot: integer) end
function Bag.prototype.client.signal.ItemAdded(item: Item, slot: integer) end

--// Methods
function Bag.prototype:AddItem(item: Item, slot: integer?): integer
    
    _expect(item).is("Item"):Argument(1, "item")
    _expect(slot).is.some("integer", "nil"):Argument(2, "slot")
    
    if not slot then
        
        slot = 0
        
        repeat
            slot += 1
            local slotItem = self._items[slot]
            
        until not slotItem or slot >= self.Capacity
    end
    
    self.ItemAdding(item, slot)
    
    self._items[slot] = item
    item:Store(self, slot)
    
    item.Releasing:Once(self._itemReleased, self, item, slot)
    
    self.ItemAdded(item, slot)
end
function Bag.prototype:GetItem(slot: integer): Item?
    
    _expect(slot).is("integer"):Argument(1, "slot")
    
    return self._items[slot]
end

--// Listeners
function Bag.prototype:_itemReleased(item: Item, slot: integer)
    
    self.ItemRemoving(item, slot)
    
    self._items[slot] = nil
    
    self.ItemRemoved(item, slot)
end
function Bag.prototype:_equipped(owner: Character)
    
    self:_weldTo(owner.Model.UpperTorso)
end

--// End
export type Bag = typeof(Bag.prototype:constructor()) & RemoteObject.RemoteObject & {
    ItemRemoved: Signal<(bag: Bag, item: Item, slot: integer) -> ()>,
    ItemAdded: Signal<(bag: Bag, item: Item, slot: integer) -> ()>,
}

return Bag