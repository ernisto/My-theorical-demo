--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute, getState = Component.create, Component.attribute, Component.getState

local State = require(Packages.Core.State)
local rgb, pixel, scale, vector, lowest = State.rgb, State.pixel, State.scale, State.vector, State.lowest
local computed, newState = State.computed, State.new

--// Component
local function Stroke(props): UIStroke|Frame
    
    Component(props)
    
    local paddingEnabled = props.Padding ~= nil
    
    --// Data
    local basePixels = newState(0)
    local parentCornerRadius = newState(pixel(0))
    local connection1, connection2
    
    function props._changed:Parent(parent)
        
        if connection1 then connection1:Disconnect() end
        if connection2 then connection2:Disconnect() end
        
        if not parent then return end
        local parentAbsoluteSize = getState(parent, "AbsoluteSize")
        connection1 = lowest(parentAbsoluteSize.X, parentAbsoluteSize.Y):Bind(basePixels)
        
        if not paddingEnabled then return end
        connection2 = getState(parent, "CornerRadius"):Bind(parentCornerRadius)
    end
    
    --// Attributes
    props.Color     = attribute(props.Color, rgb(0, 0, 0))  :: State<Color3>
    props.Thickness = attribute(props.Thickness, pixel(0))  :: State<UDim>
    props.Padding   = attribute(props.Padding, pixel(0))    :: State<UDim>
    props.Alpha     = attribute(props.Alpha, 0.00)          :: State<number>
    
    --// Body
    props.Thickness = props.Thickness.Offset + props.Thickness.Scale*basePixels
    
    if paddingEnabled then
        
        props.BackgroundTransparency = 1.00
        props.AnchorPoint   = vector(0.50, 0.50)
        props.Position      = scale(0.50, 0.50)
        props.Size          = scale(1.00, 1.00) + computed(props.Padding, basePixels, function(padding, pixels)
            
            local doubleAbsolutePadding = padding.Scale*pixels*2 + padding.Offset*2
            
            return UDim2.fromOffset(doubleAbsolutePadding, doubleAbsolutePadding)
        end)
        
        return create("Frame", props,
        {
            create("UIStroke", {
                Thickness       = props.Thickness,
                Transparency    = props.Alpha,
                Color           = props.Color,
            }),
            create("UICorner", {
                CornerRadius = pixel(
                    parentCornerRadius.Offset + parentCornerRadius.Scale*basePixels
                    + props.Padding.Offset + props.Padding.Scale*basePixels
                )
            }),
        })
    else
        
        props.Transparency = props.Alpha
        return create("UIStroke", props)
    end
end

--// End
return Stroke