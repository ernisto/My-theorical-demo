--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception: typeof(require(Packages.Core.Exception))
local getEmitterData: typeof(Exception.getEmitterData)
local createException: typeof(Exception.create)
local throw: typeof(Exception.throw)

local isSome = Package.IsSome
local isA = Package.IsA

task.defer(function()
    
    Exception = require(Packages.Core.Exception)
    getEmitterData = Exception.getEmitterData
    createException = Exception.create
    throw = Exception.throw
end)

--// Class
local Expectation = Package.class("Expectation")
:: Package.Class<Expectation> & {
    new: (...any) -> step1,
}

--// Functions
local function defaultCheck(value,...) return value end

local function equalsSome(value1,...)
    
    for _,value in {...} do
        
        if value1 == value then return true end
    end
    
    return false
end
local function equals(value1,...)
    
    for _,value in {...} do
        
        if value1 ~= value then return false end
    end
    
    return true
end

local function equalsIgnoreCaseSome(value1,...)
    
    if type(value1) ~= "string" then return false end
    
    value1 = value1:lower()
    
    for _,value in {...} do
        
        if value1 == value:lower() then return true end
    end
    
    return false
end
local function equalsIgnoreCase(value1,...)
    
    if type(value1) ~= "string" then return false end
    
    value1 = value1:lower()
    
    for _,value in {...} do
        
        if value1 ~= value:lower() then return false end
    end
    
    return true
end

local function containsSome(table, checker, isIndex,...)
    
    if type(table) ~= "table" then return false end
    
    if isIndex then
        
        for index in table do
            
            if checker(index,...) then return true end
        end
    else
        
        for _,value in table do
            
            if checker(value,...) then return true end
        end
    end
    
    return false
end
local function contains(table, checker, isIndex,...)
    
    if type(table) ~= "table" then return false end
    
    if isIndex then
        
        for index in table do
            
            if not checker(index,...) then return false end
        end
    else
        
        for _,value in table do
            
            if not checker(value,...) then return false end
        end
    end
    
    return true
end

local function checker1(modifiers, value,...)
    
    local _checker2 =
        if modifiers.equals then
        (
            if modifiers.ignorecase then
            (
                if modifiers.some2 then equalsIgnoreCaseSome else equalsIgnoreCase
            ) else
            (
                if modifiers.some2 then equalsSome else equals
            )
        )
        elseif modifiers.is then
        (
            if modifiers.some2 then isSome else isA
        )
    else defaultCheck
    
    local checker2 = if modifiers.nt then function(...) return not _checker2(...) end else _checker2
    
    --// Check
    if modifiers.all1 then
        
        local result = contains(value, checker2, modifiers.index,...)
        return if modifiers.none then not result else result
        
    elseif modifiers.some1 then
        
        local result = containsSome(value, checker2, modifiers.index,...)
        return if modifiers.none then not result else result
    else
        
        return checker2(value,...)
    end
end

--// Class Functions
function Expectation.assertMessage(value: any, message: string,...: any)
    
    if not value then throw(3, "Exception", message,...) end
    return value
end
function Expectation.assert(value: any, exceptionName: string,...: any)
    
    if not value then throw(3, exceptionName,...) end
    return value
end

--// Constructor
function Expectation.prototype:constructor(...: any)
    
    --// Instance
    self._expectationMessage = "false or nil unexpected"
    
    self._totalValues = select("#",...)
    self._arguments = {}
    self._modifiers = {}
    self._values = {...}
    return self
end

--// Methods
function Expectation.prototype:Argument(argumentCount: integer, ...: string): any...
    
    return self:_throws(2, "BadArgumentException", argumentCount,...)
end
function Expectation.prototype:ThrowsMessage(level: integer, message: string,...: any): any...
    
    --if not isA(level, "integer") then throw(2, "BadArgumentException", 1, level, "integer expected", 1, "level") end
    --if not isA(message, "string") then throw(2, "BadArgumentException", 1, message, "string expected", 2, "message") end
    
    return self:_throws(level, "Exception", message,...)
end
function Expectation.prototype:Throws(level: integer, exceptionName: string,...: any): any...
    
    --if type(level) ~= "number" then throw(2, "BadArgumentException", 1, level, "integer expected", 1, "level") end
    --if not isSubClass(exceptionName, "Exception") then throw(2, "BadArgumentException", 2, exceptionName, "$"..tostring(exceptionName).." is not a Exception class", 1, "exceptionName") end
    
    return self:_throws(level, exceptionName,...)
end
function Expectation.prototype:Warns(level: integer, exceptionName: string,...: any): any...
    
    --if type(level) ~= "number" then throw(2, "BadArgumentException", 1, level, "integer expected", 1, "level") end
    --if not isSubClass(exceptionName, "Exception") then throw(2, "BadArgumentException", 2, exceptionName, "$"..tostring(exceptionName).." is not a Exception class", 1, "exceptionName") end
    
    local success, badValueCount, badValue = self:Check()
    
    if not success then
        
        level = if level > 0 then level+2 else 0
        
        local emitterData = getEmitterData(3, {
            ExpectationMessage = self._expectationMessage,
            BadValueCount = badValueCount,
            BadValue = badValue,
        })
        
        local exceptionCreated, exception = pcall(createException, exceptionName, emitterData, level,...)
        
        if exceptionCreated then
            
            warn(exception)
        else
            
            error(exception, 2)
        end
    end
end

