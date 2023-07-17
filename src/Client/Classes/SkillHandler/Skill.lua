--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local _expect = require(Packages.Core.Expectation).new

--// Class
local Skill = Package.class("Skill").extends(ServerObject)
:: Package.Class<Skill>

--// Constructor
function Skill.prototype:constructor(serverData)
    
    --// Instance
    ServerObject(self, serverData)
    
    self.ReadyTime = nil
    self.Cooldown = nil
    
    self._clientHoldStarted = os.clock()
    self._clientHoldedTime = nil
    
    return self
end

--// Signals
function Skill.prototype.signal.InputReleased() end

--// Methods
function Skill.prototype:GetClientHoldingTime(): number?
    
    if self._clientHoldStarted == nil then return end
    
    return self._clientHoldedTime
        or os.clock() - self._clientHoldStarted
end
function Skill.prototype:IsClientHolding(): boolean
    
    return self._clientHoldStarted ~= nil
end

function Skill.prototype:IsTotallyHolding(): boolean
    
    return self.IsServerHolding and self.IsClientHolding
end
function Skill.prototype:ReleaseRemote(...: any)
    
    return self:_releaseRemote(self:GetClientHoldingTime() or 0,...)
end

--// Protected Methods
function Skill.prototype:_setReadyTime(readyTime: number)
    
    self.ReadyTime = readyTime
end
function Skill.prototype:_setKey(key: Key)
    
    if key:IsHolding() then
        
        key.Released:Once(function()
            
            self._clientHoldStarted = nil
            self.InputReleased()
        end)
    else
        
        self._clientHoldStarted = nil
    end
end

--// End
export type Skill = typeof(Skill.prototype:constructor()) & Package.Object

return Skill.ready() :: typeof(Skill)