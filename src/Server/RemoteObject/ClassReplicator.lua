--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectReplicator: typeof(require(script.Parent.ObjectReplicator))
local newRemoteSignal: typeof(require(script.Parent.RemoteSignal).new)
local newObjectReplicator: typeof(ObjectReplicator.new)
type ObjectReplicator = ObjectReplicator.ObjectReplicator

local getPlayer: typeof(require(Packages.Server.Classes.Player).getPlayer)
local tryPromise = require(Packages.Core.Promise).try
local _expect = require(Packages.Core.Expectation).new

local getType = Package.GetType
local isA = Package.IsA

local VOID = Package.VOID

task.defer(function()
    
    ObjectReplicator = require(script.Parent.ObjectReplicator)
    newObjectReplicator = ObjectReplicator.new
    
    newRemoteSignal = require(script.Parent.RemoteSignal).new
    getPlayer = require(Packages.Server.Classes.Player).getPlayer
end)

--// Assets
local RemoteFunction = ReplicatedStorage.RemoteFunction
local RemoteEvent = ReplicatedStorage.RemoteEvent
local ClassesSync = ReplicatedStorage.ClassesSync

--// Abstract Class
local ClassReplicator = Package.class("ClassReplicator")
:: Package.Class<ClassReplicator>

--// Vars
local classReplicators = {}
local everyone = {}

--// Class Signals
function ClassReplicator.signal.PlayerSessionLoaded(player: Player) end

--// Functions
local function awaitSerialize(userId: number, value: any): {any}
    
    if isA(value, "RemoteObject") then
        
        if not value:_awaitHaveReplicationAccess(userId) then return {nil} end
        
        return {value.Token, getType(value)}
    else
        
        if isA(value, "State") then
            
            value = value.Value
            
        elseif isA(value, "Object") then
            
            warn(`Attempt to send a non-RemoteObject %t(%v)`, value, value)
        end
        
        if type(value) == "table" then
            
            local serializedValue = {}
            
            for index, subValue in value do
                
                serializedValue[index] = awaitSerialize(userId, subValue)
            end
            
            return {serializedValue}
        else
            
            return {value}
        end
    end
end
local function deserialize(data: {any}): any
    
    local value, className = data[1], data[2]
    
    if className then
        
        return classReplicators[className]._objects[value]
        
    elseif type(value) == "table" then
        
        for index, subData in value do
            
            value[index] = deserialize(subData)
        end
    end
    
    return value
end

local function replicate(replication: Replication, extra,...: any): ()  --! POSSIBLE OPTIMIZATION
    
    local className, token, name = replication.ClassName, replication.Token, replication.Name
    
    for userId, rbxPlayer in replication.Players or everyone do
        
        if not rbxPlayer then continue end
        
        task.spawn(RemoteEvent.FireClient, RemoteEvent, rbxPlayer, className, token, name, awaitSerialize(userId, extra), awaitSerialize(userId, {...}))
    end
end
ClassReplicator._replicate = replicate

local function replicateState(replication: Replication, newValue: any): ()
    
    replicate(replication, {}, newValue)
end
ClassReplicator._replicateState = replicateState

--// Class Behaviour
function ClassReplicator:start()
    
    local classesFields = {}
    
    --// Listen States Change
    for className, classReplicator in classReplicators do
        
        for name, state in classReplicator._states do
            
            state.Changed:Connect(replicateState, {
                ClassName = className,
                IsState = true,
                Players = nil,
                Token = nil,
                Name = name,
            })
        end
    end
    
    --// Serialize
    for className, classReplicator in classReplicators do
        
        local prototype = { Methods = {}, Signals = {}, States = classReplicator._prototype.state } do
            
            for name, path in classReplicator._prototype.signal do prototype.Signals[name] = path end
            for name in classReplicator._prototype.methods do prototype.Methods[name] = true end
        end
        local static = { Functions = {}, Signals = {}, States = classReplicator._static.state } do
            
            for name, path in classReplicator._static.signal do static.Signals[name] = path end
            for name in classReplicator._static.functions do static.Functions[name] = true end
        end
        local baseClasses = {} do
            
            for baseClass in classReplicator._baseClasses do
                
                table.insert(baseClasses, getType(baseClass))
            end
        end
        
        classesFields[className] = {
            BaseClasses = baseClasses,
            Prototype = prototype,
            Static = static,
        }
    end
    
    --// Release Client Loader
    function ClassesSync.OnServerInvoke(player)
        
        if player:GetAttribute("Loaded") then return end
        player:SetAttribute("Loaded", true)
        
        local serializedClasses = {}
        local userId = player.UserId
        
        everyone[userId] = player
        
        --// Update Values
        for className, classFields in classesFields do
            
            local prototypeValues = {}
            local staticValues = {}
            
            for name, state in classFields.Prototype.States do
                
                prototypeValues[name] = awaitSerialize(userId, state.Value)
            end
            for name, state in classFields.Static.States do
                    
                staticValues[name] = awaitSerialize(userId, state.Value)
            end
            
            serializedClasses[className] = {
                BaseClasses = classFields.BaseClasses,
                Static = {
                    Functions = classFields.Static.Functions,
                    Signals = classFields.Static.Signals,
                    States = staticValues,
                },
                Prototype = {
                    Methods = classFields.Prototype.Methods,
                    Signals = classFields.Prototype.Signals,
                    States = prototypeValues,
                },
            }
        end
        
        --// End
        ClassReplicator.PlayerSessionLoaded(player)
        return serializedClasses
    end
end

