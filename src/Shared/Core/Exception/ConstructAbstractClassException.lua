--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)
local _expect = require(Packages.Core.Expectation).new

--// Class
return Exception:sub("ConstructAbstractClassException", function(self: Exception.Exception, Class: Package)
    
    _expect(Class).is("Object"):Throws(4, "BadArgumentException", 1, "Class")
    
    --// Instance
    self:Exception("Attempt to construct a abstract class ($%t)", Class)
    
    self.Class = Class :: PackageClass
end)