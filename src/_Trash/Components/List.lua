--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute = Component.create, Component.attribute

local State = require(Packages.Core.State)
local pixel, vector = State.pixel, State.vector

local Components = Packages.Client.Components
local Frame = require(Components.Frame)

--// Component
local function List(props,...): Frame
    
    Component(props)
    
    --// Attributes
    props.ElementsPadding       = attribute(props.ElementsPadding, pixel(0))                :: State<UDim>
    props.Direction             = attribute(props.Direction, Enum.FillDirection.Vertical)   :: State<Enum.FillDirection>
    props.SortOrder             = attribute(props.SortOrder, Enum.SortOrder.LayoutOrder)    :: State<Enum.SortOrder>
    props.Alignment             = attribute(props.Alignment, vector(0, 1))                  :: State<Vector2>
    
    local alignment = props.Alignment.Value
    local uiListLayout = create("UIListLayout", {
        HorizontalAlignment = if alignment.X > 0 then Enum.HorizontalAlignment.Right elseif alignment.X < 0 then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center,
        VerticalAlignment = if alignment.Y > 0 then Enum.VerticalAlignment.Top elseif alignment.Y < 0 then Enum.VerticalAlignment.Bottom else Enum.VerticalAlignment.Center,
        
        FillDirection = props.Direction,
        SortOrder = props.SortOrder,
        Padding = props.ElementsPadding,
    })
    
    --// Methods
    function props._method:Put(content)
        
        content.Parent = self
    end
    
    --// Body
    props.FillDirection = nil
    props.Direction = nil
    props.SortOrder = nil
    props.Padding = nil
    
    return Frame (props.Name) (props, { uiListLayout },...)
end

--// End
return function(name: string)
    
    return function(props,...)
        
        props.Name = name
        return List(props,...)
    end
end