--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Packages
local _expect: typeof(require(ReplicatedStorage.Core.Expectation).new)
local newPromise: typeof(require(ReplicatedStorage.Core.Promise).new)
local newState: typeof(require(ReplicatedStorage.Core.State).new)
local throw: typeof(require(ReplicatedStorage.Core.Exception).throw)
local format: typeof(require(ReplicatedStorage.Core.Format))
local Signal: typeof(require(ReplicatedStorage.Core.Signal))
local destroySignal: typeof(Signal.Destroy)
local newSignal: typeof(Signal.new)

local instanceIsA = game.IsA
local async = task.spawn

local isA, isSome, getType
local Package

task.defer(function()
    
    Signal = require(ReplicatedStorage.Core.Signal)
    destroySignal = Signal.Destroy
    newSignal = Signal.new
    
    Package.load(ReplicatedStorage.Core)
    _expect = require(ReplicatedStorage.Core.Expectation).new
    newPromise = require(ReplicatedStorage.Core.Promise).new
    throw = require(ReplicatedStorage.Core.Exception).throw
    newState = require(ReplicatedStorage.Core.State).new
    format = require(ReplicatedStorage.Core.Format)
    
    Package.load(ReplicatedStorage.Libraries)
end)

--// Invisible Properties
local listingGarbageCollects = setmetatable({}, { __mode = "k" })
local garbageCollectedTriggers = {} --! UDPATE SOON

local objectConstructions = setmetatable({}, { __mode = "k" })
local classesImplements = setmetatable({}, { __mode = "k" })
local objectPrototypes = setmetatable({}, { __mode = "k" })
local objectBases = setmetatable({}, { __mode = "k" })
local tracebacks = setmetatable({}, { __mode = "k" })

--// Prototype
local methods = {}
local metatable = { __index = methods, __newindex = methods, __metatable = "locked" }
local prototype = setmetatable({ methods = methods, signal = {}, async = {} }, metatable)

--// Class
local metatable = { __metatable = "locked", __index = methods }
Package = setmetatable({ prototype = prototype, signal = {}, async = {} }, metatable)

--// Log Infos
objectBases[Package] = { "Object", ["Object"] = true }
objectPrototypes[Package] = prototype
classesImplements[Package] = {}
--classes["Package"] = Package  --#no: conflict with module behaviour (:start, :editting, :client, etc)

