--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)

local create = require(Packages.Libraries.Component).create
local _expect = require(Packages.Core.Expectation).new

--// Class
local Accessory = Package.class("Accessory").extends(ServerObject)
:: Package.Class<Accessory> & {
    new: () -> Accessory
}

--// Constructor
function Accessory.prototype:constructor()
    
    --// Instance
    self._equippedActions = {}
    return self
end
function Accessory.prototype:postconstructor()
    
    --// Listeners
    if self.Status == "equipped" then self:_equipped(self.Owner) end
    self.Unequipped:Connect(self._unequipped, self)
    self.Equipped:Connect(self._equipped, self)
end

--// Virtual Protected Methods
function Accessory.prototype:_unequipped(owner: Character)
    
    self:_disableBody()
    self:_unweld()
end
function Accessory.prototype:_equipped(owner: Character)
    
    self:_weldTo(owner.Model.UpperTorso)
    self:_enableBody()
end

--// End
export type Accessory = typeof(Accessory.prototype:constructor()) & Package.Object

return Accessory.ready() :: typeof(Accessory)