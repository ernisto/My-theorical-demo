--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Item = require(Packages.Server.Classes.Item)
local _expect = require(Packages.Core.Expectation).new

--// Library
local Tree = {}

--// Library Functions
function Tree.OakTree(cframe: CFrame)
    
    _expect(cframe).is("CFrame"):Argument(1, "cframe")
    
    local root = Item.create("Branch")
    root:PlaceOriginTo(nil, cframe)
    root:GrowthAsync(2, 10)
    
    root:ExtendAsync(5, 45, 45)
        :Then(function(branch) branch:GrowthAsync(1, 3) end)
    
    return root
end

--// End
return Tree