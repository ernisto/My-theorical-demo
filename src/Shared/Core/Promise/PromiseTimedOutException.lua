--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)
local _expect = require(Packages.Core.Expectation).new

--// Class
return Exception:sub("PromiseTimedOutException", function(self: Exception.Exception)
    
    --// Instance
    self:Exception("Promise timed out")
end)