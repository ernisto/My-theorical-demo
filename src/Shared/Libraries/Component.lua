--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local newState = require(Packages.Core.State).new
local _expect = require(Packages.Core.Expectation).new
local isA = Package.IsA

--// Class
local Component = {}

--// Vars
local instanceStates = setmetatable({}, { __mode = "k" })

--// Private Functions
local function setProperty(self, index, value)
    
    while isA(value, "State") do value = value.Value end
    
    self[index] = value
end
local function setAttribute(self, index, value)
    
    while isA(value, "State") do value = value.Value end
    
    self:SetAttribute(index, value)
end

local function callMethod(signal, method, self)
    
    signal:Await()
    method(self, unpack(signal._output or {}))
end
local function get(self, index)
    
    return self[index]
end

--// Class Functions
function Component.getState(self: Instance, name: string): State<any>
    
    local states = instanceStates[self] or setmetatable({}, { __mode = "v" })
    local state = states[name]
    
    if not state then
        
        local isProperty = pcall(get, self, name)
        
        if isProperty then
            
            state = newState(self[name])
            self:GetPropertyChangedSignal(name):Connect(function() state:Set(self[name]) end)
        else
            
            state = newState(self:GetAttribute(name))
            self:GetAttributeChangedSignal(name):Connect(function() state:Set(self:GetAttribute(name)) end)
        end
    end
    
    return state
end
function Component.attribute(value: any, default: any?): State<typeof(value)>
    
    if value == nil then value = default end
    
    if not isA(value, "State") then
        
        value = newState(value)
        value.Constant = false
    end
    
    return value
end
function Component.apply(self: Instance, props,...: {Instance}): Instance
    
    local states = instanceStates[self] or {}
    instanceStates[self] = states
    
    local listeners = props._listener or {}
    local changeds = props._changed or {}
    local methods = props._method or {}
    
    props._listener = nil
    props._method = nil
    
    --// Setup
    for name, listener in listeners do
        
        local signal = self[name]
        _expect(typeof(signal) == "RBXScriptSignal", "Invalid signal '"..name.."'")
        
        signal:Connect(listener)
    end
    
    for name, method in methods do
        
        local signal = props[name]
        if not signal then continue end
        
        signal:Connect(callMethod, signal, method, self)
        props[name] = nil
    end
    
    for index, value in props do
        
        if type(value) == "function" then value = value(self) end
        
        local isProperty, baseValue = pcall(get, self, index)
        local setter = if isProperty then setProperty else setAttribute
        local state
        
        if isA(value, "State") then
            
            if not value.Constant then
                
                states[index] = value
                state = value
            end
            
            repeat value = value.Value until not isA(value, "State")
        end
        
        _expect(not isProperty or (typeof(if value ~= nil then value else game) == typeof(if baseValue ~= nil then baseValue else game)), "Invalid property '"..index.."' value ("..tostring(value)..")")
        local isWritable = pcall(setter, self, index, value)
        
        if not isWritable then continue end
        if not state then continue end
        
        state.Changed:Connect(setter, self, index)
    end
    
    for _,children in {...} do
        
        for name, child in children do
            
            if type(child) == "function" then child = child(self) end
            if type(name) == "number" then name = nil end
            
            if isA(child, "State") then
                
                local lastChildName = name
                
                child:Updater(function(newChild, lastChild)
                    
                    if lastChild then
                        
                        if name then lastChild.Name = lastChildName end
                        lastChild.Parent = nil
                    end
                    if newChild then
                        
                        lastChildName = newChild.Name
                        
                        if name then newChild.Name = name end
                        newChild.Parent = self
                    end
                end)
            else
                
                child.Parent = self
                if name then child.Name = name end
            end
        end
    end
    
    --// Changed & State sync
    self.AttributeChanged:Connect(function(property)
        
        local newValue = self:GetAttribute(property)
        
        if changeds[property] then
            
            changeds[property](self, newValue)
        end
        
        local state = states[property]
        if not state then return end
        
        state:Set(newValue)
    end)
    self.Changed:Connect(function(property)
        
        local _,newValue = pcall(get, self, property)
        
        if changeds[property] then
            
            changeds[property](self, newValue)
        end
        
        local state = states[property]
        if not state then return end
        
        state:Set(newValue)
    end)
    
    --// End
    return self
end
function Component.create(className: string, props,...: {Instance}): Instance
    
    local self = Instance.new(className)
    return Component.apply(self, props,...)
end

--// Component
function Component:__call(props)
    
    props._listener = props._listener or {}
    props._changed = props._changed or {}
    props._method = props._method or {}
end

--// End
return setmetatable(Component, Component)