--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local Item = require(Packages.Client.Classes.Item)

--// Class
local Droppable = Package.class("Droppable").extends(ServerObject, Item)
:: ServerObject.Class<Droppable>

--// Constructor
function Droppable.prototype:constructor()
    
    --// Instance
    self._dropRenderer = nil :: thread?
    
    return self
end
function Droppable.prototype:postconstruct()
    
    --// Listeners
    if self.Status == "dropped" then self:_dropped() end
    self.Dropped:Connect(self._dropped, self)
    self.Picked:Connect(self._picked, self)
end

--// Skills
function Droppable.prototype.skill:Drop(skill)

    skill.InputReleased:Await()
    skill:ReleaseRemote()
end

--// Virtual Protected Methods
function Droppable.prototype:_dropped()
    
    self:_enableBody()
    
    --// Loop
    self._dropRenderer = task.spawn(function()
        
        self._bodyWeld.Enabled = false
        
        while true do
            
            local rootPart = self.RootPart
            if not rootPart then self:GetState("RootPart").Changed:Wait() continue end
            
            local body = self.Body
            if not body then self:GetState("Body").Changed:Wait() continue end
            
            local dropPosition = rootPart.Position
            local sineWave = Vector3.new(0, 1 + math.sin(os.clock()), 0)
            
            body.PrimaryPart.CFrame = CFrame.new(dropPosition + sineWave) * CFrame.Angles(0, os.clock() / 2, 0)
            task.wait()
        end
    end)
end
function Droppable.prototype:_picked(owner)
    
    if self._dropRenderer then task.cancel(self._dropRenderer) end
    self:_disableBody()
end

--// End
export type Droppable = Package.Object

return Droppable.ready() :: typeof(Droppable)