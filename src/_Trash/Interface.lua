--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local newAnimation = require(Packages.Libraries.Animation).new

--// Class
local Interface = Package.class("Interface")

--// Consts
local WHITE1 = Color3.fromRGB(255, 255, 255)
local WHITE2 = Color3.fromRGB(211, 208, 232)
local WHITE3 = Color3.fromRGB(175, 167, 209)

local BLACK1 = Color3.fromRGB(44, 4, 48)
local BLACK2 = Color3.fromRGB(59, 14, 71)
local BLACK3 = Color3.fromRGB(74, 28, 94)

--// Vars
local themeAnimation = newAnimation()
local interfaces = {}

--// Class Vars
Interface.theme = {
    PositiveColor = Color3.fromRGB(50, 255, 70),
    Black1 = BLACK1,
    Black2 = BLACK2,
    Black3 = BLACK3,
    White1 = WHITE1,
    White2 = WHITE2,
    White3 = WHITE3,
    
    BackColor1 = (themeAnimation:At(0)
        :from ( WHITE1 )
        :to   ( BLACK1 )
        :with { Duration = .3 }
    ),
    BackColor2 = (themeAnimation:At(0)
        :from ( WHITE2 )
        :to   ( BLACK2 )
        :with { Duration = .3 }
    ),
    BackColor3 = (themeAnimation:At(0)
        :from ( WHITE3 )
        :to   ( BLACK3 )
        :with { Duration = .3 }
    ),
    TextColor1 = (themeAnimation:At(0)
        :from ( BLACK1 )
        :to   ( WHITE1 )
        :with { Duration = .3 }
    ),
    TextColor2 = (themeAnimation:At(0)
        :from ( BLACK2 )
        :to   ( WHITE2 )
        :with { Duration = .3 }
    ),
    TextColor3 = (themeAnimation:At(0)
        :from ( WHITE3 )
        :to   ( BLACK3 )
        :with { Duration = .3 }
    ),
}

--// Class Functions
function Interface.setDarkMode(darkMode: boolean): ()
    
    if themeAnimation.Reversing == darkMode then return end
    
    themeAnimation:ResumeAsync(0, nil, not darkMode)
end

--// Behaviour
function Interface:running()
    
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local displayer = Instance.new("ScreenGui")
    displayer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    displayer.IgnoreGuiInset = true
    displayer.ResetOnSpawn = false
    displayer.Name = "Displayer"
    displayer.Parent = playerGui
    
    for _,interface in interfaces do
        
        interface.body(displayer)
    end
end

--// Methods
function Interface.prototype:extended(interfaceClass)
    
    interfaces[interfaceClass:GetType()] = interfaceClass
end

--// End
return Interface