--// Consts
local CORE_SCRIPTS = ReplicatedStorage.Core:GetDescendants()
CORE_SCRIPTS[#CORE_SCRIPTS+1] = script

local FILTER_CORE = false

--// Class Consts
local function SET(self, index, value) self[index] = value end
local function EMPTY_FUNCTION() end

Package.IS_RUNNING = RunService:IsRunning()
Package.IS_EDITTING = not Package.IS_RUNNING

Package.IS_STUDIO = RunService:IsStudio()
Package.IS_APPLICATION = not Package.IS_STUDIO

Package.IS_CLIENT = RunService:IsClient()
Package.IS_SERVER = not Package.IS_CLIENT

Package.EMPTY_FUNCTION = EMPTY_FUNCTION
Package.SET = SET

Package.VOID = newproxy()

--// Vars
local loadedFolders = {}
local started = false
local classes = {}

--// Class Vars
Package.Packages = {
    Server = ServerScriptService:FindFirstChild("Server"),
    Libraries = ReplicatedStorage.Libraries,
    Settings = ReplicatedStorage.Settings,
    Client = ReplicatedStorage.Client,
    Assets = ReplicatedStorage.Assets,
    Core = ReplicatedStorage.Core,
} :: ReplicatedStorage

--// Class Behaviour
function Package:application()
    
    for _,Class in classes do async(Class.application, Class) end
end
function Package:studio()
    
    for _,Class in classes do async(Class.studio, Class) end
end

function Package:running()
    
    for _,Class in classes do async(Class.running, Class) end
end
function Package:editting()
    
    for _,Class in classes do async(Class.editting, Class) end
end

function Package:server()
    
    for _,Class in classes do async(Class.server, Class) end
end
function Package:client()
    
    for _,Class in classes do async(Class.client, Class) end
end

function Package:start()
    
    task.wait()
    
    if started then return end
    started = true
    
    for _,Class in classes do async(Class.start, Class) end
    
    if Package.IS_RUNNING then Package:running() else Package:editting() end
    if Package.IS_STUDIO then Package:studio() else Package:application() end
end

--// Class Functions
local function getTraceback(thread: thread, level: integer)
    
    if level == 0 then return "" end
    level += 2
    
    local rootTraceback = tracebacks[coroutine.running()]
    local traceback = ""
    
    while true do
        
        local path, line, func, funcName = debug.info(thread, level, "slfn")
        if not path then break end
        
        local module = getfenv(func).script
        level += 1
        
        if FILTER_CORE and table.find(CORE_SCRIPTS, module) then continue end
        if line < 0 then continue end
        
        traceback ..= ("\n  Script '%s', Line %i - %s"):format(path, line, if funcName then "function "..funcName else "anonymous function")
    end
    
    return traceback..(rootTraceback or "")
end

function Package.async(thread: coroutine|(...any) -> ...any,...: any): (thread, boolean,...any)
    
    if type(thread) == "function" then thread = coroutine.create(thread) end
    _expect(thread).is.some("function", "thread"):Argument(1, "work")
    
    tracebacks[thread] = Package.traceback()
    
    local result = {coroutine.resume(thread,...)}
    if not result[1] then error(`{result[2]}{tracebacks[thread]}`, 0) end
    
    return thread, unpack(result)
end
function Package.traceback(thread: thread, level: integer?)
    
    if typeof(thread) ~= "thread" then
        
        _expect(thread).is.some("integer", "nil"):Argument(1, "level")
        
        thread, level = coroutine.running(), thread
    else
        
        _expect(thread).is("thread"):Argument(1, "thread")
        _expect(level).is.some("integer", "nil"):Argument(2, "level")
    end
    
    level = level or 1
    return getTraceback(thread, level)
end
function Package.isSubClass(subClassName: string, baseClassName: string): boolean
    
    return (objectBases[classes[subClassName]] or {})[baseClassName] ~= nil
end
function Package.listenGarbageCollect(value, trigger)
    
    _expect(trigger).is.some("function", "Function")
    
    listingGarbageCollects[value] = trigger
end

--// Core Functions
function Package.load(folder: Folder): {[string]: {[any]: any}}
    
    if not folder then return {} end
    if loadedFolders[folder] then return loadedFolders[folder] end
    
    local modules = {}
    loadedFolders[folder] = modules
    
    for _,child in folder:GetChildren() do
        
        if child:IsA("ModuleScript") then
            
            local timeout = task.delay(5, warn, "timed out to load", child, "(possibly recusive require/infinity yield)")
            local module = require(child)
            task.cancel(timeout)
            
            modules[child.Name] = module
            Package.load(folder:FindFirstChild("_"..child.Name))
            Package.load(child)
        else
            
            if child.Name:match("^_") then continue end
            
            modules[child.Name] = Package.load(child)
        end
    end
    
    return modules
end
function Package.class(className: string): Class
    
    --_expect(className).is("string"):Argument(1, "className")
    
    local prototypeSignals = {}
    local methods = {}
    
    local baseClasses = { className, [className] = true }
    local constructing = { __index = methods }
    local implementingClasses = {}
    local Class, prototype
    
    --// Prototype
    local metatable = { __metatable = "locked", __index = methods, __newindex = methods }
    
    prototype = setmetatable({
        signal = setmetatable({}, {
            
            __newindex = function(signalOriginMethods, signalName, signalMethod)
                
                --_expect(signalMethod).is.some("function", "nil"):Argument(2, "signalMethod")
                
                if not newSignal then return end
                local signalPath = className..":"..signalName
                
                prototypeSignals[signalName] = signalPath
                rawset(signalOriginMethods, signalName, signalPath)
            end,
        }),
        async = setmetatable({}, {
            
            __newindex = function(asyncMethods, methodName, asyncMethod)
                
                --_expect(asyncMethod).is("function"):Argument(2, "asyncMethod")
                
                methods[methodName] = function(self: Object,...: any)
                    
                    return newPromise(function(promise: Promise,...: any)
                        
                        return asyncMethod(self, promise,...)
                    end,...)
                end
                
                rawset(asyncMethods, methodName, asyncMethod)
            end,
        }),
        methods = methods,
    }, metatable)
    
    --// Class
    local metatable = { __metatable = "locked", __index = methods }
    
    Class = setmetatable({
        signal = setmetatable({}, {
            
            __newindex = function(signalFunctions, signalName, signalFunction)
                
                --_expect(signalFunction).is.some("function", "nil"):Argument(2, "signalFunction")
                
                if not newSignal then return end
                local signalPath = "$"..className.."."..signalName
                
                Class[signalName] = newSignal(signalPath)
                rawset(signalFunctions, signalName, signalPath)
            end,
        }),
        async = setmetatable({}, {
            
            __newindex = function(asyncFunctions, functionName, asyncFunction)
                
                --_expect(asyncFunction).is("function"):Argument(2, "asyncFunction")
                
                Class[functionName] = function(...: any)
                    
                    return newPromise(asyncFunction,...)
                end
                rawset(asyncFunctions, functionName, asyncFunction)
            end,
        }),
        prototype = prototype,
    }, metatable)
    
    --// Log Infos
    classesImplements[Class] = implementingClasses
    objectPrototypes[Class] = prototype
    objectBases[Class] = baseClasses
    classes[className] = Class
    
    Class._hostingInstances = {}
    Class._states = {}
    
    --// Class Functions
    function Class.new(...: any): Object
        
        local garbages = setmetatable({}, { __mode = "k" })
        local constructions = {}
        
        --// Instance
        local self = setmetatable({ _hostingInstances = garbages, _states = {}, IsDestroyed = false }, constructing)
        objectConstructions[self] = constructions
        objectPrototypes[self] = prototype
        objectBases[self] = baseClasses
        
        --// Construct
        for name, path in prototypeSignals do
            
            local signal = newSignal(path)
            
            garbages[signal] = destroySignal
            self[name] = signal
        end
        
        methods.constructor(self,...)
        setmetatable(self, methods)
        
        --// Post Construct
        for class, params in constructions do
            
            class.postconstruct(self, unpack(params, 1, params.n))
        end
        methods.postconstruct(self,...)
        
        --// End
        constructions[self] = nil
        return self
    end
    function Class.implements(...: Class)
        
        for _,implementingClass in {...} do
            
            if not isA(implementingClass, "Object") then continue end
            
            implementingClasses[getType(implementingClass)] = true
        end
        
        return Class
    end
    function Class.extends(...: Class)
        
        for _,baseClass in {...} do
            
            if not isA(baseClass, "Object") then continue end
            local baseClassImplements = classesImplements[baseClass]
            
            for implementingClassName in baseClassImplements do
                
                if not isA(Class, implementingClassName) then error(format("$%s must to be extended before %s", implementingClassName, baseClass), 2) end
            end
            
            baseClass:extended(Class)
            
            --// Register Bases
            for ancestorClassName in objectBases[baseClass] or {} do
                
                baseClasses[ancestorClassName] = baseClasses[ancestorClassName] or true
            end
        end
        
        return Class
    end
    
    --// Class Behaviour
    function Class:application()
    end
    function Class:studio()
    end
    
    function Class:editting()
    end
    function Class:running()
    end
    
    function Class:start()
    end
    
    --// Constructor
    function Class.prototype:postconstruct()
    end
    function Class.prototype:constructor()
        
        throw(3, "ConstructAbstractClassException", self)
    end
    
    --// Methods
    function methods:__index(index)
        
        return methods[index] or methods.get(self, index)
    end
    
    --// Class Metatable
    function metatable:__call(object: Object,...: any)
        
        local constructions = objectConstructions[object]
        
        if not constructions then return throw(1, "BadArgumentException", 1, "self") end
        if constructions[Class] then return end
        
        constructions[Class] = table.pack(...)
        return Class.constructor(object,...)
    end
    function metatable:__tostring()
        
        return `${className}`
    end
    
    --// End
    return Class.extends(Package) :: Class
end
function Package.awaitStart()
    
    while not started do task.wait() end
    return Package
end

--// Signals
function Package.prototype.signal.Destroyed() end

--// Methods
function Package.prototype.GetType(value: any): string
    
    local valueBases = objectBases[value]
    if valueBases then return valueBases[1] end
    
    local rbxType = typeof(value)
    if rbxType == "Instance" then return value.ClassName end
    
    return rbxType
end
getType = Package.prototype.GetType

function Package.prototype.IsSome(value: any,...: string): boolean
    
    local rbxType = typeof(value)
    
    if rbxType == "Instance" then
        
        for _,baseName in {...} do
            
            if baseName == "Roblox" or instanceIsA(value, baseName) or baseName == "userdata" then return true end
        end
    else
        
        local valueBases = objectBases[value]
        
        if valueBases then
            
            for _,baseName in {...} do
                
                if valueBases[baseName] then return true end
            end
            
        elseif type(value) ~= rbxType then
            
            for _,baseName in {...} do
                
                if baseName == "Roblox" or baseName == rbxType or baseName == "userdata" then return true end
            end
        else
            
            for _,baseName in {...} do
                
                if rbxType == baseName or (rbxType == "number" and baseName == "integer" and value % 1 == 0) then return true end
            end
        end
    end
    
    return false
end
isSome = Package.prototype.IsSome

function Package.prototype.IsA(value: any,...: string): boolean
    
    local rbxType = typeof(value)
    
    if rbxType == "Instance" then
        
        for _,baseName in {...} do
            
            if baseName == "Roblox" then continue end
            if not (instanceIsA(value, baseName) or baseName == "userdata") then return false end
        end
    else
        
        local valueBases = objectBases[value]
        
        if valueBases then
            
            for _,baseName in {...} do
                
                if not (valueBases[baseName] or baseName == "table") then return false end
            end
            
        elseif type(value) ~= rbxType then
            
            for _,baseName in {...} do
                
                if baseName == "Roblox" then continue end
                if not (baseName == rbxType or baseName == "userdata") then return false end
            end
        else
            
            for _,baseName in {...} do
                
                if not (rbxType == baseName or (rbxType == "number" and baseName == "integer" and (value % 1 == 0 or math.abs(value) == 1/0))) then return false end
            end
        end
    end
    
    return true
end
isA = Package.prototype.IsA

--// Methods
function Package.prototype:GetState(stateName: string, defaultValue: any): State<any>
    
    --_expect(stateName).is("string"):Argument(1, "stateName")
    
    local state = self._states[stateName]
    if state then return state end
    
    state = self:Hoste(newState(defaultValue))
    self._states[stateName] = state
    
    state:Updater(SET, self, stateName)
    return state
end
function Package.prototype:GetStates(): {[string]: State<any>}
    
    return self._states
end

function Package.prototype:Hoste(value: Object|Promise|Instance|RbxConnection): any
    
    local kind = getType(value)
    
    self._hostingInstances[value] = if kind == "Promise" then value.Cancel
        elseif kind == "RBXScriptConnection" then value.Disconnect
        else value.Destroy
    
    return value
end
function Package.prototype:Destroy()
    
    self:destroying()
    
    if self.Destroyed then
        
        self.Destroyed()
        
        for garbage, collector in self._hostingInstances do collector(garbage) end
    end
    
    local objectLabel = tostring(self)
    local traceback = Package.traceback()
    local kind = self:GetType()
    
    setmetatable(self, {
        __index = function(_,index)
            
            if index == "IsDestroyed" then return true end
            
            error(`Attempt to index a destroyed {kind} with '{index}', destroyed at\n{traceback}`)
        end,
        __newindex = function(_,index)
            
            error(`Attempt to index a destroyed {kind} with '{index}', destroyed at\n{traceback}`)
        end,
        __tostring = function()
            
            error(`destroyed-{objectLabel}`)
        end
    })
    objectBases[self] = nil
    table.clear(self)
end

--// Protected Methods
function Package.prototype:_increaseState(stateName: string, increment: number, maximun: number?,...)
    
    maximun = maximun or 9e999
    
    --_expect(stateName).is("string"):Argument(1, "stateName")
    --_expect(increment).is("number"):Argument(2, "increment")
    --_expect(maximun).is("number"):Argument(3, "maximun")
    
    local state = self:GetState(stateName)
    state:Increase(increment, maximun,...)
    
    return state
end
function Package.prototype:_decreaseState(stateName: string, decrement: number, minimun: number?,...)
    
    minimun = minimun or -9e999
    
    --_expect(stateName).is("string"):Argument(1, "stateName")
    --_expect(decrement).is("number"):Argument(2, "decrement")
    --_expect(minimun).is("number"):Argument(3, "minimun")
    
    local state = self:GetState(stateName)
    state:Decrease(decrement, minimun,...)
    
    return state
end
function Package.prototype:_setState(stateName: string, value: any,...: any)
    
    --_expect(stateName).is("string"):Argument(1, "stateName")
    
    local state = self:GetState(stateName)
    state:Set(value,...)
    
    return state
end

--// Behaviour

--[=[
    Called when *subClass*.extends(*self*)

    ```lua
    --// Class
    local Exception = Package.class()
    
    --// Vars
    local exceptions = {}
    
    --// Functions
    function Exception.throw(exceptionName: string,...)
        
        exceptions[exceptionName](...)
    end
    
    --// Behaviour
    function Exception:extended(subClass)
        
        exceptions[subClass:GetType()] = subClass.new
        
        Package.extended(self, subClass)    -- inherit Exception methods, signals, etc
    end
    
    --// Class
    local BadArgumentException = Package.class("BadArgumentException").extends(Exception)
    
    --// Constructor
    function BadArgumentException.prototype:constructor(paramName)
        
        error("bad argument '"..paramName.."'")
    end
    
    --// Test
    Exception.throw("BadArgumentException")
]=]
function Package.prototype:extended(subClass: Package,...: any): ()
    
    local filtringIndexes = {"__index", "constructor", "postconstruct",...}
    
    local subPrototype = objectPrototypes[subClass]
    local basePrototype = objectPrototypes[self]
    
    local subMethods = subPrototype.methods
    local subSignals = subPrototype.signal
    
    for name, signalPath in basePrototype.signal do
        
        subSignals[name] = signalPath
    end
    for index, baseMethod in basePrototype.methods do
        
        if table.find(filtringIndexes, index) then continue end
        
        local builtinMethod = Package.prototype[index]
        if builtinMethod and subMethods[index] ~= builtinMethod and subMethods[index] ~= nil and baseMethod == builtinMethod then continue end
        
        subMethods[index] = baseMethod
    end
end
--[=[
    Called when tostring(*self*), print(*self*), warn(*self*), etc
    
    ```lua
    local Exception = Package.class("Exception")
    
    function Exception.prototype:constructor(message, level,...)
        
        self.Message = message:format(...)
        self.Level = level
    end
    
    function Exception.prototype:tostring(message)
        
        return "%s: %s", debug.info(self.Level+1, "s"), message
    end
    function Exception.prototype:components()
        
        return self.Message
    end
    
    local exception = exception.new("Bad argument #1 (%s)", "player")
    print(exception)    --> game.Script: Bad argument #1 (player)
    ```
]=]
function Package.prototype:tostring(...: any): (string, ...any)
    
    return "%t(%*q)", self, {...}
end
--[=[
    Called when *self*.*index* = *value* or *self*[*index*] = *value*
]=]
function Package.prototype:set(index: any, value: any): any
    
    rawset(self, index, value)
end
--[=[
    Called when *self*.*index* or *self*[*index*]
]=]
function Package.prototype:get(index: any): any
    
    return nil
end
--[=[
    Return all components to serialize
    
    ```lua
    local State = Package.class("State")
    
    function State.prototype:constructor(value)
        
        self.Value = value
    end
    
    function State.prototype:components()
        
        return self.Value
    end
    
    local state = State.new(10)
    print(state)    --> State(10)
    ```
]=]
function Package.prototype:components(): ...any
end
--[=[
    Called when *self*:Destroy() is called
    
    ```lua
    --// Class
    local Item = Package.class("Item")
    
    --// Constructor
    function Item.prototype:constructor(itemName: string)
        
        self.Model = game.ReplicatedStorage.Assets[itemName]:Clone()
    end
    
    --// Methods
    function Item.prototype:destroying()
        
        print("destroying model")
        self.Model:Destroy()
    end
    
    --// Test
    local item = Item.new("Sword")
    item:Destroy()
]=]
function Package.prototype:destroying(): ()
end

--// Metamethods
function Package.prototype:__newindex(index, value)
    
    self:set(index, value)
end
function Package.prototype:__concat(value)
    
    return tostring(self)..tostring(value)
end
function Package.prototype:__tostring()
    
    return format(self:tostring(self:components()))
end

--// Class Metatable
function metatable:__call(object: Package,...: any)
    
    throw(2, "ConstructAbstractClassException", self)
end
function metatable:__tostring()
    
    return "$Package"
end

--// Types
local Promise: typeof(require(ReplicatedStorage.Core.Promise))
export type Promise<F, R...> = Promise.Promise<F, R...>

local Signal: typeof(require(ReplicatedStorage.Core.Signal))
export type Connection = Signal.Connection
export type Signal<F> = Signal.Signal<F>

local State: typeof(require(ReplicatedStorage.Core.State))
export type State<V> = State.State<V>

export type integer = number
export type Object = {
    GetState: (Object, stateName: string, defaultValue: any) -> State<any>,
    Destroy: (Object) -> (),
    
    GetType: (Object, value: any) -> string,
    IsSome: (Object, value: any,...string) -> boolean,
    IsA: (Object, value: any,...string) -> boolean,
    
    Destroyed: Signal<() -> ()>
}

export type Class<O> = {
    application: () -> (),
    studio: () -> (),
    running: () -> (),
    editting: () -> (),
    server: () -> (),
    client: () -> (),
    start: () -> (),
    
    async: { [string]: (promise: Promise) -> () },
    signal: { [string]: () -> () },
    
    prototype: O & {
        async: { [string]: (self: O, promise: Promise) -> ...any },
        signal: { [string]: () -> () },
    },
    
    implements: (self: Class,...Class) -> Class,
    extends: (self: Class,...Class) -> Class,
}

--// End
return Package