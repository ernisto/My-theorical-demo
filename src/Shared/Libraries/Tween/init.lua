--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, R...> = Package.Promise<F, R...>

--// Packages
local _expect = require(Packages.Core.Expectation).new

local lerpers = require(script.Lerpers)
local styles = require(script.Styles)
local isA = Package.IsA

--// Class
local Tween = Package.class("Tween")
:: Package.Class<Tween> & {
    new: <V>(callback: (value: V) -> (), tweenInfo: TweenInfo|tweenInfo, origin: V, goal: V) -> Tween
}

--// Class Vars
Tween.styles = styles

--// Class Functions
function Tween.object(object, goals: {[string]: any}, origins: {[string]: any}): Tween
    
    local params = {}
    
    return Tween.new(function(multiplier)
        
        for property, lerper in params do
            
            local lerp, origin, goal = lerper[1], lerper[2], lerper[3]
            object[property] = lerp(origin, goal, multiplier)
        end
    end)
end

--// Constructor
function Tween.prototype:constructor<V>(callback: (value: V) -> (), tweenInfo: TweenInfo|tweenInfo, origin: V, goal: V)
    
    origin = origin or 0
    goal = goal or 0
    
    local originValue, goalValue = origin, goal do
        
        if isA(origin, "State") then
            
            originValue = origin.Value
            if origin.Constant then origin = originValue end
        end
        if isA(goal, "State") then
            
            goalValue = goal.Value
            if goal.Constant then goal = goalValue end
        end
    end
    
    _expect(callback).is("function"):Argument(1, "callback")
    _expect(tweenInfo).is.some("table", "TweenInfo"):Argument(2, "tweenInfo")
    _expect(originValue).is.some("State", "number", "boolean", "UDim", "UDim2", "Color3", "Vector2", "Vector3", "CFrame", "NumberRange", "NumberSequence", "ColorSequence"):Argument(3, "origin")
    _expect(goalValue).is.some("State", typeof(originValue)):Argument(4, "goal")
    
    local getLerper = lerpers[typeof(originValue)]
    
    if typeof(tweenInfo) == "TweenInfo" then
        
        tweenInfo = {
            Style = styles[tweenInfo.EasingDirection.Name..tweenInfo.EasingStyle.Name],
            RepeatCount = tweenInfo.RepeatCount,
            Reverses = tweenInfo.Reverses,
            Duration = tweenInfo.Time,
        }
    end
    
    --// Instance
    self.RepeatCount = tweenInfo.RepeatCount or 0
    self.Reverses = tweenInfo.Reverses or false
    self.Duration = tweenInfo.Duration or 0
    self.ReverseDelay = 0
    self.RepeatDelay = 0
    
    self.Reversing = false
    self.Repeateds = 0
    
    self._lerper, self._param1, self._param2 = getLerper(originValue, goalValue)
    self._getMultiplier = tweenInfo.Style or styles.Linear
    self._getLerper = getLerper
    self._callback = callback
    self._origin = originValue
    self._goal = goalValue
    
    self._thread = task.spawn(self._updater, self, origin, goal)
    self._started = nil
    self._lastFade = 0
    
    return self
end

--// Methods
function Tween.prototype.async:ResumeAsync(promise, delay: number?, fade: number?, reversing: boolean?): number
    
    _expect(delay).is.some("number", "nil"):Argument(1, "delay")
    _expect(fade).is.some("number", "nil"):Argument(2, "fade")
    _expect(reversing).is.some("boolean", "nil"):Argument(3, "reversing")
    
    promise:Catch("PromiseCancelledException")
    
    if delay > 0 then delay -= task.wait(delay) end
    
    reversing = if reversing ~= nil then reversing else self.Reversing
    fade = if fade ~= nil then fade else self:GetFade()
         + delay/self.Duration
    
    self._runningData = {fade, reversing, promise}
    if not self._started then task.spawn(self._thread, self) end
    
    coroutine.yield()
end
function Tween.prototype.async:StopAsync(promise, delay: number): ()
    
    _expect(delay).is("number"):Argument(1, "delay")
    
    task.wait(delay)
    self:Stop()
end
function Tween.prototype:Stop(): ()
    
    self._runningData = nil
end

