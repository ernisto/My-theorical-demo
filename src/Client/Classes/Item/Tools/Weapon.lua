--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local Item = require(Packages.Client.Classes.Item)

local findCharactersOnBox = require(Packages.Client.Classes.Character).findCharactersOnBox
local localPlayer = require(Packages.Client.Classes.Player).awaitLocalPlayer()
local _expect = require(Packages.Core.Expectation).new

--// Class
local Weapon = Package.class("Weapon").extends(ServerObject, Item)
:: ServerObject.Class<Weapon>

--// Constructor
function Weapon.prototype:constructor()
    
    --// Instance
    self.HitboxSize = self.HitboxSize or Vector3.new(5, 5, 5)
    self.AttackSpeed = self.AttackSpeed or 1
    self.Damage = self.Damage or 0
    
    return self
end

--// Skills Methods
function Weapon.prototype.skill:Attack(skill)
    
    if skill.IsClientHolding then skill.InputReleased:Await() end
    
    if (skill:GetClientHoldingTime() or 0) < 1 then
        
        skill:ReleaseRemote(findCharactersOnBox(localPlayer.Character.RootPart.CFrame * CFrame.new(0, -1, 0), Vector3.new(5, 5, 5)))
    else
        
        skill:ReleaseRemote()
    end
end

--// End
export type Weapon = typeof(Weapon.prototype:constructor())

return Weapon.ready() :: typeof(Weapon)