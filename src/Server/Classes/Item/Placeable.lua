--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Droppable = require(script.Parent.Droppable)
local Item = require(script.Parent)
local ItemStatus = Item.ItemStatus

local State = require(Packages.Core.State)
local computed = State.computed
local cframe = State.cframe

local Component = require(Packages.Libraries.Component)
local getPropertyState = Component.getState

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new
local isA = Package.IsA

--// Class
local Placeable = Package.class("Placeable").extends(RemoteObject, Item, Droppable)
:: RemoteObject.Class<Placeable>

--// Vars
local placeables = {}
local rootParts = {}

Placeable.world = nil :: Placeable

--// Consts
local QUERY_ROOTPARTS_RAYCAST_PARAM = RaycastParams.new()
QUERY_ROOTPARTS_RAYCAST_PARAM.FilterDescendantsInstances = rootParts
QUERY_ROOTPARTS_RAYCAST_PARAM.FilterType = Enum.RaycastFilterType.Blacklist

--// Functions
local function roundCFrame(cframe: CFrame, precision: number): CFrame
    
    --// Round LookVector
    local lookVector = cframe.LookVector
    local lookX = math.abs(lookVector.X)
    local lookY = math.abs(lookVector.Y)
    local lookZ = math.abs(lookVector.Z)
    
    if (lookX > lookY and lookX > lookZ) then
        
        lookVector = Vector3.new(lookVector.X, 0, 0)
        
    elseif (lookY > lookX and lookY > lookZ) then
        
        lookVector = Vector3.new(0, lookVector.Y, 0)
    else
        
        lookVector = Vector3.new(0, 0, lookVector.Z)
    end
    
    --// Round Position
    local position = Vector3.new(
        math.round(cframe.X/precision)*precision,
        math.round(cframe.Y/precision)*precision,
        math.round(cframe.Z/precision)*precision
    )
    
    --// End
    return CFrame.new(position, position + lookVector)
end

--// Abstract Constructor
function Placeable.prototype:constructor()
    
    --// Instance
    Item(self)
    Droppable(self)
    
    self.TwoHanded = true
    self.client.Surface = nil :: Placeable?
    
    self._computedHeight = State.new(0)
    
    --// Skills
    self:_setSkill("Skill1", "Place", self._placeSkill)
    
    --// Listeners
    self:GetState("RootPart").Changed:Connect(self._rootPartChanged, self)
    return self
end

--// Remote Signals
function Placeable.prototype.client.signal.Removing(surface: Placeable, offset: CFrame) end
function Placeable.prototype.client.signal.Removed(surface: Placeable, offset: CFrame) end
function Placeable.prototype.client.signal.Placing(surface: Placeable, offset: CFrame) end
function Placeable.prototype.client.signal.Placed(surface: Placeable, offset: CFrame) end

--// Skills
function Placeable.prototype:_placeSkill(skill: Skill)
    
    skill:Approve()
    
    local surface: Placeable, origin: CFrame = skill.Released:Await()
    if not surface then return end
    
    expect(isA(surface, "Placeable"), `Argument #1 (surface) must to be a Placeable, got %t({surface})`, surface)
    expect(surface.Status == "placed" or surface.Status == "dropped", `Surface must to be placed or dropped`)
    expect(isA(origin, "CFrame"), `Argument #2 (origin) must to be a CFrame, got %t({cframe})`, cframe)
    
    local offset = surface.RootPart.CFrame:ToObjectSpace(origin)
    local surfaceSize = surface.RootPart.Size
    
    expect(offset.X <= surfaceSize.X and offset.Y <= surfaceSize.Y and offset.Z <= surfaceSize.Z, `Place position so far from surface`)
    
    self:PlaceToOrigin(surface, origin)
end

--// Methods
function Placeable.prototype:PlaceOriginTo(surface: Placeable?, origin: CFrame)
    
    surface = surface or Placeable.world
    
    _expect(surface).is("Placeable"):Argument(1, "surface")
    _expect(origin).is("CFrame"):Argument(2, "cframe")
    
    local surfaceRootPart = surface.RootPart
    local offset = roundCFrame(surfaceRootPart.CFrame:ToObjectSpace(origin), .5)
    
    local computedSurfaceSize = getPropertyState(surfaceRootPart, "Size")
    local computedDeltaSurfaceSize = computedSurfaceSize * (offset.LookVector/2)
                                  - surfaceRootPart.Size * (offset.LookVector/2)
    
    self:WeldedPlaceTo(surface,
        computed(CFrame.new, computedDeltaSurfaceSize)
        * offset
        * cframe(0, self._computedHeight, 0)
    )
end
function Placeable.prototype:WeldedPlaceTo(surface: Placeable?, offset: CFrame|CFrameState)
    
    surface = surface or Placeable.world
    
    _expect(surface).is("Placeable"):Argument(1, "surface")
    _expect(offset).is.some("CFrame", "State"):Argument(2, "origin")
    
    self.Placing(surface, offset)
    self:_placeTo(surface, offset)
    self.Placed(surface, offset)
end
function Placeable.prototype:GetOriginWorldCFrame(): CFrame
    
    if not self.RootPart then return end
    return self.RootPart.CFrame * CFrame.new(0, -self.RootPart.Size.Y/2, 0)
end

--// Virtual Protected Methods
function Placeable.prototype:_placeTo(surface: Placeable, offset: CFrame|CFrameState)
    
    self:_setOwner(nil)
    self:_setStatus(ItemStatus.Placed)
    .Changed:Once(self._removing, self)
    
    self.client:AddEveryone()
    self:_setState("Surface", surface)
    
    self:_enableRootPart()
    self:_weldTo(surface.RootPart, offset)
end
function Placeable.prototype:_remove()
    
    self:_setState("Surface", nil)
    self:_disableRootPart()
end

--// Override Protected Methods
function Placeable.prototype:_drop(cframe, whitelist)
    
    self:_unweld()
    Droppable._drop(self, cframe, whitelist)
end
function Placeable.prototype:_unweld()
    
    Item._unweld(self)
    self:_setState("Surface", nil)
end

--// Private Methods
function Placeable.prototype:_rootPartChanged(newRootPart, lastRootPart)
    
    if newRootPart then
        
        getPropertyState(newRootPart, "Size"):Updater(function(size: Vector3)
            
            self._computedHeight:Set(size.Y/2)
        end)
        
        table.insert(rootParts, newRootPart)
    else
        
        self:_unweld()
        
        local index = table.find(rootParts, lastRootPart)
        if index then table.remove(rootParts, index) end
    end
end
function Placeable.prototype:_removing()
    
    self.Removing()
    self:_remove()
    self.Removed()
end

--// Behaviour
function Placeable.prototype:destroying()
    
    self:_removing()
end

--// Setup
local world = Placeable.new()
world:_setStatus(ItemStatus.Placed)
world:_enableRootPart()
world.RootPart.Anchored = true

Placeable.world = world

--// End
type CFrameState = State.CFrameState

export type Placeable = typeof(Placeable.prototype:constructor()) & Item.Item & Droppable.Droppable & {
    Removing: Signal<(surface: Placeable, origin: CFrame)->()>,
    Removed: Signal<(surface: Placeable, origin: CFrame)->()>,
    Placing: Signal<(surface: Placeable, origin: CFrame)->()>,
    Placed: Signal<(surface: Placeable, origin: CFrame)->()>,
}

return Placeable