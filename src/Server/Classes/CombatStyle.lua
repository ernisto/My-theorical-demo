--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local findCharactersOnBox = require(Packages.Server.Classes.Character).findCharactersOnBox

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

--// Class
local CombatStyle = Package.class("CombatStyle").extends(RemoteObject)
:: Package.Class<CombatStyle> & {
    new: (character: Character, data: combatData?) -> CombatStyle
}

--// Functions
function CombatStyle.default(character: Character)
    
    return CombatStyle.new(character, {
        BreakageDamage = 0.30,
        StunningDamage = 0.60,
        BleedDamage = 0.10,
        Damage = 5,
        
        AttackSpeed = 0,
        CatchRadius = 5,
        Combo = {
            { Animation = "Punch1" },
            { Animation = "Punch2" },
            { Animation = "Punch3" },
            { Animation = "Punch4" },
            { Animation = "Punch5" },
        },
    })
end

--// Constructor
type combatData = {
    BreakageDamage: number,
    StunningDamage: number,
    BleedDamage: number,
    Damage: number,
    
    AttackSpeed: number,
    HitRadius: number,
    Combo: { { Animation: string } },
}
function CombatStyle.prototype:constructor(character: Character?, data: combatData?)
    
    _expect(character).is.some("Character", "nil"):Argument(1, "character")
    _expect(data).is("table"):Argument(2, "data")
    
    --// Instance
    RemoteObject(self)
    
    self.client.BreakageDamage = data.BreakageDamage or 0.00
    self.client.StunningDamage = data.StunningDamage or 0.00
    self.client.BleedDamage = data.BleedDamage or 0.00
    self.client.Damage = data.Damage or 0
    
    self.client.AttackSpeed = data.AttackSpeed or 0
    self.client.HitRadius = data.HitRadius or 5
    self.client.Combo = data.Combo or {}
    
    self.ComboCooldown = 3/self.AttackSpeed
    self.Cooldown = 1/self.AttackSpeed
    self.ComboLength = #self.Combo
    self.Combo = 0
    
    self.Character = character
    
    self._cooldownFinishes = 0
    return self
end

--// Methods
function CombatStyle.prototype:Attack(isHeavy: boolean, targets: {Character}?)
    
    isHeavy = isHeavy or false
    targets = targets or findCharactersOnBox(self.Character.RootPart.CFrame * CFrame.new(0, 0, -1), Vector3.new(self.HitRadius, 4, self.HitRadius))
    
    _expect(isHeavy).is("boolean"):Argument(1, "isHeavy")
    _expect(targets).all.value.is("Character"):Argument(2, "targets")
    
    expect(os.clock() > self._cooldownFinishes, "Attack in cooldown")
    
    local combo = self.Combo + 1
    isHeavy = isHeavy or combo == self.ComboLength
    
    if isHeavy then
        
        self._cooldownFinishes = os.clock() + self.ComboCooldown
        self.Combo = 0
    else
        
        self._cooldownFinishes = os.clock() + 1/self.AttackSpeed
    end
    
    self:DoDamage(self.Damage, targets)
end
function CombatStyle.prototype:DoDamage(damage: number, targets: {Character})
    
    _expect(damage).is("number"):Argument(1, "damage")
    _expect(targets).all.value.is("Character"):Argument(1, "targets")
    
    local selfCharacter = self.Character
    local selfParty = self.Party
    
    for _,target in targets do
        
        if target == selfCharacter then continue end
        
        local player = target.Player
        if player then local party = player.Party if party == selfParty then continue end end
        
        target:Damage(damage, {
            StunningDamage = self.StunningDamage,
            BleedDamage = self.BleedDamage,
            Damager = self.Character,
        })
    end
end

--// End
export type CombatStyle = typeof(CombatStyle.prototype:constructor()) & Package.Object

return CombatStyle