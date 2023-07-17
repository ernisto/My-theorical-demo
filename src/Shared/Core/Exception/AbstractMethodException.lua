--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)

--// Class
return Exception:sub("AbstractMethodException", function(self: Exception.Exception)
    
    --// Instance
    self:Exception("Attempt to call a abstract method '%s %s'", self.EmitterName, self.EmitterFunctionName)
end)