--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Connection = Package.Connection

--// Packages
local ServerObject = require(Packages.Client.ServerObject)

local create = require(Packages.Libraries.Component).create
local _expect = require(Packages.Core.Expectation).new

local Keyboard = require(Packages.Client.Classes.Device.Keyboard)
local Mouse = require(Packages.Client.Classes.Device.Mouse)

--// Abstract Class
local Item = Package.class("Item").extends(ServerObject)
:: Class<Item>

--// Consts
local KEYBINDS = {
    Pickup = Keyboard.Keys.E,
    Drop = Keyboard.Keys.Q,
    
    Attack = Mouse.Buttons.Left,
    Skill1 = Keyboard.Keys.E,
    Skill2 = Keyboard.Keys.R,
    Skill3 = Keyboard.Keys.V,
    Skill4 = Keyboard.Keys.C,
}

--// Class Vars
Item.prototype.skill = {}

--// Vars
local itemModels = {} do
    
    for _,itemModel in Packages.Assets.ItemModels:GetChildren() do
        
        itemModels[itemModel.Name] = itemModel
    end
end

--// Functions
local function skillInCooldown(item, skillHandler, exception)
    
    warn(`{skillHandler.Name} in cooldown, time left: {exception.TimeLeft}`)
end

--// Constructor
function Item.prototype:constructor(serverData)
    
    --// Instance
    ServerObject(self, serverData)
    
    self.BodyRoot = nil :: BasePart?
    self.Body = nil :: Model?
    
    self._localRootPart = nil :: BasePart?
    self._bodyRenderer = self:GetState("RootPart").Changed:Connect(self._renderBody, self)
    self._bodyRenderer:Disconnect()
    
    --// Setup Skills
    for category, skillHandler in self.Skills do
        
        local skillName = skillHandler.Name
        
        local keybind = KEYBINDS[skillName] or KEYBINDS[category]
        if not keybind then continue end
        
        local inputHandler = self.skill[skillName] or self.skill[category]
        if not inputHandler then continue end
        
        skillHandler:SetInputHandler(keybind, function(...)
            
            return inputHandler(self,...)
            
        end):Catch("SkillInCooldown", skillInCooldown, self, skillHandler)
    end
    
    return self
end
function Item.prototype:postconstruct()
    
    --// Listeners
    if self.Status == "handled" then self:_handled(self.Owner) end
    self.Unhandled:Connect(self._unhandled, self)
    self.Handled:Connect(self._handled, self)
end

--// Virtual Protected Methods
function Item.prototype:_renderBody(newRootPart: Part?, lastRootPart: Part?)
    
    if lastRootPart then
        
        self.Body = self.Body:Destroy()
        lastRootPart.Parent = nil
        
        if self._localRootPart == lastRootPart then lastRootPart:Destroy() end
    end
    
    if newRootPart then
        
        newRootPart.Transparency = 1.00
        newRootPart.Parent = workspace
        
        local asset = itemModels[self.Name]
        if not asset then return end
        
        local body = asset:Clone()
        body.PrimaryPart.CFrame = newRootPart.CFrame
        body.Parent = newRootPart
        
        self.BodyRoot = body.PrimaryPart
        self.Body = body
        
        self._bodyWeld = create("WeldConstraint", {
            Part0 = self.BodyRoot,
            Part1 = newRootPart,
            Parent = self.BodyRoot,
        })
    end
end

function Item.prototype:_unhandled(handler: Character)
    
    self:_disableBody()
    self:_unweld()
end
function Item.prototype:_handled(handler: Character)
    
    self:_enableBody()
    self:_weldTo(handler.Model.RightHand, self.GripCFrame)
end

--// Protected Methods
function Item.prototype:_getLocalRootPart(): Part
    
    if self._localRootPart then return self._localRootPart end
    
    local rootPartUpdater
    local localRootPart = self:Hoste(create("Part", {
        Name = `local-{self}`,
        Size = Vector3.one,
        CanCollide = false,
        Anchored = false,
        CanTouch = false,
        CollisionGroup = "Items",
    }))
    
    localRootPart.Destroying:Connect(function()
        
        if rootPartUpdater then rootPartUpdater:Destroy() end
        self._localRootPart = nil
    end)
    
    self._localRootPart = localRootPart
    if self.RootPart then
        
        rootPartUpdater = self:GetState("RootPart").Changed:Connect(function(newRootPart)
            
            if newRootPart then return end
            self.RootPart = localRootPart
        end)
    else
        
        self:_setState("RootPart", localRootPart)
    end
    
    return localRootPart
end
function Item.prototype:_getRootPart(): Part
    
    return self.RootPart or self:_getLocalRootPart()
end

function Item.prototype:_weldTo(basePart: BasePart, offset: CFrame|CFrameState?): Weld
    
    _expect(basePart).is("BasePart"):Argument(1, "basePart")
    _expect(offset).is.some("CFrame", "State", "nil"):Argument(2, "offset")
    
    self:_unweld()
    
    local rootPart = self:_getRootPart()
    local weld = create("Weld", {
        Parent = rootPart,
        Part1 = rootPart,
        Part0 = basePart,
        C0 = offset,
    })
    
    self._weld = weld
    return weld
end
function Item.prototype:_unweld()
    
    if not self._weld then return end
    
    self._weld:Destroy()
    self._weld = nil
end

function Item.prototype:_disableBody()
    
    if not self._bodyRenderer.IsConnected then return end
    self._bodyRenderer:Disconnect()
    
    if self.RootPart then self:_renderBody(nil, self.RootPart) end
end
function Item.prototype:_enableBody()
    
    if self._bodyRenderer.IsConnected then return end
    self._bodyRenderer:Reconnect()
    
    if self.RootPart then self:_renderBody(self.RootPart, nil) end
end

--// Behaviour
function Item.prototype:destroying()
    
    self:_disableBody()
end
function Item.prototype:extended(subClass,...)
    
    ServerObject.prototype.extended(self, subClass, "skill",...)
    
    subClass.prototype.skill = table.clone(self.skill)
end

--// Types
local Character: typeof(require(Packages.Client.Classes.Character))
type Character = Character.Character

local Key: typeof(require(Packages.Client.Classes.Device.Key))
type Key = Key.Key

--// End
export type Item = typeof(Item.prototype:constructor()) & ServerObject.ServerObject

return Item.ready() :: typeof(Item)