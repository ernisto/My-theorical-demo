--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Item = require(Packages.Server.Classes.Item)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

--// Class
local Sheath = Package.class("Sheath").extends(RemoteObject, Item)
:: Package.Class<Sheath>

--// Constructor
Sheath:_register("Sheath")

function Sheath.prototype:constructor()
    
    --// Instance
    Item(self)
    self.client.Sword = nil :: Sword?
    
    return self
end

--// Remote Methods
function Sheath.prototype.client:SetSwordRemote(player, sword: Sword)
    
    expect(player.Character == self.Owner, "Permission denied")
    expect(player.Character == sword.Owner, "Permission denied")
    
    return self:SetSword(sword)
end
function Sheath.prototype.client:PullRemote(player)
    
    expect(self.Owner == player.Character, "Permission denied")
    expect(self.Sword, "Sword unequipped")
    
    return self:Pull()
end

--// Methods
function Sheath.prototype:SetSword(sword: Sword)
    
    self:_setState("Sword", sword)
end
function Sheath.prototype:Pull()
    
    if not self.Owner then return end
    if not self.Sword then return end
    
    self.Owner:EquipItem(self.Sword)
end

--// End
local Sword: typeof(require(Packages.Server.Classes._Item.Tools.Sword))
type Sword = Sword.Sword

export type Sheath = typeof(Sheath.prototype:constructor()) & Package.Object

return Sheath