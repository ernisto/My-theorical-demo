--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)

--// Class
return Exception:sub("EventCancelledException", function(self: Exception.Exception)
    
    --// Instance
    self:Exception("Event cancelled")
end)