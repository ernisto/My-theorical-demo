--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local StarterGui = game:GetService("StarterGui")

local localPlayer = require(Packages.Client.Classes.Player).awaitLocalPlayer()
local Interface = require(Packages.Client.Interface)

local State = require(Packages.Core.State)
local rgb, scale, pixel, vector = State.rgb, State.scale, State.pixel, State.vector
local deg = State.deg

local Components = Packages.Client.Components
local stroke = require(Components.Stroke)
local Frame = require(Components.Frame)
local text = require(Components.Text)

--// Class
local TopbarInterface = Package.class("TopbarInterface").extends(Interface)

--// Setup
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

--// Class Functions
function TopbarInterface.body(displayer)
    
    Frame "EscBorder" { Parent = displayer,
        
        AnchorPoint     = vector(0.50, 0.50),
        Position        = pixel(32, 20),
        Size            = pixel(26, 26),
        Color           = rgb(0, 0, 0),
        CornerRadius    = pixel(6),
        Rotation        = deg(15),
    }
    
    Frame "ChatBorder" ({ Parent = displayer,
        
        CornerRadius = pixel(10),
        Position = pixel(63, 7),
        Size = pixel(26, 26),
        Color = rgb(0, 0, 0),
    }, {
        Frame "LeftBottomCorner" {
            
            Position = scale(0.00, 0.50),
            Size     = scale(0.50, 0.50),
            Color    = rgb(0, 0, 0),
        }
    })
    
    Frame "PlayerName" { Parent = displayer,
        
        AutomaticSize   = Enum.AutomaticSize.X,
        CornerRadius    = pixel(8),
        Position        = pixel(105, 4),
        Size            = pixel(50, 32),
        Color           = rgb(0, 0, 0),
        Alpha           = 0.55,
        
        Text = text("@%s", localPlayer.Name) {
            
            Font        = Enum.Font.FredokaOne,
            Color       = rgb(255, 255, 255),
            TextSize    = scale(0.66),
            
            AutomaticSize   = Enum.AutomaticSize.X,
            Position        = pixel(10, 0),
            
            Stroke = stroke {
                Thickness  = scale(0.10),
                Color      = rgb(0, 0, 0),
            }
        }
    }
end

--// End
return TopbarInterface