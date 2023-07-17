--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute = Component.create, Component.attribute

local State = require(Packages.Core.State)
local udim2, scale, vector = State.udim2, State.scale, State.vector
local newState = State.new

--// Component
local function GuiObject(props): {}
    
    Component(props)
    
    local anchorPositionEnabled = props.AnchorPosition
    local padding = props.Padding
    
    if padding then
        
        if typeof(padding.Value) == "UDim2" then
            
            props.RightPadding = padding.X
            props.LeftPadding = padding.X
            props.BottomPadding = padding.Y
            props.TopPadding = padding.Y
            
        elseif typeof(padding.Value) == "UDim" then
            
            props.BottomPadding = padding
            props.RightPadding = padding
            props.LeftPadding = padding
            props.TopPadding = padding
        end
    else
        
        local xPadding = props.XPadding
        local yPadding = props.YPadding
        
        if xPadding then
            
            if typeof(xPadding.Value) == "UDim2" then
                
                props.LeftPadding = xPadding.X
                props.RightPadding = xPadding.Y
                
            elseif typeof(xPadding.Value) == "UDim" then
                
                props.RightPadding = xPadding
                props.LeftPadding = xPadding
            end
        end
        
        if yPadding then
            
            if typeof(yPadding.Value) == "UDim2" then
                
                props.TopPadding = yPadding.X
                props.BottomPadding = yPadding.Y
                
            elseif typeof(yPadding.Value) == "UDim" then
                
                props.BottomPadding = yPadding
                props.TopPadding = yPadding
            end
        end
    end
    
    --// Attributes
    props.XPadding = nil    :: State<UDim|UDim2>
    props.YPadding = nil    :: State<UDim|UDim2>
    props.Padding = nil     :: State<UDim|UDim2>
    
    props.BottomPadding = attribute(props.BottomPadding, scale(0.00))   :: State<UDim>
    props.RightPadding  = attribute(props.RightPadding, scale(0.00))    :: State<UDim>
    props.LeftPadding   = attribute(props.LeftPadding, scale(0.00))     :: State<UDim>
    props.TopPadding    = attribute(props.TopPadding, scale(0.00))      :: State<UDim>
    
    props.AnchorPosition    = attribute(props.AnchorPosition, vector(0, 0)) :: State<Vector2>
    props.Position          = attribute(props.Position, scale(0.00, 0.00))  :: State<UDim2>
    props.Size              = attribute(props.Size, scale(1.00, 1.00))      :: State<UDim2>
    props.Rotation          = attribute(props.Rotation, 0) * 360            :: State<number>
    
    --// Override
    if anchorPositionEnabled then
        
        props.AnchorPoint   = props.AnchorPosition
        props.Position      = scale(props.AnchorPosition.X, props.AnchorPosition.Y)
    end
    
    local padding1 = udim2(props.LeftPadding, props.TopPadding)
    local padding2 = udim2(props.RightPadding, props.BottomPadding)
    
    --// Body
    props.BorderSizePixel   = 0
    props.Position          = props.Position + padding1
    props.Size              = props.Size - padding1 - padding2
end

--// End
return GuiObject