--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)

--// Class
return Exception:sub("PromiseCancelledException", function(self: Exception.Exception)
    
    --// Instance
    self:Exception("Promise cancelled")
end)