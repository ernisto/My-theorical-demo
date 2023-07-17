--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local _expect = require(Packages.Core.Expectation).new

local getType = Package.GetType
local isA = Package.IsA

--// Private Consts
local FORMATS_REGEX = "(.*)%%(%*?)([0# %+%-]?)(%d*)(%.?%d*)(.)(.*)$"

--// Function
local function format(pattern: string,...: any): string
    
    _expect(pattern).is("string"):Argument(2, "pattern")
    
    local newFormat = ""
    
    local arguments = {...}
    local formatsCount = 0
    local matchIn = pattern
    local formats = {}
    
    --// Capture Formats
    repeat
        --// Match
        local preString, tuple, flag, width, precision, specifier, postString = matchIn:match(FORMATS_REGEX)
        
        if preString == nil then break end
        
        matchIn = preString
        formatsCount += 1
        
        --// Register
        table.insert(formats, {
            tuple,
            flag,
            width,
            precision,
            specifier,
            postString,
        })
        
    until false
    
    local count = 0
    
    --// Modify Flags
    for index = formatsCount, 1, -1 do
        
        local tuple, flag, width, precision, specifier, postString = unpack(formats[index])
        count += 1
        
        local argumentFormat = "%"..tuple..flag..width..precision..specifier
        local argumentValue = arguments[count]
        local argumentType = getType(argumentValue)
        
        --// Modify Format
        if tuple == "*" then
            
            argumentValue = format(("%"..argumentFormat:sub(3)..", "):rep(#argumentValue):sub(1, -3), unpack(argumentValue))
            
            flag = ""
            width = ""
            precision = ""
            specifier = "s"
            
        elseif specifier == "t" then
            
            argumentValue = argumentType
            specifier = "s"
            
        elseif specifier == "s" or specifier == "q" then
            
            if type(argumentValue) ~= "string" then specifier = "s" end
            
            argumentValue = if argumentValue == nil then "nil" else tostring(argumentValue)
            
        elseif specifier == "v" then
            
            argumentValue = if isA(argumentValue, "Object") then format("%*q", {argumentValue:components()}) else tostring(argumentValue)
            specifier = "s"
            
        elseif not specifier:lower():match("[cdefgioqstuvx%%]") then
            
            error(format("Invalid specifier #%i '%s'", count, specifier), 2)
        end
        
        arguments[count] = argumentValue
        
        --// Finish Format Modify
        newFormat ..= "%"
            ..flag
            ..width
            ..precision
            ..specifier
            ..postString
    end
    
    return string.format(matchIn..newFormat, unpack(arguments))
end

--// End
return format