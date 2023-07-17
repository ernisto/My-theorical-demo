--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local ItemStatus = require(script.Parent).ItemStatus

local _expect = require(Packages.Core.Expectation).new

--// Class
local Accessory = Package.class("Accessory").extends(RemoteObject)
:: RemoteObject.Class<Accessory>

--// Constructor
function Accessory.prototype:constructor()
    
    --// Instance
    self._weld = nil :: Weld?
    return self
end

--// Remote Signals
function Accessory.prototype.client.signal.Equipping(owner: Character) end
function Accessory.prototype.client.signal.Equipped(owner: Character) end
function Accessory.prototype.client.signal.Unequipping() end
function Accessory.prototype.client.signal.Unequipped() end

--// Methods
function Accessory.prototype:Equip(owner: Character)
    
    _expect(owner).is("Character"):Argument(1, "owner")
    
    self.Equipping(owner)
    self:_equip(owner)
    self.Equipped(self.Owner)
end

--// Virtual Protected Methods
function Accessory.prototype:_equip(owner: Character)
    
    self:_setOwner(owner)
    self:_setStatus(ItemStatus.Equipped)
        .Changed:Once(self._unequipping, self)
    
    self.client:AddEveryone()
end
function Accessory.prototype:_unequip(newStatus: ItemStatus)
end

--// Private Methods
function Accessory.prototype:_unequipping(newStatus: ItemStatus)
    
    self.Unequipping()
    self:_unequip(newStatus)
    self.Unequipped()
end

--// End
export type Accessory = typeof(Accessory.prototype:constructor()) & RemoteObject.RemoteObject & {
    Equipping: Signal<(owner: Character)->()>,
    Equipped: Signal<(owner: Character)->()>,
    Unequipping: Signal<()->()>,
    Unequipped: Signal<()->()>,
}

return Accessory