--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local ItemStatus = require(script.Parent).ItemStatus
local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local getPlayer = require(Packages.Server.Classes.Player).getPlayer

--// Const
local PICKUP_RANGE = 5

--// Class
local Droppable = Package.class("Droppable").extends(RemoteObject)
:: RemoteObject.Class<Droppable>

--// Constructor
function Droppable.prototype:constructor()
    
    self:_setSkill("Drop", "Drop", self._dropSkill)
    
    return self
end

--// Signals
function Droppable.prototype.client.signal.Dropping(cframe: CFrame, whitelist: {Player}) end
function Droppable.prototype.client.signal.Dropped(cframe: CFrame, whitelist: {Player}) end
function Droppable.prototype.client.signal.Picking(newOwner: Character) end
function Droppable.prototype.client.signal.Picked(newOwner: Character) end

--// Skills Methods
function Droppable.prototype:_dropSkill(skill)
    
    skill:DeferApprove()
    skill.Released:Await()
    
    self:Drop()
end

--// Methods
function Droppable.prototype:Drop(cframe: CFrame|Vector3, whitelist: {Player}?)
    
    cframe = cframe or if self.Owner then self.Owner.RootPart.CFrame * CFrame.new(0, 0, -1) elseif self.RootPart then self.RootPart.CFrame else Vector3.new(0, 10, 0)
    cframe = if typeof(cframe) == "Vector3" then CFrame.lookAt(cframe, cframe + Vector3.yAxis) else cframe
    
    _expect(cframe).is.some("CFrame", "Vector3"):Argument(1, "cframe")
    
    self.Dropping(cframe, whitelist)
    self:_drop(cframe, whitelist)
    self.Dropped(cframe, whitelist)
end

--// Virtual Protected Methods
function Droppable.prototype:_drop(cframe: CFrame, whitelist: {Player}?)
    
    self:_setOwner(nil)
    self:_setStatus(ItemStatus.Dropped)
        .Changed:Once(self._picking, self)
    
    if whitelist then
        
        _expect(whitelist).all.index.is("integer"):Argument(2, "whitelist")
        _expect(whitelist).all.value.is("Player"):Argument(2, "whitelist")
        
        self.client:SetPlayers(whitelist)
    else
        
        self.client:AddEveryone()
    end
    
    local rootPart = self:_enableRootPart()
    rootPart.CanCollide = true
    rootPart.CFrame = cframe
    rootPart:ApplyImpulse(cframe.LookVector * 10)
    
    local pickupPrompt = Instance.new("ProximityPrompt", rootPart)
    pickupPrompt.MaxActivationDistance = PICKUP_RANGE
    pickupPrompt.ObjectText = self.Name
    pickupPrompt.ActionText = "Pickup"
    
    pickupPrompt.Triggered:Connect(function(rPlayer)
        
        local player = getPlayer(rPlayer)
        local character = expect(player.Character, `Character not spawned`)
        expect((character.RootPart.Position - self.RootPart.Position).Magnitude < PICKUP_RANGE, `So far to pick up item`)
        
        character:EquipItem(self)
        pickupPrompt:Destroy()
    end)
end
function Droppable.prototype:_pick(newOwner: Character)
    
    self:_disableRootPart()
end

--// Private Methods
function Droppable.prototype:_picking()
    
    local newOwner = self.Owner
    if not newOwner then return end
    
    self.Picking(newOwner)
    self:_pick(newOwner)
    self.Picked(newOwner)
end

--// End
export type Droppable = typeof(Droppable.prototype:constructor()) & RemoteObject.RemoteObject & {
    Dropping: Signal<(cframe: CFrame, whitelist: {Player})->()>,
    Dropped: Signal<(cframe: CFrame, whitelist: {Player})->()>,
    Picking: Signal<(newOwner: Character)->()>,
    Picked: Signal<(newOwner: Character)->()>,
}

return Droppable