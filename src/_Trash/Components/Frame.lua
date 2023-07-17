--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Packages
local Component = require(Packages.Libraries.Component)
local create, attribute = Component.create, Component.attribute

local Components = Packages.Client.Components
local Container = require(Components.Container)

--// Component
local function Frame(props,...): Frame
    
    local children = Container(props)
    
    --// Body
    return create("Frame", props, children,...)
end

--// End
return function(name: string)
    
    return function(props,...)
        
        props.Name = name
        return Frame(props,...)
    end
end