--// Constructor
function ClassReplicator.prototype:constructor(classToReplicate: Class)
    
    _expect(classToReplicate).is("Object"):Argument(1, "classToReplicate")
    
    local className = getType(classToReplicate)
    local clientFunctions = {}
    local clientMethods = {}
    local clientSignals = {}
    local clientStates = {}
    
    --// Instance
    self.ClassName = className
    
    self._clientFunctions = clientFunctions
    self._clientMethods = clientMethods
    self._clientSignals = clientSignals
    self._clientStates = clientStates
    
    self._object = classToReplicate
    self._objectsCount = 0
    self._baseClasses = {}
    self._replicators = {}
    self._objects = {}
    
    self._states = classToReplicate._states
    self._signals = {}
    
    self._prototype = setmetatable({
        methods = setmetatable({}, {
            __newindex = function(methods, methodName, remoteMethod)
                
                _expect(methodName).is("string"):Argument(1, "methodName")
                _expect(remoteMethod).is("function"):Argument(2, "remoteMethod")
                
                clientMethods[methodName] = function(object, player,...)
                    
                    return tryPromise(remoteMethod, object, player,...)
                end
                
                rawset(methods, methodName, remoteMethod)
            end
        }),
        signal = setmetatable({}, {
            __newindex = function(signals, signalName)
                
                _expect(signalName).is("string"):Argument(1, "signalName")
                
                local signalPath = "remote "..className..":"..signalName
                
                clientSignals[signalName] = signalPath
                rawset(signals, signalName, signalPath)
            end,
        }),
        state = setmetatable({}, {
            __newindex = function(states, stateName, stateValue)
                
                _expect(stateName).is("string"):Argument(1, "stateName")
                
                stateValue = if stateValue == nil then VOID else stateValue
                
                assert(stateName ~= "Amount")
                
                clientStates[stateName] = stateValue
                rawset(states, stateName, { Value = stateValue })
            end
        }),
    }, {
        __newindex = function(prototype, index, value)
            
            _expect(index).is("string"):Argument(1, "index")
            
            if type(value) == "function" then
                
                prototype.methods[index] = value
            else
                
                prototype.state[index] = value
            end
        end,
    })
    self._static = setmetatable({
        functions = setmetatable({}, {
            __newindex = function(functions, functionName, remoteFunction)
                
                _expect(functionName).is("string"):Argument(1, "functionName")
                _expect(remoteFunction).is.some("function", "nil"):Argument(2, "remoteFunction")
                
                clientFunctions[functionName] = function(object, player,...)
                    
                    return tryPromise(remoteFunction, player,...)
                end
                
                rawset(functions, functionName, remoteFunction)
            end,
        }),
        signal = setmetatable({}, {
            __newindex = function(signals, signalName)
                
                _expect(signalName).is("string"):Argument(1, "signalName")
                
                local signalPath = "remote $"..className.."."..signalName
                local signal = newRemoteSignal(signalPath, {
                    ClassName = className,
                    Name = signalName,
                    IsState = false,
                    Players = nil,
                    Token = nil,
                })
                
                classToReplicate[signalName] = signal
                self._signals[signalName] = signal
                
                rawset(signals, signalName, signalPath)
            end
        }),
        state = setmetatable({}, {
            __newindex = function(states, stateName, stateValue)
                
                _expect(stateName).is("string"):Argument(1, "stateName")
                
                local state = classToReplicate:GetState(stateName, stateValue)
                rawset(states, stateName, state)
            end
        }),
    }, {
        __newindex = function(static, index, value)
            
            _expect(index).is("string"):Argument(1, "index")
            
            if type(value) == "function" then
                
                static.functions[index] = value
            else
                
                static.state[index] = value
            end
        end,
    })
    
    --// Log
    classReplicators[getType(classToReplicate)] = self
    return self
end

--// Methods
function ClassReplicator.prototype:Object(object: Object,...: any): ObjectReplicator
    
    _expect(object).is("Object"):Argument(1, "object")
    
    local token = self._objectsCount
    self._objectsCount += 1
    
    local objectReplicator = newObjectReplicator(self.ClassName, object, token, self._clientStates, self._clientSignals,...)
    self._replicators[token] = objectReplicator
    self._objects[token] = object
    
    return objectReplicator
end

--// Behaviour
function ClassReplicator.prototype:tostring()
    
    return "remote $%s", self.ClassName
end

--// Listeners
function RemoteFunction.OnServerInvoke(rbxPlayer: Player, className: string, token: integer, name: string, arguments: {{any}}): (boolean, {{any}})
    
    if type(arguments) ~= "table" then return rbxPlayer:Kick("Bad request arguments") end
    
    --// Trace Object
    local classReplicator = classReplicators[className]
    if not classReplicator then return rbxPlayer:Kick("Bad request className") end
    
    local objectReplicator = if token then classReplicator._replicators[token] else classReplicator
    if not objectReplicator then return rbxPlayer:Kick("Bad request token") end
    
    if token and not objectReplicator.Players[rbxPlayer.UserId] then return false, awaitSerialize({"Exception", "Permission denied"}) end
    
    --// Trace Function
    local remoteFunction = classReplicator[if token then "_clientMethods" else "_clientFunctions"][name]
    if not remoteFunction then return rbxPlayer:Kick("Bad request name") end
    
    --// Execute
    local result = {
        remoteFunction(objectReplicator._object, getPlayer(rbxPlayer), unpack(deserialize(arguments)))
            :Catch("Exception")
            :Await()
    }
    
    if result[1] then
        
        return true, awaitSerialize(rbxPlayer.UserId, {unpack(result, 2)})
    else
        
        local exception = result[2]
        return false, awaitSerialize(rbxPlayer.UserId, {getType(exception), exception:components()})
    end
end

--// End
type Replication = {
    Players: {[number]: Player?},
    ClassName: string,
    IsState: boolean?,
    Token: number,
    Name: string?,
}
export type ClassReplicator = typeof(ClassReplicator.prototype:constructor())

return ClassReplicator