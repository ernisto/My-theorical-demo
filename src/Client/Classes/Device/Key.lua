--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local UserInputService = game:GetService("UserInputService")

local _expect = require(Packages.Core.Expectation).new

--// Class
local Key = Package.class("Key")
:: Package.Class<Key> & {
    new: (userInputType: Enum.UserInputType?, keyCode: Enum.KeyCode?) -> Key
}

--// Constructor
function Key.prototype:constructor(userInputType: Enum.UserInputType?, keyCode: Enum.KeyCode?)
    
    keyCode = keyCode or Enum.KeyCode.Unknown
    
    _expect(userInputType).is.some("EnumItem", "nil"):Argument(1, "userInputType")
    _expect(keyCode).is.some("EnumItem", "nil"):Argument(2, "keyCode")
    
    --// Instance
    self.UserInputType = userInputType
    self.KeyCode = keyCode
    
    self.EngineProcessed = nil :: boolean?
    self.HoldTimestamp = nil   :: number?
    
    --// Setup
    UserInputService.InputBegan:Connect(function(inputObject, engineProcessed)
        
        if inputObject.KeyCode == keyCode and inputObject.UserInputType == userInputType then
            
            self:Hold(engineProcessed)
        end
    end)
    UserInputService.InputEnded:Connect(function(inputObject, engineProcessed)
        
        if inputObject.KeyCode == keyCode and inputObject.UserInputType == userInputType then
            
            self:Release()
        end
    end)
    
    return self
end

--// Signals
function Key.prototype.signal.Changed(isDown: boolean, engineProcessed: boolean) end
function Key.prototype.signal.Released(engineProcessed: boolean) end
function Key.prototype.signal.Holded(engineProcessed: boolean) end

--// Methods
function Key.prototype:GetHoldingTime(): number?
    
    if not self.HoldTimestamp then return end
    return os.clock() - self.HoldTimestamp
end
function Key.prototype:IsHolding(engineProcessed: boolean?): boolean
    
    _expect(engineProcessed).is.some("boolean", "nil"):Argument(1, "engineProcessed")
    
    return if engineProcessed == nil
        then self.EngineProcessed ~= nil
        else self.EngineProcessed == engineProcessed
end

function Key.prototype:Hold(engineProcessed: boolean)
    
    if self.EngineProcessed ~= nil then return end
    
    self.EngineProcessed = engineProcessed
    self.HoldTimestamp = os.clock()
    
    self.Holded(engineProcessed)
    self.Changed(true, engineProcessed)
end
function Key.prototype:Release()
    
    local engineProcessed = self.EngineProcessed
    if engineProcessed == nil then return end
    
    self.Released(engineProcessed)
    self.Changed(false, engineProcessed)
    
    self.EngineProcessed = nil
    self.HoldTimestamp = nil
end

function Key.prototype:__mul(seconds: number)
    
    _expect(seconds).is("number"):Argument(1, "seconds")
    
    local longKey = Key.new()
    local lastPressId
    
    self.Released:Connect(longKey.Release, longKey)
    self.Holded:Connect(function(engineProcessed)
        
        local pressId = {}
        lastPressId = pressId
        
        task.wait(seconds)
        
        if lastPressId ~= pressId then return end
        longKey:Hold(engineProcessed)
    end):Async(true)
    
    return longKey
end
function Key.prototype:__pow(count: integer)
    
    _expect(count).is("integer"):Argument(1, "count")
    
    local sequenceKey = Key.new()
    local pressStreak = 0
    local lastPressId
    
    self.Holded:Connect(function(engineProcessed)
        
        local pressId = {}
        lastPressId = pressId
        
        pressStreak += 1
        
        if pressStreak == count then
            
            sequenceKey:Hold(engineProcessed)
            pressStreak = 0
            
            self, engineProcessed = self.Released:Await()
            sequenceKey:Release()
        else
            
            task.wait(.5)
            
            if lastPressId ~= pressId then return end
            pressStreak = 0
        end
    end)
    
    return sequenceKey
end
function Key.prototype:__add(key2: Key)
    
    _expect(key2).is("Key"):Argument(1, "key2")
    
    local keyCombination = Key.new()
    
    self.Released:Connect(keyCombination.Release, keyCombination)
    self.Holded:Connect(function(engineProcessed)
        
        if key2:IsHolding() then
            
            keyCombination:Hold(engineProcessed or key2.EngineProcessed)
        end
    end)
    
    key2.Released:Connect(keyCombination.Release, keyCombination)
    key2.Holded:Connect(function(engineProcessed)
        
        if self:IsHolding() then
            
            keyCombination:Hold(engineProcessed or self.EngineProcessed)
        end
    end)
    
    return keyCombination
end
function Key.prototype:__div(key2: Key)
    
    _expect(key2).is("Key"):Argument(1, "key2")
    
    local keyGroup = Key.new()
    
    self.Released:Connect(keyGroup.Release, keyGroup)
    self.Holded:Connect(keyGroup.Hold, keyGroup)
    
    key2.Released:Connect(keyGroup.Release, keyGroup)
    key2.Holded:Connect(keyGroup.Hold, keyGroup)
    
    return keyGroup
end

function Key.prototype:components()
    
    return if self.EngineProcessed == true then "engine processed" elseif self.EngineProcessed == false then "game processed" else "released"
end

--// End
export type Key = typeof(Key.prototype:constructor()) & {
    Changed: Signal<(isHolding: boolean, engineProcessed: boolean) -> ()>,
    Released: Signal<(engineProcessed: boolean) -> ()>,
    Holded: Signal<(engineProcessed: boolean) -> ()>,
}

return Key