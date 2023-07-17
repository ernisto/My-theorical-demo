--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local UserInputService = game:GetService("UserInputService")

local newKey = require(Packages.Client.Classes.Device.Key).new
local _expect = require(Packages.Core.Expectation).new

--// Class
local Mouse = Package.class("Mouse")
:: Package.Class & {
    Scrolled: Signal<(direction: integer, engineProcessed: boolean) -> ()>,
    ScrollBackward: Signal<(engineProcessed: boolean) -> ()>,
    ScrollForward: Signal<(engineProcessed: boolean) -> ()>,
    Moved: Signal<(position: Vector2, delta: Vector2) -> ()>,
}

--// Vars
local camera = workspace.CurrentCamera

--// Class Vars
Mouse.Buttons = {
    Middle = newKey(Enum.UserInputType.MouseButton3),
    Right = newKey(Enum.UserInputType.MouseButton2),
    Left = newKey(Enum.UserInputType.MouseButton1),
}

--// Signals
function Mouse.signal.Scrolled(direction: integer, engineProcessed: boolean) end
function Mouse.signal.ScrollBackward(engineProcessed: boolean) end
function Mouse.signal.ScrollForward(engineProcessed: boolean) end
function Mouse.signal.Moved(position: Vector2, delta: Vector2) end

--// Methods
function Mouse:SetVisible(visible: boolean)
    
    _expect(visible).is("boolean"):Argument(1, "visible")
    
    UserInputService.MouseIconEnabled = visible
end
function Mouse:IsEnabled(): boolean
    
    return UserInputService.MouseEnabled
end

function Mouse:GetPosition(): Vector2
    
    return UserInputService:GetMouseLocation()
end
function Mouse:GetDelta(): Vector2
    
    return UserInputService:GetMouseDelta()
end

function Mouse:LockAtCenter()
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end
function Mouse:Unlock()
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end
function Mouse:Lock()
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function Mouse:Raycast(range: number?, raycastParams: RaycastParams?): (Instance, CFrame, number)
    
    range = range or 500
    
    _expect(range).is("number"):Argument(1, "range")
    _expect(raycastParams).is.some("RaycastParams", "nil"):Argument(2, "raycastParams")
    
    local position = Mouse:GetPosition()
    local info = camera:ViewportPointToRay(position.X, position.Y, range)
    
    local cast = workspace:Raycast(camera.CFrame.Position, info.Origin, raycastParams)
    if not cast then return end
    
    return cast.Instance, CFrame.new(cast.Position, cast.Position + cast.Normal), cast.Distance
end
function Mouse:RaycastWhitelist(range: number, whitelist: {Instance}): (Instance, Vector3, Vector3, number)
    
    _expect(range).is("number"):Argument(1, "range")
    _expect(whitelist).all.value.is("Instance"):Argument(1, "whitelist")
    _expect(whitelist).all.index.is("integer"):Argument(1, "whitelist")
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = whitelist
    params.FilterType = Enum.RaycastFilterType.Whitelist
    
    return self:Raycast(range, params)
end
function Mouse:RaycastBlacklist(range: number, blacklist: {Instance}): (Instance, Vector3, Vector3, number)
    
    _expect(range).is("number"):Argument(1, "range")
    _expect(blacklist).all.value.is("Instance"):Argument(1, "blacklist")
    _expect(blacklist).all.index.is("integer"):Argument(1, "blacklist")
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = blacklist
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    return self:Raycast(params)
end

--// Listeners
UserInputService.InputChanged:Connect(function(inputObject, engineProcessed)
    
    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
        
        Mouse.Moved(inputObject.Position, inputObject.Delta, engineProcessed)
        
    elseif inputObject.UserInputType == Enum.UserInputType.MouseWheel then
        
        local direction = inputObject.Delta.Z
        Mouse.Scrolled(direction, engineProcessed)
        
        if direction > 0 then
        
            Mouse.ScrollForward(engineProcessed)
        else
            
            Mouse.ScrollBackward(engineProcessed)
        end
    end
end)

--// End
return Mouse