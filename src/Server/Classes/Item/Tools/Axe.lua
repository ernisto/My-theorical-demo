--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local Droppable = require(Packages.Server.Classes.Item.Droppable)
local Item = require(Packages.Server.Classes.Item)
local Weapon = require(script.Parent.Weapon)

local expect = require(Packages.Core.Expectation).assertMessage

local newCombatStyle = require(Packages.Server.Classes.CombatStyle).new
local isA = Package.IsA

--// Class
local Axe = Package.class("Axe").extends(RemoteObject, Item, Weapon, Droppable)

--// Constructor
Axe:_register("Axe")

function Axe.prototype:constructor()
    
    --// Instance
    Item(self)
    Weapon(self)
    Droppable(self)
    
    self.client.Damage = 15
    self.client.GripCFrame = CFrame.new(0, -.5, -.5) * CFrame.Angles(0, math.rad(90), math.rad(-90))
    self.client.CombatStyle = newCombatStyle(nil, {
        BreakageDamage = 0.60,
        StunningDamage = 0.30,
        BleedDamage = 0.10,
        Damage = self.Damage,
        
        AttackSpeed = 0.5,
        HitRadius = 5,
        
        Combo = {
            { Animation = "AxeAttack1" },
            { Animation = "AxeAttack2" },
            { Animation = "AxeAttack3" },
            { Animation = "AxeAttack4" },
            { Animation = "AxeAttack5" },
        },
    })
    
    self:_setSkill("Skill2", "Divise", self._diviseSkill)
    self:_setSkill("Skill1", "Chop", self._chopSkill)
    
    self:GetState("Owner"):Updater(function(owner) self.CombatStyle.Character = owner end)
    
    return self
end

--// Skills
function Axe.prototype:_diviseSkill(skill)
    
    skill:DeferApprove()
    
    local isReady = skill:AwaitReadyTime(.5)
    if not isReady then return end
    
    local branch = skill:GetReleaseData() or skill.Released:Await()
    if not branch then return end
    
    expect(isA(branch, "Branch"), `Invalid branch (Branch expected)`)
    expect(branch.Status == "dropped", `Branch must to be dropped`)
    
    branch:Divise()
end
function Axe.prototype:_chopSkill(skill)
    
    skill:DeferApprove()
    
    local isReady = skill:AwaitReadyTime(.5)
    if not isReady then return end
    
    local branch, heigth, direction = skill.Released:Await()
    if not branch then return end
    
    expect(isA(branch, "Branch"), "Invalid branch (Branch expected)")
    expect(isA(heigth, "integer"), "Invalid heigth (integer expected)")
    expect(0 <= heigth and heigth <= branch.Length, "Invalid heigth (0 <= heigth <= branch.Length expected)")
    
    branch:Chop(heigth, direction)
    skill:SetCooldown(1)
end

--// End
export type Axe = typeof(Axe.prototype:constructor()) & Item.Item & Weapon.Weapon & Droppable.Droppable

return Axe