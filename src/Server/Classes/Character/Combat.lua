--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Character = require(Packages.Server.Classes.Character)
local RemoteObject = require(Packages.Server.RemoteObject)

local CombatStyle = require(Packages.Server.Classes.CombatStyle)
local _expect = require(Packages.Core.Expectation).new

--// Class
local CharacterCombat = Package.class("CharacterCombat").extends(RemoteObject).implements(Character)
:: Package.Class<CharacterCombat> & {
    new: () -> CharacterCombat
}

--// Constructor
function CharacterCombat.prototype:constructor()
    
    --// Instance
    self.client.CombatStyle = CombatStyle.default(self)
    self.client.Bleeding = 0
    self.client.Stunning = 0
    
    self._stunFinishes = 0
    
    self.Damaged:Connect(function(damage, data)
        
        self:_increaseState("Stunning", damage*data.StunningDamage)
        self:_increaseState("Bleeding", damage*data.BleedingDamage)
    end)
    
    return self
end

--// Methods
function CharacterCombat.prototype:Stun(duration: number)
    
    _expect(duration).is("number"):Argument(1, "duration")
    
    self._stunFinishes = math.max(self._stunFinishes, os.clock() + duration)
end
function CharacterCombat.prototype:IsStunned(): boolean
    
    return os.clock() > self._stunFinishes
end

--// End
export type CharacterCombat = typeof(CharacterCombat.prototype:constructor()) & Package.Object & Character.Character

return CharacterCombat