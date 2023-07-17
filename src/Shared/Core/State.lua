--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Connection = Package.Connection
type Signal<F> = Package.Signal<F>

--// Packages
local Signal = require(Packages.Core.Signal)
local format = require(Packages.Core.Format)
local _expect = require(Packages.Core.Expectation).new

local clamp, lowest, highest = math.clamp, math.min, math.max
local isA = Package.IsA

local scaleUDim2, pixelUDim2 = UDim2.fromScale, UDim2.fromOffset
local newVector2, newVector3 = Vector2.new, Vector3.new
local fromHSV, fromRGB = Color3.fromHSV, Color3.fromRGB
local newUDim = UDim.new

local SET = Package.SET

--// Class
local State = Package.class("State")
:: Package.Class<State> & {
    new: ((value: number) -> numberState)
        & ((value: Vector3) -> Vector3State)
        & ((value: Vector2) -> Vector2State)
        & ((value: CFrame) -> CFrameState)
        & ((value: UDim2) -> UDim2State)
        & ((value: UDim) -> UDimState)
        & ((value: Color3) -> Color3State)
        & (<V>(value: V) -> State<V>),
    
    thernary: <V1, V2>(condition: any, trueValue: V1, falseValue: V2) -> State<V1|V2>,
    
    vector: ((
        x: number|numberState,
        y: number|numberState,
        z: number|numberState
    ) -> Vector3State)
    & ((
        xy: Vector2|Vector2State,
        z: number|numberState
    ) -> Vector3State)
    & ((
        x: number|numberState,
        yz: Vector2|Vector2State
    ) -> Vector3State)
    & ((
        x: number|numberState,
        y: number|numberState
    ) -> Vector2State)
    & ((
        x: number|numberState
    ) -> numberState),
    
    scale: ((
        xy: Vector2|Vector2State
    ) -> UDim2State)
    & ((
        x: number|numberState,
        y: number|numberState
    ) -> UDim2State)
    & ((
        x: number|numberState
    ) -> UDimState),
    
    pixel: ((
        xy: Vector2|Vector2State
    ) -> UDim2State)
    & ((
        x: integer|integerState,
        y: integer|integerState
    ) -> UDim2State)
    & ((
        x: integer|integerState
    ) -> UDimState),
    
    deg: ((
        x: number|numberState,
        y: number|numberState,
        z: number|numberState
    ) -> CFrameState)
    & ((
        x: number|numberState
    ) -> numberState),
    
    rad: ((
        x: number|numberState,
        y: number|numberState,
        z: number|numberState
    ) -> CFrameState)
    & ((
        x: number|numberState
    ) -> numberState),
}

--// Consts
local DEG_TO_RAD = 180 / math.pi
local TAU = math.pi*2

local PROPERTIES_WHITELIST = {
    RightVector = true,
    LookVector = true,
    UpVector = true,
    Offset = true,
    Scale = true,
    X = true,
    Y = true,
    Z = true,
    R = true,
    G = true,
    B = true,
}

--// Functions
local function connectChanged(signal,...)
    
    local connection = Signal.Connect(signal,...)
    connection._state = signal._state
    
    return connection
end

--// Class Functions
function State.computed(...: any|State<any>|(...any) -> any): State<any>
    
    local connections = {}
    local mainState = State.new(nil)
    local weak_mainState = setmetatable({ mainState }, { __mode = "v" })
    
    local statesCount = select("#",...)-1
    local stateValues = {}
    local constant = true
    local computer
    
    local function cleanUp()
        
        for connection in connections do
            
            connection:Destroy()
        end
    end
    local function subStateChanged(index, value)
        
        local mainState = weak_mainState[1]
        if not mainState then return cleanUp() end
        
        stateValues[index] = value
        mainState:Set(computer(unpack(stateValues, 1, statesCount)))
    end
    
    for index = 1, statesCount+1 do
        
        local value = select(index,...)
        index = if computer then index-1 else index
        
        if type(value) == "function" then
            
            computer = value
            
        elseif isA(value, "State") then
            
            if not value.Constant then
                
                local connection = value.Changed:Connect(subStateChanged, index)
                
                connections[connection] = true
                constant = false
            end
            
            stateValues[index] = value.Value
        else
            
            stateValues[index] = value
        end
    end
    
    _expect(computer).is("function"):Argument(statesCount+2, "computer")
    
    --// Setup
    mainState:Set(computer(unpack(stateValues, 1, statesCount)))
    mainState.Destroyed:Connect(cleanUp)
    mainState.Constant = constant
    
    --// End
    return mainState
end
local computed = State.computed

function State.thernary(condition: any|State<any>, isTrue: any|State<any>, isFalse: any|State<any>): State<any>
    
    return computed(condition, isTrue, isFalse, function(a, b, c) return if a then b else c end)
end
function State.string(pattern: string,...: State<any>): State<string>
    
    _expect(pattern).is("string"):Argument(1, "pattern")
    
    return computed(format, pattern,...)
end

function State.udim2(x: UDim, y: UDim): UDim2State
    
    _expect(x, y).is.some("UDim", "State"):Argument(1, "x", "y")
    
    return computed(UDim2.new, x, y)
