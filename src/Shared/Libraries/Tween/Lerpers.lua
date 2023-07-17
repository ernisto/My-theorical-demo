--// Module
local lerpers = {}

--// Functions
local function primitiveLerp(origin, delta, fade)
    
    return origin + delta*fade
end

--// Module Functions
function lerpers.number(origin, goal)
    
    return primitiveLerp, origin, goal - origin
end
function lerpers.Vector2(origin, goal)
    
    return primitiveLerp, origin, goal - origin
end
function lerpers.Vector3(origin, goal)
    
    return primitiveLerp, origin, goal - origin
end
function lerpers.UDim2(origin, goal)
    
    return origin.Lerp, origin, goal
end
function lerpers.CFrame(origin, goal)
    
    return origin.Lerp, origin, goal
end

do  --// Color3
    local function lerp(origin, delta, fade)
        
        return Color3.fromHSV(
            origin[1] + delta[1]*fade,
            origin[2] + delta[2]*fade,
            origin[3] + delta[3]*fade
        )
    end
    
    function lerpers.Color3(origin, goal)
        
        local hue1, saturation1, value1 = origin:ToHSV()
        local hue2, saturation2, value2 = goal:ToHSV()
        
        if saturation1 == 0 or value1 == 0 then
            
            hue1 = hue2
        end
        if saturation2 == 0 or value2 == 0 then
            
            hue2 = hue1
        end
        
        return lerp, {hue1, saturation1, value1}, {hue2 - hue1, saturation2 - saturation1, value2 - value1}
    end
end
do  --// UDim
    local function lerp(origin, delta, fade)
        
        return UDim.new(
            origin[1] + delta[1]*fade,
            origin[2] + delta[2]*fade
        )
    end
    
    function lerpers.UDim(origin, goal)
        
        return lerp, {origin.Scale, origin.Offset}, {goal.Scale - origin.Scale, goal.Offset - origin.Offset}
    end
end
do  --// Boolean
    local function lerp(origin, goal, multiplier)
        
        return if multiplier == 1 then goal else origin
    end
    
    function lerpers.boolean(origin, goal)
        
        return lerp, origin, goal
    end
end
do  --// NumberRange
    local function lerp(origin, delta, fade)
        
        return NumberRange.new(
            origin[1] + delta[1]*fade,
            origin[2] + delta[2]*fade
        )
    end
    
    function lerpers.NumberRange(origin, goal, fade)
        
        return lerp, {origin.Min, origin.Max}, {goal.Min - origin.Min, goal.Max - origin.Max}
    end
end

do  --// NumberSequence
    local function lerpKeypoints(originKeypoints, deltaKeypoints, multiplier)
        
        local keypoints = {}
        
        for index, originKeypoint in originKeypoints do
            
            local deltaKeypoint = deltaKeypoints[index]
            
            keypoints[index] = NumberSequenceKeypoint.new(
                originKeypoint.Time,
                originKeypoint.Value + deltaKeypoint.Value*multiplier,
                originKeypoint.Envelope + deltaKeypoint.Envelope*multiplier
            )
        end
        
        return NumberSequence.new(keypoints)
    end
    local function lerp(origin, goal, interpolation)

        return origin + (goal - origin)*interpolation
    end
    
    function lerpers.NumberSequence(origin, goal)
        
        local originKeypoints = origin.Keypoints
        local goalKeypoints = goal.Keypoints
        local originKeypointsHash = {}
        local goalKeypointsHash = {}
        local deltaKeypoints = {
            NumberSequence.new(0, originKeypoints[1].Value - goalKeypoints[1].Value)
        }
        
        for _,keypoint in originKeypoints do
            
            originKeypointsHash[keypoint.Time] = true
        end
        for _,keypoint in goalKeypoints do
            
            goalKeypointsHash[keypoint.Time] = true
        end
        
        local lastOriginKeypoint = originKeypoints[1]
        local lastGoalKeypoint = goalKeypoints[1]
        local index = 2
        
        repeat
            local originKeypoint = originKeypoints[index]
            local originValue = originKeypoint.Value
            local originTime = originKeypoint.Time
            
            local goalKeypoint = goalKeypoints[index]
            local goalValue = goalKeypoint.Value
            local goalTime = goalKeypoint.Time
            
            if originTime > goalTime then
                
                if not originKeypointsHash[goalTime] then
                    
                    local lastKeypoint = lastOriginKeypoint
                    
                    local valueInterpolation = (goalTime - lastKeypoint.Time) / (originTime - lastKeypoint.Time)
                    originValue = lerp(lastKeypoint.Value, originKeypoint.Value, valueInterpolation)
                    
                    table.insert(originKeypoints, index, NumberSequenceKeypoint.new(goalTime, originValue))
                end
                
                if not goalKeypointsHash[originTime] then
                    
                    local nextKeypoint = goalKeypoints[index+1]
                    
                    local valueInterpolation = (originTime - goalTime) / (nextKeypoint.Time - goalTime)
                    goalValue = lerp(goalKeypoint.Value, nextKeypoint.Value, valueInterpolation)
                    
                    table.insert(goalKeypoints, index+1, NumberSequenceKeypoint.new(originTime, goalValue))
                end
                
                deltaKeypoints[index] = NumberSequence.new(originTime, goalValue - originValue)
                
            elseif originTime < goalTime then
                
                if not goalKeypointsHash[originTime] then
                    
                    local lastKeypoint = lastGoalKeypoint
                    
                    local valueInterpolation = (originTime - lastKeypoint.Time) / (goalTime - lastKeypoint.Time)
                    goalValue = lerp(lastKeypoint.Value, goalKeypoint.Value, valueInterpolation)
                    
                    table.insert(goalKeypoints, index, NumberSequenceKeypoint.new(originTime, goalValue))
                end
                
                if not originKeypointsHash[goalTime] then
                    
                    local nextKeypoint = originKeypoints[index+1]
                    
                    local valueInterpolation = (goalTime - originTime) / (nextKeypoint.Time - originTime)
                    originValue = lerp(originKeypoint.Value, nextKeypoint.Value, valueInterpolation)
                    
                    table.insert(originKeypoints, index+1, NumberSequenceKeypoint.new(goalTime, originValue))
                end
                
                deltaKeypoints[index] = NumberSequence.new(originTime, goalValue - originValue)
            else
                
                lastOriginKeypoint = originKeypoint
                lastGoalKeypoint = goalKeypoint
            end
            
            index += 1
            
        until originTime == 1.00 and goalTime == 1.00
        
        --// End
        return lerpKeypoints, originKeypoints, deltaKeypoints
    end
