--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute = Component.create, Component.attribute

local State = require(Packages.Core.State)
local rgb, scale = State.rgb, State.scale

local Components = Packages.Client.Components
local GuiObject = require(Components.GuiObject)

--// Component
local function Container(props): {}
    
    GuiObject(props)
    
    local cornerRadiusEnabled = props.CornerRadius ~= nil
    local aspectRatioEnabled = props.AspectRatio ~= nil
    
    --// Attributes
    props.Color         = attribute(props.Color, rgb(255, 255, 255)) :: State<Color3>
    props.Alpha         = attribute(props.Alpha, 0.00)               :: State<number>
    
    props.CornerRadius  = attribute(props.CornerRadius, nil) :: State<UDim>
    props.AspectRatio   = attribute(props.AspectRatio, nil)  :: State<number>
    props.Stroke        = attribute(props.Stroke, nil)       :: State<UIStroke>
    props.Text          = attribute(props.Text, nil)         :: State<TextContent>
    
    --// Body
    props.BackgroundTransparency    = props.Alpha
    props.BackgroundColor3          = props.Color
    props.BorderSizePixel           = 0
    
    --// Children
    return {
        if aspectRatioEnabled then create("UIAspectRatioConstraint", { AspectRatio = props.AspectRatio }) else nil,
        if cornerRadiusEnabled then create("UICorner", { CornerRadius = props.CornerRadius }) else nil,
        props.Stroke,
        props.Text,
    }
end

--// End
return Container