end
function State.vector(x: number|Vector2, y: number|Vector2?, z: number?): numberState|Vector2State|Vector3State
    
    if typeof(x) == "Vector2" then
        
        _expect(y).is.some("number", "nil"):Argument(2, "y")
        x, y, z = x.X, x.Y, y
        
    elseif typeof(y) == "Vector2" then
        
        _expect(z).is("nil"):Argument(3, "z")
        y, z = y.X, y.Y
    end
    
    _expect(x).is.some("State", "number"):Argument(1, "x")
    _expect(y, z).is.some("State", "number", "nil"):Argument(1, "y", "z")
    
    return if z then computed(newVector3, x, y, z) elseif y then computed(newVector2, x, y) else computed(x, function(x) return x end)
end
function State.scale(x: number|Vector2, y: number?): UDimState|UDim2State
    
    if typeof(x) == "Vector2" then x, y = x.X, x.Y end
    
    _expect(x).is.some("number", "State", "Vector2"):Argument(1, "x")
    _expect(y).is.some("number", "State", "nil"):Argument(2, "y")
    
    return if y then computed(scaleUDim2, x, y) else computed(newUDim, x, 0)
end
function State.pixel(x: number|Vector2, y: number?): UDimState|UDim2State
    
    if typeof(x) == "Vector2" then x, y = x.X, x.Y end
    
    _expect(x).is.some("number", "State", "Vector2"):Argument(1, "x")
    _expect(y).is.some("number", "State", "nil"):Argument(2, "y")
    
    return if y then computed(pixelUDim2, x, y) else computed(newUDim, 0, x)
end

function State.clamp(number: number, minimun: number?, maximun: number?): numberState
    
    minimun = minimun or -9e999
    maximun = maximun or 9e999
    
    _expect(number, minimun, maximun).is.some("number", "State"):Argument(1, "number", "minimun", "maximun")
    
    return computed(clamp, number, minimun, maximun)
end
function State.highest(number: number,...: number): numberState
    
    _expect(number,...).is.some("number", "State"):Argument(1, "number")
    
    return computed(highest, number,...)
end
function State.lowest(number: number,...: number): numberState
    
    _expect(number,...).is.some("number", "State"):Argument(1, "number")
    
    return computed(lowest, number,...)
end

function State.cframe(x: number, y: number, z: number): CFrameState
    
    _expect(x, y, z).is.some("number", "State"):Argument(1, "x", "y", "z")
    
    return computed(CFrame.new, x, y, z)
end
function State.deg(x: number, y: number?, z: number?): numberState|CFrameState
    
    _expect(x).is.some("number", "State"):Argument(1, "degress")
    _expect(y, z).is.some("number", "State", "nil"):Argument(2, "degress")
    
    if y then
        
        return State.computed(CFrame.Angles, x/DEG_TO_RAD, y/DEG_TO_RAD, z/DEG_TO_RAD)
    else
        
        return x/360
    end
end
function State.rad(x: number, y: number?, z: number?): numberState|CFrameState
    
    _expect(x).is.some("number", "State"):Argument(1, "radians")
    _expect(y, z).is.some("number", "State", "nil"):Argument(2, "radians")
    
    if y then
        
        return computed(CFrame.Angles, x, y, z)
    else
        
        return x/TAU
    end
end

function State.hsv(hue: number, saturation: number, value: number): Color3State
    
    _expect(hue, saturation, value).is.some("number", "State"):Argument(1, "hue", "saturation", "value")
    
    return computed(fromHSV, hue, saturation, value)
end
function State.rgb(red: number, green: number, blue: number): Color3State
    
    _expect(red, green, blue).is.some("number", "State"):Argument(1, "red", "green", "blue")
    
    return computed(fromRGB, red, green, blue)
end

--// Constructor
function State.prototype:constructor(value: any)
    
    while isA(value, "State") and value.Constant do value = value.Value end
    
    --// Instance
    self.Constant = false
    self.Value = value
    
    self._destroyedConnection = nil :: Connection?
    
    --! rule breaker
    self.Changed.Connect = connectChanged
    self.Changed._state = self
    return self
end

--// Signals
function State.prototype.signal.Changed(newValue: any, lastValue: any,...: any) end

--// Methods
function State.prototype:Increase(increment: number, maximun: number,...: any): number
    
    maximun = maximun or 9e999
    
    _expect(self.Value).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Throws(2, "Exception", "Attempt to decrease a non-numeric State(%s)", self)
    _expect(increment).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Argument(1, "increment")
    _expect(maximun).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Argument(2, "maximun")
    
    return self:Set(lowest(self.Value + increment, maximun),...)
end
function State.prototype:Decrease(decrement: number, minimun: number,...: any): number
    
    minimun = minimun or -9e999
    
    _expect(self.Value).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Throws(2, "Exception", "Attempt to decrease a non-numeric State(%s)", self)
    _expect(decrement).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Argument(1, "decrement")
    _expect(minimun).is.some("number", "UDim", "UDim2", "CFrame", "Vector2", "Vector3"):Argument(2, "minimun")
    
    return self:Set(highest(self.Value - decrement, minimun),...)