end
do  --// ColorSequence
    local lerpRGB = Color3.new().Lerp
    
    local function lerpKeypoints(originKeypoints, deltaKeypoints, multiplier)
        
        local keypoints = {}
        
        for index, originKeypoint in originKeypoints do
            
            keypoints[index] = ColorSequenceKeypoint.new(
                originKeypoint.Time,
                lerpRGB(originKeypoint.Value, deltaKeypoints[index].Value, multiplier)
            )
        end
        
        return ColorSequence.new(keypoints)
    end
    
    function lerpers.NumberSequence(origin, goal)
        
        local originKeypoints = origin.Keypoints
        local goalKeypoints = goal.Keypoints
        local originKeypointsHash = {}
        local goalKeypointsHash = {}
        local deltaKeypoints = {
            NumberSequence.new(0, originKeypoints[1].Value - goalKeypoints[1].Value)
        }
        
        for _,keypoint in originKeypoints do
            
            originKeypointsHash[keypoint.Time] = true
        end
        for _,keypoint in goalKeypoints do
            
            goalKeypointsHash[keypoint.Time] = true
        end
        
        local lastOriginKeypoint = originKeypoints[1]
        local lastGoalKeypoint = goalKeypoints[1]
        local index = 2
        
        repeat
            local originKeypoint = originKeypoints[index]
            local originValue = originKeypoint.Value
            local originTime = originKeypoint.Time
            
            local goalKeypoint = goalKeypoints[index]
            local goalValue = goalKeypoint.Value
            local goalTime = goalKeypoint.Time
            
            if originTime > goalTime then
                
                if not originKeypointsHash[goalTime] then
                    
                    local lastKeypoint = lastOriginKeypoint
                    
                    local valueInterpolation = (goalTime - lastKeypoint.Time) / (originTime - lastKeypoint.Time)
                    originValue = lerpRGB(lastKeypoint.Value, originKeypoint.Value, valueInterpolation)
                    
                    table.insert(originKeypoints, index, NumberSequenceKeypoint.new(goalTime, originValue))
                end
                
                if not goalKeypointsHash[originTime] then
                    
                    local nextKeypoint = goalKeypoints[index+1]
                    
                    local valueInterpolation = (originTime - goalTime) / (nextKeypoint.Time - goalTime)
                    goalValue = lerpRGB(goalKeypoint.Value, nextKeypoint.Value, valueInterpolation)
                    
                    table.insert(goalKeypoints, index+1, NumberSequenceKeypoint.new(originTime, goalValue))
                end
                
                deltaKeypoints[index] = NumberSequence.new(goalTime, goalValue - originValue)
                
            elseif originTime < goalTime then
                
                if not goalKeypointsHash[originTime] then
                    
                    local lastKeypoint = lastGoalKeypoint
                    
                    local valueInterpolation = (originTime - lastKeypoint.Time) / (goalTime - lastKeypoint.Time)
                    goalValue = lerpRGB(lastKeypoint.Value, goalKeypoint.Value, valueInterpolation)
                    
                    table.insert(goalKeypoints, index, NumberSequenceKeypoint.new(originTime, goalValue))
                end
                
                if not originKeypointsHash[goalTime] then
                    
                    local nextKeypoint = originKeypoints[index+1]
                    
                    local valueInterpolation = (goalTime - originTime) / (nextKeypoint.Time - originTime)
                    originValue = lerpRGB(originKeypoint.Value, nextKeypoint.Value, valueInterpolation)
                    
                    table.insert(originKeypoints, index+1, NumberSequenceKeypoint.new(goalTime, originValue))
                end
                
                deltaKeypoints[index] = NumberSequence.new(originTime, goalValue - originValue)
            else
                
                lastOriginKeypoint = originKeypoint
                lastGoalKeypoint = goalKeypoint
            end
            
            index += 1
            
        until originTime == 1.00 and goalTime == 1.00
        
        --// End
        return lerpKeypoints, originKeypoints, deltaKeypoints
    end
end

--// End
return lerpers