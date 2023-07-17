--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)

local Item = require(Packages.Client.Classes.Item)
local Droppable = require(script.Parent.Parent.Droppable)
local Weapon = require(script.Parent.Weapon)

local getFocusedItem = require(Packages.Client.Classes.Item.Placeable).getFocusedItem

--// Class
local Axe = Package.class("Axe").extends(ServerObject, Item, Weapon, Droppable)
:: Package.Class<Axe>

--// Constructor
function Axe.prototype:constructor(serverData)
    
    --// Instance
    Item(self, serverData)
    Droppable(self)
    Weapon(self)
    
    return self
end

--// Skill Methods
function Axe.prototype.skill:Divise(skill)
    
    --// Hold
    local branch, render, unfocus
    
    --// Render
    while skill:IsClientHolding() do
        
        local newBranch, cframe = getFocusedItem()
        newBranch = if newBranch and newBranch:IsA("Branch") then newBranch else nil
        
        if branch ~= newBranch then
            
            if unfocus then unfocus() end
            unfocus, render = nil, nil
            
            if newBranch then unfocus, render = newBranch:FocusDivising() end
        end
        
        if render and cframe then
            
            render(cframe)
        end
        
        branch = newBranch
        task.wait()
    end
    
    --// Release
    skill:ReleaseRemote(branch)
    if branch then unfocus() end
end
function Axe.prototype.skill:Chop(skill)
    
    --// Hold
    local branch, render, unfocus, cutHeight, direction
    
    --// Render
    while skill:IsClientHolding() do
        
        local newBranch, cframe = getFocusedItem()
        newBranch = if newBranch and newBranch:IsA("Branch") then newBranch else nil
        
        if branch ~= newBranch then
            
            if unfocus then unfocus() end
            unfocus, render = nil, nil
            
            if newBranch then unfocus, render = newBranch:FocusChopping() end
        end
        
        if render and cframe then
            
            cutHeight = render(cframe)
            direction = cframe.LookVector
        end
        
        branch = newBranch
        task.wait()
    end
    
    --// Release
    skill:ReleaseRemote(branch, cutHeight, direction)
    if branch then unfocus() end
end

--// End
export type Axe = typeof(Axe.prototype:constructor()) & Item.Item & Weapon.Weapon & ServerObject.ServerObject

return Axe.ready() :: typeof(Axe)