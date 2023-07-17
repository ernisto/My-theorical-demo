--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Component = require(Packages.Libraries.Component)

--// Function
return function(part1: BasePart, part2: BasePart, offset: CFrame): Weld
    
    return Component.create("Weld", {
        Part0 = part1,
        Part1 = part2,
        C1 = offset,
        Parent = part1,
    })
end