--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local format = require(Packages.Core.Format)
local _expect = require(Packages.Core.Expectation).new
local getType = Package.GetType

--// Class
local Exception = Package.class("Exception")
:: Package.Class<Exception>

--// Vars
local exceptions = { Exception = Exception.new }

--// Class Functions
function Exception.getEmitterData(level: integer, extra: {[string]: any}?)
    
    level = level or 1
    extra = extra or {}
    
    _expect(level).is("integer"):Argument(1, "level")
    _expect(extra).all.index.is("string"):Argument(2, "extra")
    
    level = if level > 0 then level+1 else 0
    
    local line, path, func, funcName = debug.info(level, "lsfn")
    local script = getfenv(level).script
    local scriptName = script.Name
    
    local data = {
        EmitterFunctionName = funcName,
        EmitterFunction = func,
        EmitterName = scriptName,
        EmitterPath = path,
        EmitterLine = line,
        
        EmitterTraceback = Package.traceback(level),
        EmitterThread = coroutine.running(),
        EmitterScript = script,
    }
    
    for index, value in extra do data[index] = value end
    return data
end
function Exception.create(exceptionName: string, emitterData: {any}, level: integer,...: any): Exception
    
    _expect(exceptionName).is("string"):Argument(1, "exceptionName")
    _expect(exceptions[exceptionName]):ThrowsMessage(2, "Invalid exception name '%s'", exceptionName)
    _expect(emitterData).is("table"):Argument(2, "emitterData")
    _expect(level).is("integer"):Argument(3, "level")
    
    return exceptions[exceptionName](emitterData, level,...)
end
function Exception.throw(level: integer, exceptionName: string,...: any)
    
    _expect(level).is("integer"):Argument(1, "level")
    _expect(exceptionName).is("string"):Argument(2, "exceptionName")
    
    level = if level > 0 then level+1 else 0
    
    error(Exception.create(exceptionName, Exception.getEmitterData(2), level,...), 0)
end

--// Constructor
function Exception.prototype:constructor(emitterData: {[string]: any}, level: integer,...: any)
    
    _expect(emitterData).is("table"):Argument(1, "emitterData")
    _expect(level).is("integer"):Argument(2, "level")
    
    --// Instance
    if level > 0 then
        
        local internalLevel = level+3
        local path, line, func, funcName = debug.info(internalLevel, "slfn")
        local environment = if func then getfenv(level) else {}
        local script = environment.script
        
        self.Name = if script then script.Name else nil
        self.FunctionName = funcName
        self.Function = func
        self.Path = path
        self.Line = line
        
        self.Traceback = Package.traceback(internalLevel)
        self.Thread = coroutine.running()
        self.Script = script
    end
    
    self.Message = "No exception message"
    self.Level = level
    
    self._emitterData = emitterData
    self._hasThrowed = false
    self._arguments = {...}
    
    for index, value in emitterData do
        
        self[index] = value
    end
    
    --// Setup
    self[getType(self)](self,...)
    return self
end

--// Methods
function Exception.prototype:Exception(message: string,...: any)
    
    _expect(message).is("string"):Throws(4, "BadArgumentException", 2, "message")
    
    --// Instance
    self.Message = format(message,...)
end
function Exception.prototype:Throw(level: integer)
    
    level = level or 1
    
    _expect(level).is("integer"):Argument(1, "level")
    
    if self._hasThrowed then return end
    self._hasThrowed = true
    
    level = if level > 0 then level+1 else 0
    
    error(Exception.create(getType(self), self._emitterData, level, self:components()), 0)
end

function Exception.prototype:sub(exceptionName: string, constructor: (self: Exception) -> Exception): Package.Class<Exception>
    
    _expect(exceptionName).is("string"):Argument(1, "exceptionName")
    _expect(constructor).is("function"):Argument(2, "constructor")
    
    local SubException = Package.class(exceptionName).extends(self)
    
    SubException.prototype[exceptionName] = constructor
    return SubException
end

--// Behaviour
function Exception.prototype:components()
    
    return unpack(self._arguments, 1, self._arguments.n)
end
function Exception.prototype:tostring()
    
    if self.Level > 0 then
        
        return "%s:%s: %s%s", self.Path, self.Line, self.Message, self.Traceback
    else
        
        return self.Message
    end
end

function Exception.prototype:extended(subException,...)
    
    Package.extended(self, subException,...)
    
    local exceptionName = getType(subException)
    
    subException.prototype.constructor = Exception.constructor
    exceptions[exceptionName] = subException.new
    self[exceptionName] = subException
end

--// End
export type Exception = typeof(Exception.prototype:constructor())

return Exception