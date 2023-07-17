--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local localPlayer = require(Packages.Client.Classes.Player).awaitLocalPlayer()

local Interface = require(Packages.Client.Interface)
local theme = Interface.theme

local newTweenState = require(Packages.Libraries.TweenState).new
local newAnimation = require(Packages.Libraries.Animation).new
local style = require(Packages.Libraries._Tween.Styles)

local newSignal = require(Packages.Core.Signal).new
local State = require(Packages.Core.State)
local scale, vector = State.scale, State.vector
local newState = State.new

local Components = Packages.Client.Components
local stroke = require(Components.Stroke)
local Frame = require(Components.Frame)
local List = require(Components.List)
local text = require(Components.Text)

--// Class
local PartyInterface = Package.class("PartyInterface").extends(Interface)

--// Vars
local partyMembersCount = newState(0)

--// Signals
function PartyInterface.signal._putMemberFrame(player: Player, destroySignal)
    
    local displayName = player.DisplayName
    local showAnimation = newAnimation()
    showAnimation:ResumeAsync()
    
    return Frame (displayName) ({
        Alpha = 1.00,
        
        SizeConstraint  = Enum.SizeConstraint.RelativeXX,
        Size            = (showAnimation:At(0)
            :from ( scale(0.50, 0.00) )
            :to   ( scale(1.00, 0.10) )
            :with { Duration = .15, Style = style.OutCubic }
        ),
        
        Destroy = destroySignal,
        _method = {
            Destroy = function(self)
                
                showAnimation:ResumeAsync(0, 1, true):Then(self.Destroy, self):Catch("PromiseCancelledException")
            end
        }
    }, {
        Frame "Frame" {
            SizeConstraint  = Enum.SizeConstraint.RelativeXX,
            Size            = scale(1.00, 0.10),
            CornerRadius    = scale(0.50),
            Alpha           = (showAnimation:At(0)
                :from ( 1.00 )
                :to   ( 0.00 )
                :with { Duration = .15, Style = style.OutCubic }
            ),
            
            Text = text("%s", displayName) {
                
                Font     = Enum.Font.FredokaOne,
                Color    = theme.TextColor1,
                TextSize = scale(0.80),
                XPadding = scale(0.05),
                Alpha    = (showAnimation:At(0)
                    :from ( 1.00 )
                    :to   ( 0.00 )
                    :with { Duration = .15, Style = style.OutCubic }
                ),
            },
            
            Stroke = stroke {
                Thickness  = scale(1/7),
                Color      = theme.TextColor1,
                Alpha      = (showAnimation:At(0)
                    :from ( 1.00 )
                    :to   ( 0.00 )
                    :with { Duration = .15, Style = style.OutCubic }
                ),
            },
        }
    })
end

--// Class Functions
function PartyInterface.body(displayer)
    
    Frame "PartyHUD" ({ Parent = displayer,
        
        AnchorPosition  = vector(0.00, 0.50),
        Size            = scale(0.30, 0.30),
        Alpha           = 1.00,
        AspectRatio     = 1/1,
        
        Text = text("Party") {
            Font            = Enum.Font.FredokaOne,
            Color           = theme.BackColor1,
            BottomPadding   = scale(0.90),
            XPadding        = scale(0.05),
            
            Stroke = stroke {
                Thickness   = scale(0.15),
                Color       = theme.Black1,
            }
        },
    }, {
        text("%i/5", partyMembersCount) {
            
            Font            = Enum.Font.FredokaOne,
            Color           = theme.BackColor1,
            Alignment       = vector(1, 0),
            BottomPadding   = scale(0.90),
            XPadding        = scale(0.05),
            
            Stroke = stroke {
                Thickness  = scale(0.15),
                Color      = theme.Black1,
            }
        },
        Frame "Line" {
            Color           = theme.BackColor1,
            YPadding        = scale(0.14, 0.845),
            XPadding        = scale(0.05),
            CornerRadius    = scale(0.50),
            
            Stroke = stroke {
                Thickness   = scale(1.00),
                Color       = theme.Black1,
            }
        },
        List "Members" ({
            ElementsPadding = scale(0.05),
            TopPadding      = scale(0.20),
            XPadding        = scale(0.05),
            Alignment       = vector(0, 1),
            Alpha           = 1.00,
            
            Put = PartyInterface._putMemberFrame,
        }, {
            Frame "Invite" {
                Size            = scale(1.00, 0.10),
                CornerRadius    = scale(0.50),
                Alpha           = 0.35,
                LayoutOrder     = 2,
                
                Text = text "Invite" {
                    Font     = Enum.Font.FredokaOne,
                    Color    = theme.TextColor1,
                    TextSize = scale(0.80),
                    XPadding = scale(0.05),
                    Alpha    = 0.35,
                },
                
                Stroke = stroke {
                    Thickness   = scale(1/7),
                    Color       = theme.Black1,
                    Alpha       = 0.35,
                },
            }
        })
    })
end

--// Listeners
local destroyers = {}

localPlayer:GetState("Party").Changed:Connect(function(party)
    
    if party then
        
        local function renderMember(member)
            
            local destroyer = newSignal()
            destroyers[destroyer] = true
            
            member:GetState("Party").Changed:Once(function()
                
                destroyers[destroyer] = nil
                destroyer()
            end)
            
            PartyInterface._putMemberFrame(member, destroyer)
        end
        
        party.MemberRemoved:Connect(partyMembersCount.Decrease, partyMembersCount, 1, nil)
        party.MemberAdded:Connect(partyMembersCount.Increase, partyMembersCount, 1, nil)
        party.MemberAdded:Connect(renderMember)
        
        for _,member in party.Members do
            
            renderMember(member)
        end
        partyMembersCount:Set(#party.Members)
    else
        
        for destroyer in destroyers do destroyer() end
        partyMembersCount:Set(0)
    end
end)

--// End
return PartyInterface