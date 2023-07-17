--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Keyboard = require(Packages.Client.Classes.Device.Keyboard)

local Interface = require(Packages.Client.Interface)
local theme = Interface.theme

local newAnimation = require(Packages.Libraries.Animation).new
local style = require(Packages.Libraries._Tween.Styles)

local State = require(Packages.Core.State)
local scale, vector = State.scale, State.vector

local Components = Packages.Client.Components
local stroke = require(Components.Stroke)
local Frame = require(Components.Frame)

--// Class
local InventoryInterface = Package.class("InventoryInterface").extends(Interface)

--// Vars
local openAnimation = newAnimation()
local opened = false

--// Class Behaviour
function InventoryInterface:running()
    
    Keyboard.Keys.B.Holded:Connect(function(engineProcessed)
        
        if engineProcessed then return end
        if opened then InventoryInterface.close() else InventoryInterface.open() end
    end)
end

--// Class Functions
function InventoryInterface.open()
    
    if opened then return end
    
    openAnimation:ResumeAsync(0, nil, false):Await()
    opened = true
end
function InventoryInterface.close()
    
    if not opened then return end
    
    openAnimation:ResumeAsync(0, nil, true):Await()
    opened = false
end

function InventoryInterface.body(displayer)
end

--// End
return InventoryInterface