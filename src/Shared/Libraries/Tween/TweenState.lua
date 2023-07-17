--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local _expect = require(Packages.Core.Expectation).new
local State = require(Packages.Core.State)
local Tween = require(script.Parent)
type tweenInfo = Tween.tweenInfo

--// Class
local TweenState = Package.class("TweenState").extends(Tween, State)
:: Package.Class<TweenState> & {
    new: <V>(from: V, to: V, tweenInfo: TweenInfo|tweenInfo) -> TweenState,
}

--// Consts
local ZERO = {
    NumberSequence = NumberSequence.new(0),
    ColorSequence = ColorSequence.new(Color3.new()),
    NumberRange = NumberRange.new(0),
    Vector3 = Vector3.new(),
    Vector2 = Vector2.new(),
    Color3 = Color3.new(),
    CFrame = CFrame.new(),
    UDim2 = UDim2.new(),
    UDim = UDim.new(),
    boolean = false,
    string = "",
    number = 0,
}

--// Class Functions
local Schema = {} do
    Schema.__index = Schema
    
    function Schema:from(origin: any)
        
        self._origin = origin
        return self
    end
    function Schema:to(goal: any)
        
        self._goal = goal
        return self
    end
    function Schema:with(info: tweenInfo)
        
        if self._origin == nil then self._origin = ZERO[typeof(self._goal)] end
        if self._goal == nil then self._goal = ZERO[typeof(self._origin)] end
        
        local tweenState = TweenState.new(self._origin, self._goal, info)
        self._completed(tweenState)
        
        return tweenState
    end
end

function TweenState.schema(completed: (tweenState: TweenState) -> ()): TweenSchema
    
    local schema = setmetatable({
        _completed = completed,
        _origin = nil,
        _goal = nil,
    }, Schema)
    
    return schema
end

--// Constructor
function TweenState.prototype:constructor(from: State|any, to: State|typeof(from), tweenInfo: tweenInfo)
    
    tweenInfo = tweenInfo or TweenInfo.new(0)
    
    _expect(to).is.some("State", typeof(from)):Argument(2, "to")
    _expect(tweenInfo).is.some("table", "TweenInfo"):Argument(3, "tweenInfo")
    
    local function updater(value)
        
        self:Set(value)
    end
    
    --// Instance
    Tween(self, updater, tweenInfo, from, to)
    State(self, from)
    
    return self
end

--// End
export type TweenState = typeof(TweenState.prototype:constructor()) & Tween.Tween & State.State
export type TweenSchema = {
    from: (self: TweenSchema, origin: V) -> TweenSchema,
    to: (self: TweenSchema, goal: V) -> {
        with: (self: TweenSchema, tweenInfo: TweenInfo|tweenInfo) -> TweenState,
    }
}

return TweenState