--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Exception = require(Packages.Core.Exception)
local _expect = require(Packages.Core.Expectation).new

--// Class
return Exception:sub("SkillInCooldown", function(self: Exception.Exception, timeLeft: number)
    
    _expect(timeLeft).is("number"):Argument(1, "timeLeft")
    
    self:Exception("Skill in cooldown, time left: %d", timeLeft)
    self.TimeLeft = timeLeft
end)