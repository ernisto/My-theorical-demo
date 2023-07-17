--[[
    Easing local functions adapted from Robert Penner's AS3 tweening equations.
--]]

--// Consts
local HALF_PI = math.pi/2

--// Consts
local A = 1.70158
local B = A + 1

--// Module Functions
local function Smoother(fade: number)
    return fade * fade * fade * (fade * (6 * fade - 15) + 10)
end
local function RidiculousWiggle(fade: number)
    return math.sin(math.sin(fade * 3.1415926535898) * 1.5707963267949)
end
local function Spring(fade: number)
    return 1 + (-math.exp(-6.9 * fade) * math.cos(-20.106192982975 * fade))
end
local function SoftSpring(fade: number)
    return 1 + (-math.exp(-7.5 * fade) * math.cos(-10.053096491487 * fade))
end

local function outExponential(fade: number)
    
    if fade == 1 then return 1 end
    
    return 1 - 2^(-10*fade)
end
local function inExponential(fade: number)
    
    if fade == 0 then return 0 end
    
    return 2^(10*(fade-1))
end
local function inOutExponential(fade: number)
    
    return if fade < .5
        then inExponential(fade*2) / 2
        else (1 + outExponential(fade*2 - 1)) / 2
end
local function outInExponential(fade: number)
    
    return if fade < .5
        then outExponential(fade*2) / 2
        else (1 + inExponential(fade*2 - 1)) / 2
end

local function outQuadratic(fade: number)
    
    fade -= 1
    return 1 - fade^2
end
local function inQuadratic(fade: number)
    
    return fade^2
end
local function inOutQuadratic(fade: number)
    
    return if fade < .5
        then inQuadratic(fade*2) / 2
        else (1 + outQuadratic(fade*2 - 1)) / 2
end
local function outInQuadratic(fade: number)
    
    return if fade < .5
        then outQuadratic(fade*2) / 2
        else (1 + inQuadratic(fade*2 - 1)) / 2
end

local function outCircular(fade: number)
    
    fade -= 1
    return (1 - fade^2)^.5
end
local function inCircular(fade: number)
    
    return -((1 - fade*fade)^.5 - 1)
end
local function inOutCircular(fade: number)
    
    return if fade < .5
        then inCircular(fade*2) / 2
        else (1 + outCircular(fade*2 - 1)) / 2
end
local function outInCircular(fade: number)
    
    return if fade < .5
        then outCircular(fade*2)/2
        else (1 + inCircular(fade*2 - 1)) / 2
end

local function outElastic(fade: number)
    
    return  if fade == 0 then 0
        elseif fade == 1 then 1
        else 2^(-10*fade) * math.sin((fade*10 - 0.75)*2.1) + 1
end
local function inElastic(fade: number)
    
    return  if fade == 0 then 0
        elseif fade == 1 then 1
        else -2^(10*fade - 10) * math.sin((fade*10 - 10.75)*2.1)
end
local function inOutElastic(fade: number)
    
    return if fade < .5
        then inElastic(fade*2) / 2
        else (1 + outElastic(fade*2 - 1)) / 2
end
local function outInElastic(fade: number)
    
    return if fade < .5
        then outElastic(fade*2) / 2
        else (1 + inElastic(fade*2 - 1)) / 2
end

local function outQuintic(fade: number)
    
    fade -= 1
    return 1 + fade^5
end
local function inQuintic(fade: number)
    
    return fade^5
end
local function inOutQuintic(fade: number)
    
    return if fade < .5
        then inQuintic(fade*2) / 2
        else (1 + outQuintic(fade*2 - 1)) / 2
end
local function outInQuintic(fade: number)
    
    return if fade < .5
        then outQuintic(fade*2)/2
        else (1 + inQuintic(fade*2 - 1)) / 2
end

local function outQuartic(fade: number)
    
    fade -= 1
    return 1 - fade^4
end
local function inQuartic(fade: number)
    
    return fade^4
end
local function inOutQuartic(fade: number)
    
    return if fade < .5
        then inQuartic(fade*2) / 2
        else (1 + outQuartic(fade*2 - 1)) / 2
end
local function outInQuartic(fade: number)
    
    return if fade < .5
        then outQuartic(fade*2) / 2
        else (1 + inQuartic(fade*2 - 1)) / 2
