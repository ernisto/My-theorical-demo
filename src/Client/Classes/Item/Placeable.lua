--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local Droppable = require(Packages.Client.Classes.Item.Droppable)
local Mouse = require(Packages.Client.Classes.Device.Mouse)
local Item = require(Packages.Client.Classes.Item)

local _expect = require(Packages.Core.Expectation).new

--// Class
local Placeable = Package.class("Placeable").extends(ServerObject, Item, Droppable)
:: ServerObject.Class<Placeable>

--// Vars
local focusedItem: Item?, focusedCFrame: CFrame, focusedDistance: number
local placeables = setmetatable({}, { __mode = "k" })
local placeableRootParts = {}

--// Behaviour
function Placeable:start()
    
    local lastItem
    
    while true do
        
        local rootPart
        rootPart, focusedCFrame, focusedDistance = Mouse:RaycastWhitelist(500, placeableRootParts)
        focusedItem = placeables[rootPart]
        
        if focusedItem ~= lastItem then
            
            if lastItem and not lastItem.IsDestroyed then
                
                lastItem:_unfocused()
                lastItem.IsFocused = false
            end
            if focusedItem then
                
                focusedItem:_focused()
                focusedItem.IsFocused = true
            end
        end
        
        lastItem = focusedItem
        task.wait()
    end
end

--// Class Functions
function Placeable.getFocusedItem(): (Placeable?, CFrame?, number?)
    
    if not focusedItem then return end
    return focusedItem, focusedCFrame, focusedDistance
end
function Placeable.getItemFromRootPart(rootPart: Part): Placeable?
    
    _expect(rootPart).is("Part"):Argument(1, "rootPart")
    
    return placeables[rootPart]
end

--// Constructor
function Placeable.prototype:constructor(serverData)
    
    --// Instance
    Item(self, serverData)
    Droppable(self)
    
    self._placedActions = {}
    return self
end
function Placeable.prototype:postconstruct()
    
    --// Listeners
    self:GetState("RootPart"):Updater(self._rootPartChanged, self)
    
    if self.Status == "placed" then self:_placed(self.Surface) end
    self.Removed:Connect(self._removed, self)
    self.Placed:Connect(self._placed, self)
end

--// Skills
function Placeable.prototype.skill:Place(skill: Skill)
    
    warn("not done yet")
    skill:Release()
end

--// Override Protected Methods
function Placeable.prototype:_dropped()
    
    self:_enableBody()
end

--// Virtual Protected Methods
function Placeable.prototype:_unfocused()
end
function Placeable.prototype:_focused()
end

function Placeable.prototype:_removed()
    
    self:_disableBody()
end
function Placeable.prototype:_placed(surface: Placeable)
    
    self:_enableBody()
end

--// Private Methods
function Placeable.prototype:_rootPartChanged(newRootPart, lastRootPart)
    
    if lastRootPart then
        
        local index = table.find(placeableRootParts, lastRootPart)
        placeables[lastRootPart] = nil
        
        if newRootPart then
            
            if index then
                
                placeableRootParts[index] = newRootPart
            else
                
                table.insert(placeableRootParts, newRootPart)
            end
            placeables[newRootPart] = self
            
        elseif index then
            
            table.remove(placeableRootParts, index)
        end
    else
        
        if newRootPart then
            
            table.insert(placeableRootParts, newRootPart)
            placeables[newRootPart] = self
        end
    end
end

--// Behaviour
function Placeable.prototype:destroying()
    
    if self.IsFocused then self:_unfocused() focusedItem = nil end
    Item.destroying(self)
end

--// End
export type Placeable = Package.Object

return Placeable.ready() :: typeof(Placeable)