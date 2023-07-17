--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)
local _expect = require(Packages.Core.Expectation).new

--// Class
return Exception:sub("BadArgumentException", function(self: Exception.Exception, argumentCount: string,...: string)
    
    argumentCount = argumentCount or 1
    
    _expect(argumentCount).is.some("integer", "nil"):Throws(4, "BadArgumentException", 1, "argumentCount")
    _expect(...).is.some("string", "nil"):Throws(4, "BadArgumentException", 2, "argumentName")
    
    local expectationMessage = self.ExpectationMessage or "unknown expected"
    local badValueCount = self.BadValueCount or 1
    local badValue = self.BadValue or nil
    
    local argumentName = if ... ~= nil
        then (select(badValueCount,...) or select(-1,...)):gsub("%%", "%%")
        else nil
    
    argumentCount += badValueCount - 1
    
    local argumentMessage = "argument #"..argumentCount..(if argumentName then " ("..argumentName..")" else "")
    local emitterMessage = (if self.EmitterName then "$"..self.EmitterName else "").." "..(self.EmitterFunctionName or "anonymous")
    
    --// Instance
    self:Exception("Invalid %s to '%s' (%s, got %t(%v))", argumentMessage, emitterMessage, expectationMessage, badValue, badValue)
    
    self.ArgumentCount = argumentCount
    self.ArgumentName = argumentName
end)