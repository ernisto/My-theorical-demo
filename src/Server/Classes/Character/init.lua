--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, R...> = Package.Promise<F, R...>
type Signal<F> = Package.Signal<F>

--// Packages
local PhysicsService = game:GetService("PhysicsService")
local StarterPlayer = game:GetService("StarterPlayer")

local RemoteObject = require(Packages.Server.RemoteObject)
local Promise = require(Packages.Core.Promise)

local CharacterInventory: typeof(require(script.Inventory))
local CharacterCombat: typeof(require(script.Combat))

local _expect = require(Packages.Core.Expectation).new
local Character

task.defer(function()
    
    CharacterInventory = require(script.Inventory)
    CharacterCombat = require(script.Combat)
    
    Character.extends(CharacterInventory, CharacterCombat)
end)

--// Assets
local starterScripts = StarterPlayer.StarterCharacterScripts:GetChildren()
local StarterCharacter = StarterPlayer.StarterCharacter

--// Setup
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)

--// Class
Character = Package.class("Character").extends(RemoteObject, CharacterInventory, CharacterCombat)
:: RemoteObject.Class<Character> & {
    new: (rigInfo: { Model: Model?, HumanoidDescription: HumanoidDescription? }?, player: Player?) -> Character
}

--// Vars
local characterFromModel = setmetatable({}, { __mode = "kv" })

--// Class Vars
local charactersFolder = Instance.new("Folder", workspace)
charactersFolder.Name = "Characters"

Character.charactersFolder = charactersFolder

--// Class Functions
function Character.findCharactersOnBox(cframe: CFrame, size: Vector3): {Character}
    
    _expect(cframe).is("CFrame"):Argument(1, "cframe")
    _expect(size).is("Vector3"):Argument(2, "size")
    
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    overlapParams.FilterDescendantsInstances = {charactersFolder}
    
    local parts = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
    local catchedCharacters = {}
    local catchedModels = {}
    
    for _,part in parts do
        
        local characterModel = part
        
        while characterModel.Parent ~= charactersFolder do
            
            characterModel = characterModel.Parent
        end
        
        --// Task Per Character
        if catchedModels[characterModel] then continue end
        catchedModels[characterModel] = true
        
        table.insert(catchedCharacters, characterFromModel[characterModel])
    end
    
    --// End
    return catchedCharacters
end

--// Constructor
type rigInfo = {
    HumanoidDescription: HumanoidDescription?,
    Model: Model?,
}
function Character.prototype:constructor(rigInfo: rigInfo?, player: Player?)
    
    rigInfo = rigInfo or {}
    
    _expect(rigInfo).all.index.equals.some("Model", "HumanoidDescription"):Argument(1, "rigInfo")
    _expect(player).is.some("Player", "nil"):Argument(2, "player")
    
    local model = rigInfo.Model or StarterCharacter:Clone()
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    model.Name = if player then player.DisplayName else model.Name
    model.Parent = charactersFolder
    
    --// Instance
    RemoteObject(self, model, player)
    CharacterInventory(self)
    
    self.client.MaxHealth = 100
    self.client.Health = 100
    
    self.RootPart = humanoid.RootPart
    self.Humanoid = humanoid
    self.Player = player
    self.Model = self:Hoste(model)
    
    --// Setup
    self:SetCollisionGroup("Characters")
    self.client:AddEveryone()
    return self
end
function Character.prototype:postconstruct(rigInfo)
    
    rigInfo = rigInfo or {}
    
    --// Load Character
    self:Hoste(Promise.new(function(promise)
        
        if rigInfo.HumanoidDescription then self:ApplyDescriptionAsync(rigInfo.HumanoidDescription):Expect() end
        
        for _,starterScript in starterScripts do
            
            local script = starterScript:Clone()
            script.Parent = self.Model
        end
        
        characterFromModel[self.Model] = self
        self.Loaded()
    end))
    
    self:Hoste(self.Humanoid.Died:Once(function() self:Destroy() end))
end

--// Remote Signals
function Character.prototype.client.signal.Damaged(damage: number, data: damageData) end
function Character.prototype.client.signal.Loaded() end

--// Methods
function Character.prototype.async:ApplyDescriptionAsync(promise, description: HumanoidDescription): ()
    
    _expect(description).is("HumanoidDescription"):Argument(1, "description")
    
    return self.Humanoid:ApplyDescription(description)
end
function Character.prototype:SetCollisionGroup(collisionGroup: string)
    
    for _,part in self.Model:GetChildren() do
        
        if not part:IsA("BasePart") then continue end
        
        part.CollisionGroup = collisionGroup
    end
end

type damageData = { StunningDamage: number?, BleedDamage: number?, Damager: Character?, IsHeavy: boolean? }
function Character.prototype:Damage(damage: number, data: damageData)
    
    data = data or {}
    
    _expect(damage).is("number"):Argument(1, "damage")
    _expect(data).is("table"):Argument(1, "data")
    
    self:_decreaseState("Health", damage, 0)
    return self.Damaged(damage, data)
end

--// Behaviour
function Character.prototype:destroying()
    
    if self.Item then self.Item:Suspense() end
    if self.Bag then self.Bag:Suspense() end
end
function Character.prototype:components()
    
    return self.Model.Name
end

--// End
local Player: typeof(require(Packages.Server.Classes.Player))
type Player = Player.Player

export type Character = typeof(Character.prototype:constructor()) & RemoteObject.RemoteObject & CharacterInventory.CharacterInventory & CharacterCombat.CharacterCombat & {
    ApplyDescriptionAsync: (self: Character, description: HumanoidDescription) -> Promise<() -> ()>,
    
    Damaged: Signal<(damage: number, damager: Character?) -> ()>,
    Loaded: Signal<() -> ()>
}

return Character