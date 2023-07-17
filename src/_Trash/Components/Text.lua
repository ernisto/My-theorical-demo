--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute, getState = Component.create, Component.attribute, Component.getState

local State = require(Packages.Core.State)
local rgb, scale, vector, string = State.rgb, State.scale, State.vector, State.string
local computed, newState = State.computed, State.new

local Components = Packages.Client.Components
local GuiObject = require(Components.GuiObject)

--// Component
local function Text(props,...): TextLabel
    
    GuiObject(props)
    
    --// Attributes
    --! AUTOMATIC SIZE COMING SOON
    --props.LinesRange            = attribute(props.LinesRange, NumberRange.new(1))   :: State<NumberRange>
    --props.Wrapped               = attribute(props.Wrapped, false)                   :: State<boolean>
    props.TextSizeConstraint    = attribute(props.TextSizeConstraint, "Y")          :: State<"X"|"Y">
    props.Alignment             = attribute(props.Alignment, vector(-1, 0))         :: State<Vector2>
    props.TextSize              = attribute(props.TextSize, scale(1.00))            :: State<UDim>
    props.Color                 = attribute(props.Color, rgb(0, 0, 0))              :: State<Color3>
    props.Alpha                 = attribute(props.Alpha, 0.00)                      :: State<number>
    props.Stroke                = attribute(props.Stroke, nil)                      :: State<UIStroke>
    
    --// Body
    local alignment = props.Alignment.Value
    props.TextXAlignment = if alignment.X > 0 then Enum.TextXAlignment.Right elseif alignment.X < 0 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
    props.TextYAlignment = if alignment.Y > 0 then Enum.TextYAlignment.Bottom elseif alignment.Y < 0 then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
    
    props.TextSize                  = props.TextSize.Offset + props.AbsoluteSize[props.TextSizeConstraint.Value]*props.TextSize.Scale
    props.TextTransparency          = props.Alpha
    props.TextColor3                = props.Color
    props.TextWrapped               = false
    props.TextScaled                = false
    props.BackgroundTransparency    = 1.00
    
    if props.RichText and props.Stroke then
        
        local richText = newState()
        local text = props.Text
        local updater
        
        props.Stroke:Updater(function(stroke)
            
            if updater then updater:Disconnect() end
            
            if stroke then
                
                local thickness = getState(stroke, "Thickness")
                local alpha = getState(stroke, "Transparency")
                local color = getState(stroke, "Color")
                
                updater = string("<stroke color=\"#%X%X%X\" thickness=\"%s\" transparency=\"%s\">%s</stroke>", color.R, color.G, color.B, thickness, alpha, text)
                    :Bind(richText)
            else
                
                updater = text:Bind(richText)
            end
        end)
        props.Text = richText
    end
    
    return create("TextLabel", props, { props.Stroke })
end

--// End
return function(text: string,...: any)
    
    text = string(text,...)
    
    return function(props)
        
        props.Text = text
        return Text(props)
    end
end