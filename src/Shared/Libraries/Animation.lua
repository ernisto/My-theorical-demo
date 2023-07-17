--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, R...> = Package.Promise<F, R...>

--// Packages
local TweenState = require(Packages.Libraries.Tween.TweenState)
local schematicTweenState = TweenState.schema
type TweenSchema = TweenState.TweenSchema

local Promise = require(Packages.Core.Promise)
local _expect = require(Packages.Core.Expectation).new

--// Class
local Animation = Package.class("Animation")
:: Package.Class<Animation> & {
    new: (duration: number) -> Animation,
}

--// Constructor
function Animation.prototype:constructor(duration: number)
    
    duration = duration or 0
    
    _expect(duration).is("number"):Argument(1, "duration")
    
    --// Instance
    self.StopAnimations = false
    self.Reversing = false
    self.Repeateds = false
    self.Duration = 0
    
    self._tweenPromises = {}
    self._lastFade = 0
    self._started = 0
    self._tweens = {}
    
    return self
end

--// Methods
function Animation.prototype.async:ResumeAsync(promise, delay: number?, fade: number?, reverse: boolean?): ()
    
    promise:Catch("PromiseCancelledException")
    
    delay = delay or 0
    reverse = if reverse == nil then self.Reversing else reverse
    fade = fade or self:GetFade()
    
    _expect(delay).is.some("number", "nil"):Argument(1, "delay")
    _expect(fade).is("number"):Argument(2, "fade")
    _expect(reverse).is("boolean"):Argument(3, "reverse")
    
    if delay > 0 then task.wait(delay) delay = 0 end
    
    if self._sectionPromise then self._sectionPromise:Cancel() end
    self._sectionPromise = promise
    
    --// Setup Data
    local duration = self.Duration
    local fadeInSeconds = fade*duration - delay
    local tweenPromises = self._tweenPromises
    
    self.Reversing = reverse
    self._started = os.clock() - fadeInSeconds
    self._lastFade = nil
    
    local count = 0
    
    --// Play New Tweens
    for keyframeFadeInSeconds, tweens in self._tweens do
        
        for _,tween in tweens do
            
            count += 1
            
            local tweenPromise = if reverse
                then tween:ResumeAsync(fadeInSeconds - keyframeFadeInSeconds - tween.Duration, 1, true)
                else tween:ResumeAsync(keyframeFadeInSeconds - fadeInSeconds, 0, false)
            
            tweenPromises[count] = tweenPromise
        end
    end
    
    function promise.onCancel()
        
        self._sectionPromise = nil
        self._lastFade = self:GetFade()
        
        for _,tweenPromise in tweenPromises do tweenPromise:Cancel() end
    end
    
    --// Finish
    Promise.all(tweenPromises):Expect()
    
    self._sectionPromise = nil
    self._lastFade = 1
end
function Animation.prototype.async:StopAsync(promise, delay: number): ()
    
    _expect(delay).is("number"):Argument(1, "delay")
    
    task.wait(delay)
    self:Stop()
end
function Animation.prototype:Stop(): ()
    
    if self._sectionPromise then self._sectionPromise:Cancel() end
end

function Animation.prototype:IsFinished(): boolean
    
    return self._lastFade == 1
end
function Animation.prototype:IsPlaying(): boolean
    
    return self._started ~= nil
end
function Animation.prototype:GetFade(): number
    
    local fade = self._lastFade or (os.clock() - self._started) / self.Duration
    
    return if self.Reversing then 1-fade else fade
end

function Animation.prototype:At(timestamp: number): TweenSchema
    
    _expect(timestamp).is("number"):Argument(1, "timestamp")
    
    return schematicTweenState(function(tween)
        
        self.Duration = math.max(self.Duration, timestamp + tween.Duration)
        
        self._tweens[timestamp] = self._tweens[timestamp] or {}
        table.insert(self._tweens[timestamp], tween)
    end)
end

--// End
export type Animation = typeof(Animation.prototype:constructor()) & {
    ResumeAsync: (self: Animation, delay: number?, fade: number?, reverse: boolean?) -> Promise<(secondsOverflow: number) -> (), number>,
    StopAsync: (self: Animation, delay: number?) -> Promise<() -> ()>,
}

return Animation