function Expectation.prototype:Check(...: any): (boolean, integer?, any?)
    
    local arguments = self._arguments
    local modifiers = self._modifiers
    local values = self._values
    
    for count = 0, self._totalValues do
        
        if count == 0 then continue end
        local value = values[count]
        
        if not checker1(modifiers, value, unpack(arguments)) then return false, count, value end
    end
    
    values = {...}
    
    for count = 0, select("#",...) do
        
        if count == 0 then continue end
        local value = values[count]
        
        if not checker1(self, value, unpack(arguments)) then return false, self._totalValues + count, value end
    end
    
    return true
end

--// Private Methods
function Expectation.prototype:_throws(level: integer, exceptionName: string,...: any): any...
    
    --if type(level) ~= "number" then throw(2, "BadArgumentException", 1, level, "integer expected", 1, "level") end
    --if type(exceptionName) ~= "string" then throw(2, "BadArgumentException", 2, exceptionName, "string expected", 1, "exceptionName") end
    --if not isSubClass(exceptionName, "Exception") then throw(2, "BadArgumentException", 2, exceptionName, "$"..exceptionName.." is not a Exception class", 1, "exceptionName") end
    
    local success, badValueCount, badValue = self:Check()
    
    if not success then
        
        level = if level > 0 then level+2 else 0
        
        local emitterData = getEmitterData(3, {
            ExpectationMessage = self._expectationMessage,
            BadValueCount = badValueCount,
            BadValue = badValue,
        })
        
        local exceptionCreated, exception = pcall(createException, exceptionName, emitterData, level,...)
        
        if exceptionCreated then
            
            exception:Throw(level)
        else
            
            error(exception, 3)
        end
    end
    
    return unpack(self._values, 1, self._totalValues)
end

--// Behaviour
function Expectation.prototype:__call(...): Expectation
    
    local totalArguments = select("#",...)
    local modifiers = self._modifiers
    local expectationMessage = ""
    local whitelistText = ""
    
    --// Concat Arguments
    if totalArguments > 1 then
        
        whitelistText = string.rep(if modifiers.equals then "%q, " else "%s, ", totalArguments-1)
        whitelistText = whitelistText:sub(1, -3)..if modifiers.some2 then " or " else " and "
    end
    
    whitelistText ..= if modifiers.equals then "%q" else "%s"
    
    --// Concat Table Modifier
    if modifiers.value or modifiers.index then
        
        expectationMessage = ""
            ..(if modifiers.all1 then "all " else "some ")
            ..(if modifiers.value then "value " else "index ")
            ..(if modifiers.is then "of type " else "equals ")
    end
    
    expectationMessage ..= whitelistText:format(...)    -- adjust format
        ..(if modifiers.nt then " unexpected" else " expected")
    
    --// Release
    self._expectationMessage = expectationMessage
    self._arguments = {...}
    
    return self
end
function Expectation.prototype:get(index: string): Expectation
    
    --if type(index) ~= "string" then throw("BadArgumentException", 1, index, "string expected", 2, 1, "index") end
    
    local newIndex = index:lower()
    local modifiers = self._modifiers
    local inStep2 = modifiers.is or modifiers.equals
    
    if newIndex == "all" then
        
        newIndex = if inStep2 then "all2" else "all1"
        
    elseif newIndex == "some" then
        
        newIndex = if inStep2 then "some2" else "some1"
        
    elseif newIndex == "none" then
        
        assert(not inStep2, "Unexpected modifier 'none' after modifier 'is' or 'equals'")
        
    elseif newIndex == "index" then
        
        assert(modifiers.some1 or modifiers.all1 or modifiers.none, "Unexpected modifier 'index' before modifier 'none', 'some' or 'all'")
        assert(not modifiers.value, "Unexpected modifier 'index' and 'value' at same Expectation")
        
    elseif newIndex == "value" then
        
        assert(modifiers.some1 or modifiers.all1 or modifiers.none, "Unexpected modifier 'value' before modifier 'none', 'some' or 'all'")
        assert(not modifiers.index, "Unexpected modifier 'index' and 'value' at same Expectation")
        
    elseif newIndex == "is" then
        
        assert(not modifiers.equals, "Unexpected modifier 'is' and 'equals' at same Expectation")
        
    elseif newIndex == "equals" then
        
        assert(not modifiers.is, "Unexpected modifier 'equals' and 'is' at same Expectation")
        
    elseif newIndex == "ignorecase" then
        
        assert(modifiers.equals, "Unexpected modifier 'ignorecase' with no modifier 'equals' before")
        
    elseif newIndex == "nt" then
        
        assert(inStep2, "Unexpected modifier 'nt' before modifier 'is' or 'equals'")
    else
        
        error("Invalid modifier '"..index.."' to a Expectation")
    end
    
    assert(not modifiers[newIndex], "Modifier '"..index.."' already used")
    
    modifiers[newIndex] = true
    return self
end
function Expectation.prototype:components()
    
    return self._expectationMessage
end

--// Types
type expectationSchema2 = Expectation & {
    equals: {
        nt: {
            some: {
                ignorecase: Expectation,
            },
            all: {
                ignorecase: Expectation,
            },
            ignorecase: Expectation,
        },
        some: {
            ignorecase: Expectation,
        },
        all: {
            ignorecase: Expectation,
        },
        ignorecase: Expectation,
    },
    is: {
        nt: {
            some: Expectation,
            all: Expectation,
        },
        some: Expectation,
        all: Expectation,
    },
}
type expectationSchema1 = expectationSchema2 & {
    none: {
        index: expectationSchema2,
        value: expectationSchema2,
    },
    some: {
        index: expectationSchema2,
        value: expectationSchema2,
    },
    all: {
        index: expectationSchema2,
        value: expectationSchema2,
    },
}

--// End
export type Expectation = typeof(Expectation.prototype:constructor())

return Expectation