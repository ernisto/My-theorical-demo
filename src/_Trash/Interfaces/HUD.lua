--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local localPlayer = require(Packages.Client.Classes.Player).awaitLocalPlayer()

local Interface = require(Packages.Client.Interface)
local theme = Interface.theme

local newAnimation = require(Packages.Libraries.Animation).new
local style = require(Packages.Libraries._Tween.Styles)

local State = require(Packages.Core.State)
local rgb, scale, vector = State.rgb, State.scale, State.vector
local computed = State.computed
local newState = State.new

local Components = Packages.Client.Components
local stroke = require(Components.Stroke)
local Frame = require(Components.Frame)
local text = require(Components.Text)

--// Class
local HUD = Package.class("HUDInterface").extends(Interface)

--// Vars
local handlingItem = newState(nil)

--// Class Functions
function HUD.body(displayer)
    
    Frame "HandlingItem" ({ Parent = displayer,
        
        AnchorPosition  = vector(1.00, 1.00),
        Size            = scale(0.15, 0.15),
        Alpha           = 1.00,
        AspectRatio     = 1/1,
    }, {
        Frame "Back" ({
            
            AnchorPosition  = vector(0.50, 0.50),
            Size            = scale(0.80, 0.80),
            CornerRadius    = scale(0.50),
            Color           = theme.BackColor1,
            
            Stroke = stroke {
                Thickness  = scale(0.05),
            }
        }, {
            Frame "IconBack" ({
                
                AnchorPosition  = vector(0.50, 0.50),
                Size            = scale(0.60, 0.60),
                CornerRadius    = scale(0.60),
                Color           = theme.BackColor2,
                
                Text = text("%i", 99) {
                    Font            = Enum.Font.FredokaOne,
                    AnchorPoint     = vector(0.50, 1.00),
                    Position        = scale(1.00, 1.15),
                    Size            = scale(1.00, 0.50),
                    Color           = theme.BackColor1,
                    Alignment       = vector(0, 0),
                    
                    Stroke = stroke {
                        Color       = theme.TextColor1,
                        Thickness   = scale(0.15),
                    }
                }
            })
        })
    })
    
    --// Listeners
    localPlayer:GetState("Character"):Updater(function(character)
        
        if not character then return end
        
        character:GetState("Item"):Updater(handlingItem.Set, handlingItem)
    end)
end

--// End
return HUD