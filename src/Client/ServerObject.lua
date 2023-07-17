--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type State<V> = Package.State<V>

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Assets
local RemoteFunction = ReplicatedStorage.RemoteFunction
local RemoteEvent = ReplicatedStorage.RemoteEvent
local ClassesSync = ReplicatedStorage.ClassesSync

--// Packages
local Promise = require(Packages.Core.Promise)
local tryPromise = Promise.try
local allPromise = Promise.all

local newSignal = require(Packages.Core.Signal).new
local throw = require(Packages.Core.Exception).throw
local _expect = require(Packages.Core.Expectation).new
local getType = Package.GetType
local isA = Package.IsA

local VOID = Package.VOID
local SET = Package.SET

--// Class
local ServerObject = Package.class("ServerObject")
:: Package.Class<ServerObject>

--// Consts
local LOG_REQUESTS = true

--// Vars
local onServerClassReady = newSignal()
local serializedClasses = {}
local serverClasses = {}

--// Private Functions
local function awaitBuildingObject(serverClass: Class, awaitingToken: any): ServerObject
    
    if not awaitingToken then return serverClass end
    
    local object = serverClass._buildingObjects[awaitingToken]
    local token = if object then awaitingToken else -1
    
    while token ~= awaitingToken do
        
        object, token = serverClass._objectBuilding:Await()
    end
    
    return object
end
local function findBuildingObject(serverClass: Class, token: any): ServerObject?
    
    if not token then return serverClass end
    return serverClass._buildingObjects[token]
end

local function awaitBuildedObject(serverClass: Class, awaitingToken: any): ServerObject
    
    if not awaitingToken then return serverClass end
    
    local buildingObject = awaitBuildingObject(serverClass, awaitingToken)
    if buildingObject._isBuilding then buildingObject._builded:Await() end
    
    return buildingObject
end
local function findBuildedObject(serverClass: Class, token: any): ServerObject?
    
    if not token then return serverClass end
    return serverClass._buildedObjects[token]
end

local function awaitServerClass(className: string): Class
    
    local serverClass = serverClasses[className]
    local readyClassName = serverClass and className
    
    while readyClassName ~= className do
        
        serverClass, readyClassName = onServerClassReady:Await()
    end
    
    return serverClass
end
local function findServerClass(className: string): Class?
    
    return serverClasses[className]
end

local function deserializeAsync(data: {any}): (Promise<(value: any)->(), any>, any)
    
    local value, className = data[1], data[2]
    local promise
    
    if className then
        
        local serverClass = findServerClass(className)
        local token = value
        
        value = if serverClass then findBuildingObject(serverClass, token) else nil
        
        if not value then
            
            promise = tryPromise(awaitServerClass, className)
                :Timeout(5):Catch("PromiseTimedOutException", warn, "Unexist class", className)
                :Then(function(serverClass) return awaitBuildedObject(serverClass, token) end)
        end
        
    elseif type(value) == "table" then
        
        local promises = {}
        
        for index, subData in value do
            
            local subPromise, provisoryValue = deserializeAsync(subData)
            value[index] = provisoryValue
            
            if subPromise then table.insert(promises, subPromise:Then(SET, value, index)) end
        end
        
        promise = allPromise(promises):ThenValue(value)
    end
    
    return promise, value
end
local function awaitDeserialize(data: {any}): any
    
    local value, className = data[1], data[2]
    
    if className then
        
        value = awaitBuildedObject(awaitServerClass(className), value)
        
    elseif type(value) == "table" then
        
        for index, subData in value do
            
            value[index] = awaitDeserialize(subData)
        end
    end
    
    return value
end

local function serialize(value: any): {any}
    
    if isA(value, "ServerObject") then
        
        return {value.Token, getType(value)}
        
    elseif isA(value, "table") then
        
        local serializedValue = {}
        
        for index, subValue in value do
            
            serializedValue[index] = serialize(subValue)
        end
        
        return {serializedValue}
    else
        
        return {value}
    end
end

--// Behaviour
function ServerObject:start()
    
    for className in serializedClasses do
        
        if serverClasses[className] then continue end
        
        Package.class(className).extends(ServerObject).ready()
    end
end

--// Constructor
function ServerObject.prototype:constructor(data)
    
    local token, stateValues = unpack(data)
    local signals = {}
    
    --// Instance
    self.Token = token
    
    self._isBuilding = true
    self._signals = signals
    
    --// Load Data
    self:_onBuilding(token)
    
    for name, value in self._serverStates do
        
        if value == VOID then value = nil end
        
        self:GetState(name, if value == VOID then nil else value)
    end
    for name, path in self._serverSignals do
        
        local signal = newSignal(path)
        signals[name] = signal
        self[name] = signal
    end
    
    for name, serializedValue in stateValues do
        
        local promise, provisoryValue = deserializeAsync(serializedValue)
        local state = self:GetState(name, provisoryValue)
        
        if promise then promise:Then(state.Set, state) end
    end
    
    return self
end
function ServerObject.prototype:postconstruct(data)
    
    local token = data[1]
    
    self._isBuilding = false
    self:_onBuilded(token)
end

--// Signals
function ServerObject.prototype.signal._building(self: RemoteObject, token: any) end
function ServerObject.prototype.signal._builded(self: RemoteObject, token: any) end

--// Private Methods
function ServerObject.prototype:_onBuilding(token: any) end
function ServerObject.prototype:_onBuilded(token: any) end

--// Behaviour
function ServerObject.prototype:tostring(...)
    
    return "%t#%s(%*s)", self, self.Token, {...}
end