end
function State.prototype:Set(newValue: any,...: any): any
    
    while isA(newValue, "State") do newValue = newValue.Value end
    
    local lastValue = self.Value
    if newValue == lastValue then return end
    
    self.Value = newValue
    
    local success = self.Changed:TryCall(newValue, lastValue,...)
    if not success then self.Value = lastValue; return lastValue end
    
    if isA(newValue, "Object") and rawget(newValue, "Destroyed") and self.Value == newValue then
        
        local clearValue = newValue.Destroyed:Connect(self.Set, self, nil)
        self.Changed:Once(clearValue.Disconnect, clearValue)
    end
    
    return newValue
end
function State.prototype:Get(): any
    
    return self.Value
end

function State.prototype:Updater(updater: (value: any, lastValue: any) -> (), ...: any): Connection?
    
    _expect(updater).is("function"):Argument(1, "updater")
    
    local connection = self.Changed:Connect(updater,...)
    connection(self.Value, self.Value)
    
    if self.Constant then connection:Disconnect() return end
    return connection
end
function State.prototype:Bind(object: State|userdata|{[any]: any}, index: any?): any
    
    _expect(object).is.some("table", "userdata", "State"):Argument(1, "object")
    
    if isA(object, "State") then
        
        return self:Updater(object.Set, object)
    else
        
        return self:Updater(SET, object, index)
    end
end

--// Override Methods
function State.prototype:destroying()
    
    if self._destroyedConnection then self._destroyedConnection:Destroy() end
end

--// Behaviour
function State.prototype:components()
    
    return self.Value
end
function State.prototype:get(index)
    
    if not PROPERTIES_WHITELIST[index] then return end
    
    local value = computed(self, function(selfValue)
        
        return selfValue[index]
    end)
    
    self[index] = value
    return value
end

--// Operators
function State.prototype:__concat(concating)
    
    return computed(self, concating, function(selfValue, concatingValue)
        
        return selfValue..concatingValue
    end)
end

function State.prototype:__unm()
    
    return computed(self, function(selfValue)
        
        return -selfValue
    end)
end
function State.prototype:__add(increment)
    
    return computed(self, increment, function(selfValue, incrementValue)
        
        return selfValue + incrementValue
    end)
end
function State.prototype:__sub(decrement)
    
    return computed(self, decrement, function(selfValue, decrementValue)
        
        return selfValue - decrementValue
    end)
end
function State.prototype:__mul(multiplier)
    
    return computed(self, multiplier, function(selfValue, multiplierValue)
        
        return selfValue * multiplierValue
    end)
end
function State.prototype:__div(divisor)
    
    return computed(self, divisor, function(selfValue, divisorValue)
        
        return selfValue / divisorValue
    end)
end
function State.prototype:__pow(potence)
    
    return computed(self, potence, function(selfValue, potenceValue)
        
        return selfValue ^ potenceValue
    end)
end
function State.prototype:__mod(divisor)
    
    return computed(self, divisor, function(selfValue, divisorValue)
        
        return selfValue % divisorValue
    end)
end

function State.prototype:__eq(state)
    
    return computed(self, state, function(selfValue, stateValue)
        
        return selfValue == stateValue
    end)
end
function State.prototype:__le(state)
    
    return computed(self, state, function(selfValue, stateValue)
        
        return selfValue <= stateValue
    end)
end
function State.prototype:__lt(state)
    
    return computed(self, state, function(selfValue, stateValue)
        
        return selfValue < stateValue
    end)
end
function State.prototype:__or(state)
    
    return computed(self, state, function(selfValue, value)
        
        return selfValue or value
    end)
end

--// End
type numericState<V> = State<V> & {
    Increase: (self: State<V>, increment: V, minimun: V) -> V,
    Decrease: (self: State<V>, increment: V, minimun: V) -> V,
}

export type Vector3State = numericState<Vector3> & {
    X: numberState,
    Y: numberState,
    Z: numberState,
}
export type Vector2State = numericState<Vector2> & {
    X: numberState,
    Y: numberState,
}
export type CFrameState = numericState<CFrame> & {
    RightVector: Vector3State,
    LookVector: Vector3State,
    UpVector: Vector3State,
    X: numberState,
    Y: numberState,
    Z: numberState,
}
export type UDim2State = numericState<UDim2> & {
    X: UDimState,
    Y: UDimState,
}
export type UDimState = numericState<UDim> & {
    Offset: numberState,
    Scale: numberState,
}
export type Color3State = State<Color3> & {
    R: numberState,
    G: numberState,
    B: numberState,
}
export type integerState = numericState<integer>
export type numberState = numericState<number>

export type State<V> = {
    Updater: (self: State<V>, callback: (newValue: V, lastValue: V) -> (), ...any) -> Connection,
    Bind: (self: State<V>, instance: Instance|Object|table, field: string) -> Conneciton,
    Set: (self: State<V>, newValue: V, ...any) -> V,
    Get: (self: State<V>) -> V,
    
    Changed: Signal<(newValue: V, lastValue: V) -> ()>,
    
    Constant: boolean,
    Value: V,
}

return State