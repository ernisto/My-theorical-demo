--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local newKey = require(Packages.Client.Classes.Device.Key).new

--// Class
local Gamepad = Package.class("Gamepad")

--// Vars
local gamepads = {}

--// Class Functions
function Gamepad.get(gamepadUserInputType: Enum.UserInputType?): Gamepad
    
    return if gamepadUserInputType then gamepads[gamepadUserInputType] else Gamepad
end

--// Constructor
function Gamepad.prototype:constructor(gamepadUserInputType: Enum.UserInputType)
    
    local gamepadHoldingButtons = {}
    
    --// Instance
    self.UserInputType = gamepadUserInputType
    self.Buttons = {
        ButtonSelect    = newKey(gamepadUserInputType, Enum.KeyCode.ButtonSelect),
        ButtonStart     = newKey(gamepadUserInputType, Enum.KeyCode.ButtonStart),
        ButtonL1        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonL1),
        ButtonL2        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonL2),
        ButtonL3        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonL3),
        ButtonR1        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonR1),
        ButtonR2        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonR2),
        ButtonR3        = newKey(gamepadUserInputType, Enum.KeyCode.ButtonR3),
        DPadRight       = newKey(gamepadUserInputType, Enum.KeyCode.DPadRight),
        DPadLeft        = newKey(gamepadUserInputType, Enum.KeyCode.DPadLeft),
        DPadDown        = newKey(gamepadUserInputType, Enum.KeyCode.DPadDown),
        DPadUp          = newKey(gamepadUserInputType, Enum.KeyCode.DPadUp),
        ButtonA         = newKey(gamepadUserInputType, Enum.KeyCode.ButtonA),
        ButtonB         = newKey(gamepadUserInputType, Enum.KeyCode.ButtonB),
        ButtonX         = newKey(gamepadUserInputType, Enum.KeyCode.ButtonX),
        ButtonY         = newKey(gamepadUserInputType, Enum.KeyCode.ButtonY),
    }
    
    self._holdingButtons = gamepadHoldingButtons
    
    --// Setup
    gamepads[gamepadUserInputType] = self
    
    for _,gamepadButton in self.Buttons do
        
        gamepadButton.Holded:Connect(function(engineProcessed)
            
            self.ButtonChanged(gamepadButton, true, engineProcessed)
            self.ButtonHolded(gamepadButton, engineProcessed)
            
            gamepadHoldingButtons[gamepadButton] = true
        end)
        gamepadButton.Released:Connect(function(engineProcessed)
            
            self.ButtonChanged(gamepadButton, false, engineProcessed)
            self.ButtonRelease(gamepadButton, engineProcessed)
            
            gamepadHoldingButtons[gamepadButton] = nil
        end)
    end
    
    return self
end

--// Signals
function Gamepad.prototype.signal.ButtonChanged(button: Key, isHolding: boolean, engineProcessed: boolean) end
function Gamepad.prototype.signal.ButtonReleased(button: Key, engineProcessed: boolean) end
function Gamepad.prototype.signal.ButtonHolded(button: Key, engineProcessed: boolean) end

--// Methods
function Gamepad.prototype:GetHoldingButtons(): {Key}
    
    local array = {}
    local index = 0
    
    for gamepadButton in self._holdingButtons do
        
        index += 1
        array[index] = gamepadButton
    end
    
    return array
end

--// End
export type Gamepad = typeof(Gamepad.prototype:constructor()) & {
    ButtonChanged: Signal<(button: Key, isHolding: boolean, engineProcessed: boolean) -> ()>,
    ButtonReleased: Signal<(button: Key, engineProcessed: boolean) -> ()>,
    ButtonHolded: Signal<(button: Key, engineProcessed: boolean) -> ()>,
}

return Gamepad