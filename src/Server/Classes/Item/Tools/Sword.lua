--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local Item = require(Packages.Server.Classes.Item)
local Droppable = require(Packages.Server.Classes.Item.Droppable)
local Weapon = require(script.Parent.Weapon)

local newCombatStyle = require(Packages.Server.Classes.CombatStyle).new

--// Class
local Sword = Package.class("Sword").extends(RemoteObject, Item, Weapon, Droppable)
:: RemoteObject.Class<Sword>

--// Constructor
Sword:_register("Sword")

function Sword.prototype:constructor()
    
    --// Instance
    Item(self)
    Weapon(self)
    
    self.client.Damage = 15
    self.client.CombatStyle = newCombatStyle(self.Owner, {
        BreakageDamage = 0.40,
        StunningDamage = 0.10,
        BleedDamage = 0.50,
        Damage = self.Damage,
        
        AttackSpeed = 0.33,
        HitRadius = 6,
        
        Combo = {
            { Animation = "SwordAttack1" },
            { Animation = "SwordAttack2" },
            { Animation = "SwordAttack3" },
            { Animation = "SwordAttack4" },
            { Animation = "SwordAttack5" },
        },
    })
    
    return self
end

--// End
export type Sword = typeof(Sword.prototype:constructor()) & Item.Item & Weapon.Weapon & Droppable.Droppable

return Sword