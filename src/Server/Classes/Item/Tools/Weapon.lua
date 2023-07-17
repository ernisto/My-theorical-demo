--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local findCharactersOnBox = require(Packages.Server.Classes.Character).findCharactersOnBox
local Item = require(Packages.Server.Classes.Item)

--// Class
local Weapon = Package.class("Weapon").extends(RemoteObject, Item)
:: Package.Class<Weapon>

--// Vars
local CHARACTERS_OVERLAP_PARAMS = OverlapParams.new()
CHARACTERS_OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Whitelist
CHARACTERS_OVERLAP_PARAMS.FilterDescendantsInstances = {workspace:WaitForChild("Characters")}

--// Constructor
function Weapon.prototype:constructor()
    
    --// Instance
    self.client.Damage = 0
    
    self:_setSkill("Attack", "Attack", self._attackSkill)
    return self
end

--// Protected Methods
function Weapon.prototype:_barrageHitbox(): {Character}
    
    local radius = self.CombatStyle.HitRadius*2
    
    local characters = findCharactersOnBox(self.Owner.RootPart.CFrame, Vector3.new(radius, 4, radius))
    return characters
end

--// Skills
function Weapon.prototype:_barrageSkill(skill: Skill)
    
    local interval = .1
    
    local totalAttacks = 3/interval
    local damage = self.Damage/5
    local attacks = 0
    
    repeat
        local newAttacks = attacks + task.wait(interval)/interval
        warn(("barraging (%.2fs)"):format(skill:GetHoldingTime()))
        
        for combo = math.floor(attacks) + 1, math.floor(newAttacks) do
            
            print(combo)
            
            self.CombatStyle:DoDamage(damage, self:_barrageHitbox())
            if combo == totalAttacks then return end
        end
        
        attacks = newAttacks
        
    until not skill:IsHolding()
    
    return math.floor(attacks)
end
function Weapon.prototype:_attackSkill(skill: Skill)
    
    skill:DeferApprove("some skill client data")
    local stage = skill:AwaitReadyTime(0, .5, 1)
    
    if stage == 3 then
        
        skill:SetDuration(3)
        
        self:_barrageSkill(skill)
        skill:SetStageCooldown(3, 15)
    else
        
        self.CombatStyle:Attack(stage == 2)
        skill:SetCooldown(.3)
    end
end

--// End
export type Weapon = typeof(Weapon.prototype:constructor()) & RemoteObject.RemoteObject

return Weapon