function Tween.prototype:IsFinished(isReversing: boolean?): boolean
    
    _expect(isReversing).is.some("boolean", "nil"):Argument(1, "isReversing")
    
    if isReversing == nil then
        
        return self._lastFade == 0 or self._lastFade == 1
    else
        
        return if isReversing then self._lastFade == 0 else self._lastFade == 1
    end
end
function Tween.prototype:IsPlaying(): boolean
    
    return self._started ~= nil
end
function Tween.prototype:GetFade(): number
    
    local fade = self._lastFade or math.clamp((os.clock() - self._started) / self.Duration, 0, 1)
    
    return if self.Reversing then 1-fade else fade
end

function Tween.prototype:Lerp(fade: number): any
    
    _expect(fade).is("number"):Argument(1, "fade")
    
    local multiplier = self._getMultiplier(fade)
    local value = self._from + self._delta*multiplier
    
    self._callback(value)
    return value
end

--// Private Methods
function Tween.prototype:_updater(originState, goalState)
    
    local getLerper, origin, goal = self._getLerper, self._origin, self._goal
    local lerper, param1, param2 = self._lerper, self._param1, self._param2
    local callback, getMultiplier = self._callback, self._getMultiplier
    
    local reverseDelay = self.ReverseDelay
    local repeatDelay = self.RepeatDelay
    local repeatCount = self.RepeatCount
    local reverses = self.Reverses
    local duration = self.Duration
    
    --// Update From|To
    if isA(originState, "State") then
        
        origin.Changed:Connect(function(newOrigin)
            
            origin = newOrigin
            lerper, param1, param2 = getLerper(origin, goal)
        end)
    end
    if isA(goalState, "State") then
        
        goalState.Changed:Connect(function(newGoal)
            
            goal = newGoal
            lerper, param1, param2 = getLerper(origin, goal)
        end)
    end
    
    originState = nil
    goalState = nil
    self = nil
    
    --// Loop
    local fade, reversing, promise
    local runningData
    
    while true do
        
        local self = coroutine.yield()
        local started = os.clock()
        
        self._started = started
        self._lastFade = nil
        
        --// Loop
        local secondsOverflow = 0
        local completed = false
        local repeateds = 0
        
        repeat
            if self._runningData ~= runningData then
                
                if promise then promise = promise:Cancel() end
                
                runningData = self._runningData
                if not runningData then break end
                
                fade, reversing, promise = unpack(runningData)
                duration = math.abs(duration)
                
                if reversing then duration = -duration end
            end
            
            --// Fading
            fade += task.wait()/duration
            
            if fade >= 1 or fade <= 0 then
                
                local currentTime = os.clock()
                
                while currentTime > started + duration do
                    
                    if reverses and not reversing then
                        
                        started += reverseDelay + duration
                        reversing = true
                        
                    elseif repeateds ~= repeatCount then
                        
                        started += repeatDelay + duration
                        reversing = false
                        repeateds += 1
                    else
                        
                        secondsOverflow = currentTime - started - duration
                        completed = true
                        break
                    end
                end
                
                fade = if completed
                     then (if reversing then 0 else 1)
                     else (currentTime - started) / duration
                
                self.Reversing = reversing
                self.Repeateds = repeateds
                self._started = started
            end
            
            --// Lerp
            local multiplier = getMultiplier(fade)
            callback(lerper(param1, param2, multiplier))
            
        until completed
        
        --// Finished
        if promise then task.defer(promise.Resolve, promise, secondsOverflow) end
        
        self._runningData = nil
        self._lastFade = fade
        self._started = nil
    end
end

--// Behaviour
function Tween.prototype:destroying()
    
    coroutine.close(self._thread)
    self:Stop()
end
function Tween.prototype:components()
    
    return self.Duration, debug.info("n", self.Style) or "unknown style"
end

--// End
export type tweenInfo = {
    Duration: number,
    Style: (fade: number) -> number?,
    Reverses: boolean?,
    RepeatCount: integer?,
}
export type Tween = typeof(Tween.prototype:constructor()) & {
    ResumeAsync: (self: Tween, delay: number?, fade: number?, reversing: boolean?) -> Promise<(secondsOverflow: number) -> (), number>,
    StopAsync: (self: Tween, delay: number) -> Promise<() -> ()>
}

return Tween