function ServerObject.prototype:extended(subClass,...)
    
    local filtringFields = table.move(self._remoteMethodNames, 1, #self._remoteMethodNames, select("#",...)+1, {...})
    
    Package.extended(self, subClass, "_serverSignals", "_serverStates", "_onBuilding", "_onBuilded", "Destroy", unpack(filtringFields))
end
function ServerObject:extended(subClass,...)
    
    Package.extended(self, subClass,...)
    
    local className = getType(subClass)
    
    if serverClasses[className] then return end
    serverClasses[className] = subClass
    
    local serializedClass = serializedClasses[className] or {
        Prototype = { Methods = {}, Signals = {}, States = {} },
        Static = { Functions = {}, Signals = {}, States = {} },
        BaseClasses = {},
    }
    
    local remoteMethodNames = {}
    local buildingObjects = {}
    local buildedObjects = {}
    
    --// Class Vars
    subClass._remoteMethodNames = remoteMethodNames
    subClass._buildingObjects = buildingObjects
    subClass._buildedObjects = buildedObjects
    
    subClass._signals = {}
    subClass._states = {}
    
    --// Class Signals
    function subClass.signal._objectBuilding(object: ServerObject, token: any) end
    function subClass.signal._objectBuilded(object: ServerObject, token: any) end
    
    --// Class Functions
    function subClass.ready()
        
        serverClasses[className] = subClass
        onServerClassReady(subClass, className)
        
        return subClass
    end
    
    --// Constructor
    function subClass.prototype:constructor(data)
        
        --// Instance
        ServerObject(self, data)
    end
    
    --// Override Properties
    subClass.prototype._serverSignals = serializedClass.Prototype.Signals
    subClass.prototype._serverStates = serializedClass.Prototype.States
    
    --// Methods
    function subClass.prototype:_onBuilding(token: any)
        
        buildingObjects[token] = self
        
        subClass._objectBuilding(self, token)
        self._building(token)
    end
    function subClass.prototype:_onBuilded(token: any)
        
        buildedObjects[token] = self
        
        subClass._objectBuilded(self, token)
        self._builded(token)
    end
    
    --// Override Methods
    function subClass.prototype:Destroy()
        
        buildingObjects[self.Token] = nil
        buildedObjects[self.Token] = nil
        
        Package.Destroy(self)
    end
    
    --// Server Resource
    local objectStates = subClass.prototype._serverStates
    
    for name, serializedValue in serializedClass.Prototype.States do
        
        local promise, provisoryValue = deserializeAsync(serializedValue)
        objectStates[name] = if provisoryValue == nil then VOID else provisoryValue
        
        if promise then promise:Then(SET, objectStates, name) end
    end
    for name, serializedValue in serializedClass.Static.States do
        
        local promise, provisoryValue = deserializeAsync(serializedValue)
        local state = subClass:GetState(name, provisoryValue)
        
        if promise then promise:Then(state.Set, state) end
    end
    
    for name, path in serializedClass.Static.Signals do
        
        local signal = newSignal(path)
        
        subClass._signals[name] = signal
        subClass[name] = signal
    end
    
    for name in serializedClass.Prototype.Methods do
        
        table.insert(remoteMethodNames, name)
        
        subClass.prototype.async[name] = function(self, promise,...)
            
            local success, result = RemoteFunction:InvokeServer(className, self.Token, name, serialize({...}))
            result = awaitDeserialize(result)
            
            if success then
                
                return unpack(result)
            else
                
                throw(0, unpack(result))
            end
        end
    end
    for name in serializedClass.Static.Functions do
        
        subClass.async[name] = function(promise,...)
            
            local success, result = RemoteFunction:InvokeServer(className, nil, name, serialize({...}))
            result = awaitDeserialize(result)
            
            if success then
                
                return unpack(result)
            else
                
                throw(0, unpack(result))
            end
        end
    end
    
    task.spawn(function()
        
        for baseClassName in serializedClass.BaseClasses do
            
            local baseClass = awaitServerClass(baseClassName)
            self.extends(baseClass)
        end
    end)
end

--// Listeners
RemoteEvent.OnClientEvent:Connect(function(className: string, token: any, name: string, states: {}, arguments: {{any}})
    
    local serverClass = awaitServerClass(className)
    arguments = awaitDeserialize(arguments)
    states = states[1]
    
    if name then
        
        local object = awaitBuildedObject(serverClass, token)
        
        if states then
            
            if LOG_REQUESTS then print("[client]", className..(token and "#"..token or "").."."..name, "=", arguments[1]) end
            
            object._states[name]:Set(arguments[1], "fromserver")
        else
            
            if LOG_REQUESTS then print("[client]", className..(token and "#"..token or "").."."..name, "|", unpack(arguments)) end
            
            object._signals[name](unpack(arguments))
        end
    else
        
        if states then
            
            if LOG_REQUESTS then warn("[client] NEW", className.."#"..token, "|", states, unpack(arguments)) end
            
            local existingObject = findBuildedObject(serverClass, token)
            
            if existingObject then
                
                for state, value in awaitDeserialize(states) do
                    
                    existingObject:GetState(state):Set(value)
                end
            else
                
                serverClass.new({ token, states }, unpack(arguments))
            end
        else
            
            if LOG_REQUESTS then warn("[client] DEL", className.."#"..token) end
            
            awaitBuildedObject(serverClass, token):Destroy()
        end
    end
end)

--// Yielder Behaviour
if Package.IS_RUNNING then
    
    serializedClasses = ClassesSync:InvokeServer()
end

--// End
export type ServerObject = typeof(ServerObject.prototype:constructor())

return ServerObject