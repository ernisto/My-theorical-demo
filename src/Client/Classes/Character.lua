--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

export type Signal<F> = Package.Signal<F>

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local _expect = require(Packages.Core.Expectation).new

--// Assets
local AnimationsFolder = Packages.Assets.Animations

--// Class
local Character = Package.class("Character").extends(ServerObject)
:: Package.Class<Character>

--// Vars
local charactersFolder = workspace:WaitForChild("Characters")
local characterFromModel = setmetatable({}, { __mode = "k" })

--// Functions
local function loadAnimations(animator: Animator, folder: Folder)
    
    local animations = {}
    
    for _,animation in folder:GetChildren() do
        
        animations[animation.Name] = if animation:IsA("Animation")
            then animator:LoadAnimation(animation)
            else loadAnimations(animator, animation)
    end
    
    return animations
end

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
        
        repeat
            characterModel = characterModel.Parent
            
        until characterModel.Parent == charactersFolder
        
        --// Task Per Character
        if catchedModels[characterModel] then continue end
        catchedModels[characterModel] = true
        
        table.insert(catchedCharacters, characterFromModel[characterModel])
    end
    
    --// End
    return catchedCharacters
end

--// Constructor
function Character.prototype:constructor(serverData, model: Model, player: Player?)
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator")
    
    --// Instance
    ServerObject(self, serverData)
    
    self.RootPart = humanoid.RootPart
    self.Humanoid = humanoid
    self.Player = player
    self.Model = model
    
    self.Tracks = loadAnimations(animator, AnimationsFolder)   :: {[string]: AnimationTrack}
    
    --// Log
    characterFromModel[model] = self
    return self
end

--// Types
local Player: typeof(require(Packages.Client.Classes.Player))
type Player = Player.Player

local Item: typeof(require(Packages.Client.Classes.Item))
type Item = Item.Item

local Bag: typeof(require(Packages.Client.Classes.Item.Bag))
type Bag = Bag.Bag

--// End
export type Character = typeof(Character.prototype:constructor()) & ServerObject.ServerObject & {
    MaxHealth: number,
    Health: number,
    Hand: Item?,
    Bag: Bag?,
    
    Damaged: Signal<(damage: number, damager: Character?) -> ()>,
    Loaded: Signal<() -> ()>,
}

return Character.ready() :: typeof(Character)