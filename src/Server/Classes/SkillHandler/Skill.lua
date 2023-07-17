--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local tryPromise = require(Packages.Core.Promise).try

--// Class
local Skill = Package.class("Skill").extends(RemoteObject)
:: RemoteObject.Class<Skill> & {
    new: (handler: (skill: Skill,...any) -> (), player: Player,...any) -> Skill
}

--// Constructor
function Skill.prototype:constructor(handler: (skill: Skill,...any) -> (), player: Player,...: any)
    
    _expect(handler).is("function"):Argument(1, "handler")
    _expect(player).is("Player"):Argument(2, "player")
    
    --// Instance
    RemoteObject(self)
    self.client.Duration = nil
    
    self.StageReadyTimes = { 0 }
    self.StageCooldowns = { 0 }
    self.Player = player
    self.Stage = 1
    
    self._promise = tryPromise(handler, self,...)
    self._durationTask = nil :: thread?
    self._clientHoldedTime = 0
    self._clientStates = {}
    self._releaseData = {}
    self._approveData = {}
    
    self._holdStarted = os.clock()
    self._holdedTime = nil
    
    self.client:EnableReplicatesWhenRequest(false)
    self.client:SetPlayers{ player }
    
    return self
end

--// Remote Signals
function Skill.prototype.client.signal.Approved(readyTime: number,...: any) end
function Skill.prototype.client.signal.Released(...: any) end

--// Remote Methods
function Skill.prototype.client:SetStateRemote(name: string, value: any)
    
    expect(type(name) == "string", "Invalid argument #1 (name) to 'Skill:SetRemoteState' (string expected)")
    expect(self._clientStates[name], "Invalid state name '%s'", name)
    
    self:_setState(name, value)
end

--// Private Remote Methods
function Skill.prototype.client:_releaseRemote(player, clientHoldedTime: number,...: any): number
    
    expect(type(clientHoldedTime) == "number", "Invalid argument #1 (clientHoldedTime) to 'Skill:ReleaseRemote' (number expected)")
    
    self._clientHoldedTime = clientHoldedTime
    self:Release(...)
    
    self._promise:Then(task.wait, 0):Then(self.Destroy, self)
    return self.Cooldown, self._promise:Expect()
end

--// Methods
function Skill.prototype:SetStageCooldown(stage: number, stageCooldown: number)
    
    _expect(stage).is("integer"):Argument(1, "stage")
    _expect(stageCooldown).is("number"):Argument(2, "cooldown")
    
    self.StageCooldowns[stage] = stageCooldown
end
function Skill.prototype:SetCooldown(cooldown: number)
    
    _expect(cooldown).is("number"):Argument(1, "cooldown")
    
    self.StageCooldowns[1] = cooldown
end
function Skill.prototype:SetDuration(duration: number,...: any)
    
    _expect(duration).is("number"):Argument(1, "duration")
    
    if self._durationTask then task.cancel(self._durationTask) end
    self._durationTask = task.delay(duration, self.Release, self,...)
    
    self.Destroyed:Connect(task.cancel, self._durationTask)
    self:_setState("Duration", duration)
end

function Skill.prototype:AwaitReadyTime(...: number): number?
    
    _expect(...).is("number"):Argument(1, "stageReadyTime")
    
    self.StageReadyTimes = {...}
    self.Released:AwaitWithTimeout(select(-1,...))
    
    local holdTime = self:GetHoldingTime()
    local holdedStage: number?
    
    for stage, stageReadyTime in {...} do
        
        if holdTime >= stageReadyTime then holdedStage = stage end
    end
    
    self.Stage = holdedStage
    return holdedStage
end
function Skill.prototype:EnableClientStates(...: string)
    
    for _,index in {...} do
        
        self._clientStates[index] = true
    end
end
function Skill.prototype:GetReleaseData(): ...any
    
    return unpack(self._releaseData)
end

function Skill.prototype:GetClientHoldingTime(): number?
    
    return self._clientHoldedTime
end
function Skill.prototype:GetHoldingTime(): number
    
    return self._holdedTime
        or os.clock() - self._holdStarted
end
function Skill.prototype:IsHolding(): boolean
    
    return self._holdStarted ~= nil
end

function Skill.prototype:DeferApprove(...: any)
    
    task.defer(self._approve, self,...)
end
function Skill.prototype:Release(...: any)
    
    if not self:IsHolding() then return end
    self:_release(...)
end

--// Private Methods
function Skill.prototype:_approve(...: any)
    
    self._approveData = {...}
    self.Approved(self.StageReadyTimes,...)
end
function Skill.prototype:_release(...: any)
    
    self._holdedTime = self:GetHoldingTime()
    self._holdStarted = nil
    
    self._releaseData = {...}
    self.Released(...)
end

--// End
export type Skill = typeof(Skill.prototype:constructor()) & Package.Object

return Skill