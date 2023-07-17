--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local _expect = require(Packages.Core.Expectation).new

--// Class
local SkillHandler = Package.class("SkillHandler").extends(ServerObject)

--// Constructor
type inputHandler = (handler: Skill, input: Key) -> ()

function SkillHandler.prototype:constructor(serverData, name: string)
    
    --// Instance
    ServerObject(self, serverData)
    
    self.Name = name
    self.Key = nil :: Key?
    self.IsEnabled = self._everyoneAllowed
    
    self._inputConnection = nil :: Connection?
    self._inputHandler = nil :: inputHandler?
    
    self._exceptionHandlers = {}
    
    --// Listeners
    self.Enabled:Connect(function()
        
        self.IsEnabled = true
    end)
    self.Disabled:Connect(function()
        
        self.IsEnabled = false
    end)
    
    return self
end

--// Methods
function SkillHandler.prototype:SetInputHandler(key: Key, inputHandler: inputHandler)
    
    inputHandler = inputHandler or self._inputHandler
    
    _expect(key).is("Key"):Argument(1, "key")
    _expect(inputHandler).is("function"):Argument(2, "inputHandler")
    
    if self._inputConnection then self._inputConnection:Destroy() end
    
    self._inputConnection = self:Hoste(key.Holded:Connect(function(engineProcessed)
        
        if engineProcessed then return end
        if not self.IsEnabled then return end
        
        local promise = self:HoldRemote()--:Timeout(5)
        for exceptionName, exceptionHandler in self._exceptionHandlers do promise:Catch(exceptionName, exceptionHandler, self) end
        
        local result = {promise:Await()}
        local success, skill, readyTime = result[1], result[2], result[3]
        
        if not success then return end
        skill:_setReadyTime(readyTime)
        skill:_setKey(key)
        
        inputHandler(skill, unpack(result, 4))
        if not skill:IsClientHolding() then return end
        
        warn(`skill '{self.Name}' not manually released`)
        skill:ReleaseRemote()
    end))
    
    self._inputHandler = inputHandler
    self.Key = key
    
    return self
end
function SkillHandler.prototype:Catch(exceptionName: string, exceptionHandler: (exception: string) -> ())
    
    _expect(exceptionName).is("string"):Argument(1, "exceptionName")
    _expect(exceptionHandler).is("function"):Argument(2, "exceptionHandler")
    
    self._exceptionHandlers[exceptionName] = exceptionHandler
    return self
end

--// End
export type SkillHandler = typeof(SkillHandler.prototype:constructor()) & Package.Object

return SkillHandler.ready() :: typeof(SkillHandler)