end

local function outBounce(fade: number)
    
    if fade < 1/2.75 then

        return 7.5625 * fade^2
        
    elseif fade < 2/2.75 then

        fade -= 1.5/2.75
        
        return 7.5625 * fade^2 + 0.75
        
    elseif fade < 2.5/2.75 then

        fade -= 2.25/2.75
        
        return 7.5625 * fade^2 + 0.9375
    else
        
        fade -= 2.625/2.75
        
        return 7.5625 * fade^2 + 0.984375
    end
end
local function inBounce(fade: number)
    
    return 1 - outBounce(1-fade)
end
local function inOutBounce(fade: number)

    return if fade < .5
        then inBounce(fade*2) / 2
        else (1 + outBounce(fade*2 - 1)) / 2
end
local function outInBounce(fade: number)

    return if fade < .5
        then outBounce(fade*2) / 2
        else (1 + inBounce(fade*2 - 1)) / 2
end

local function inCubic(fade: number)
    
    return fade^3
end
local function outCubic(fade: number)
    
    fade -= 1
    return fade^3 + 1
end
local function inOutCubic(fade: number)
    
    return if fade < .5
        then inCubic(fade*2) / 2
        else (1 + outCubic(fade*2 - 1)) / 2
end
local function outInCubic(fade: number)
    
    return if fade < .5
        then outCubic(fade*2) / 2
        else (1 + inCubic(fade*2 - 1)) / 2
end

local function outSine(fade: number)
    
    return math.sin(fade*HALF_PI)
end
local function inSine(fade: number)
    
    return 1 - math.cos(fade*HALF_PI)
end
local function inOutSine(fade: number)
    
    return if fade < .5
        then inSine(fade*2)/2
        else (1 + outSine(fade*2 - 1)) / 2
end
local function outInSine(fade: number)
    
    return if fade < .5
        then outSine(fade*2)/2
        else (1 + inSine(fade*2 - 1)) / 2
end

local function outBack(fade: number)
    
    fade -= 1
    return 1  +  B * fade^3  +  A * fade^2
end
local function inBack(fade: number)
    
    return B * fade^3  -  A * fade^2
end
local function inOutBack(fade: number)
    
    return if fade < .5
        then inBack(fade*2)/2
        else (1 + outBack(fade*2 - 1))/2
end
local function outInBack(fade: number)
    
    return if fade < .5
        then outBack(fade*2) / 2
        else (1 + inBack(fade*2 - 1)) / 2
end

local function linear(fade: number)
    
    return fade
end

--// End Hidden Module
return {
    RidiculousWiggle = RidiculousWiggle,
    SoftSpring = SoftSpring,
    Smoother = Smoother,
    Spring = Spring,
    
    InOutExponential = inOutExponential,
    OutInExponential = outInExponential,
    OutExponential = outExponential,
    InExponential = inExponential,
    
    InOutCircular = inOutCircular,
    OutInCircular = outInCircular,
    OutCircular = outCircular,
    InCircular = inCircular,
    
    InOutElastic = inOutElastic,
    OutInElastic = outInElastic,
    OutElastic = outElastic,
    InElastic = inElastic,
    
    InOutBounce = inOutBounce,
    OutInBounce = outInBounce,
    OutBounce = outBounce,
    InBounce = inBounce,
    
    InOutQuint = inOutQuintic,
    OutInQuint = outInQuintic,
    OutQuint = outQuintic,
    InQuint = inQuintic,
    
    InOutQuart = inOutQuartic,
    OutInQuart = outInQuartic,
    OutQuart = outQuartic,
    InQuart = inQuartic,
    
    InOutCubic = inOutCubic,
    OutInCubic = outInCubic,
    OutCubic = outCubic,
    InCubic = inCubic,
    
    InOutQuad = inOutQuadratic,
    OutInQuad = outInQuadratic,
    OutQuad = outQuadratic,
    InQuad = inQuadratic,
    
    InOutSine = inOutSine,
    OutInSine = outInSine,
    OutSine = outSine,
    InSine = inSine,
    
    InOutBack = inOutBack,
    OutInBack = outInBack,
    OutBack = outBack,
    InBack = inBack,
    
    Linear = linear,
}