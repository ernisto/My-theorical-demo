--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)
local Placeable = require(Packages.Client.Classes.Item.Placeable)
local Item = require(Packages.Client.Classes.Item)

local create = require(Packages.Libraries.Component).create
local vector = require(Packages.Core.State).vector
local _expect = require(Packages.Core.Expectation).new

--// Class
local Branch = Package.class("Branch").extends(ServerObject, Item, Placeable)
:: Package.Class<Branch>

--// Vars
local bodyBuilders = {} :: { [string]: (rootPart: Part, thickness: numberState, length: numberState) -> BasePart } do
    
    function bodyBuilders.Branch(rootPart, thickness, length)
        
        return create("Part", {
            Size = vector(thickness, length, thickness),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(170, 90, 50),
            CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0),
            Parent = rootPart,
            CanCollide = false,
            Anchored = false,
            CanQuery = false,
            CanTouch = false,
            Massless = true,
        })
    end
end

--// Constructor
function Branch.prototype:constructor(serverData)
    
    --// Instance
    Item(self, serverData)
    Placeable(self)
    
    self._bodyBuilder = assert(bodyBuilders[self.Name], ("Invalid branch name '%s'"):format(self.Name))
    self.BodyRoot = nil :: BasePart?
    return self
end

--// Methods
function Branch.prototype:FocusChopping()
    
    local thicknessCap = self:GetState("Thickness") + .01
    local highlight = create("Highlight", {
        DepthMode = Enum.HighlightDepthMode.Occluded,
        FillColor = Color3.new(1, 0, 0),
        FillTransparency = .8,
        Parent = self.Body,
    }, {
        create("Part", {
            Color = Color3.new(1, 1, 1),
            Size = vector(thicknessCap, .1, thicknessCap),
            Material = Enum.Material.SmoothPlastic,
            CanCollide = false,
            CastShadow = false,
            CanQuery = false,
            Anchored = true,
        }, {
            create("Highlight", { FillColor = Color3.new(1, 1, 1), FillTransparency = 0.00, OutlineTransparency = 1.00, DepthMode = Enum.HighlightDepthMode.Occluded })
        })
    })
    
    local function render(mouseCFrame: CFrame)
        
        local originCFrame = self.Body.Part.CFrame * CFrame.new(0, -self.Length/2, 0)
        local offset = originCFrame:ToObjectSpace(CFrame.new(mouseCFrame.Position))
        local height = math.round(offset.Position.Y)
        
        highlight.Part.CFrame = originCFrame * CFrame.new(0, height, 0)
        return height
    end
    local function unfocus()
        
        highlight:Destroy()
    end
    
    return unfocus, render
end
function Branch.prototype:FocusDivising()
    
    local thicknessCap = self:GetState("Thickness") + .01
    local highlight = create("Highlight", {
        DepthMode = Enum.HighlightDepthMode.Occluded,
        FillColor = Color3.new(1, 0, 0),
        FillTransparency = .8,
        Parent = self.Body,
    }, {
        Part1 = create("Part", {
            Color = Color3.new(1, 1, 1),
            Size = vector(.1, self:GetState("Length") + 0.01, thicknessCap),
            CanCollide = false,
            CastShadow = false,
            CanQuery = false,
            Anchored = true,
        }, {
            create("Highlight", { FillColor = Color3.new(1, 1, 1), FillTransparency = 0.00, OutlineTransparency = 1.00, DepthMode = Enum.HighlightDepthMode.Occluded })
        }),
        Part2 = create("Part", {
            Color = Color3.new(1, 1, 1),
            Size = vector(thicknessCap, self:GetState("Length") + .01, .1),
            CanCollide = false,
            CastShadow = false,
            CanQuery = false,
            Anchored = true,
        }, {
            create("Highlight", { FillColor = Color3.new(1, 1, 1), FillTransparency = 0.00, OutlineTransparency = 1.00, DepthMode = Enum.HighlightDepthMode.Occluded })
        })
    })
    
    local function render(mouseCFrame: CFrame)
        
        highlight.Part1.CFrame = self.BodyRoot.CFrame
        highlight.Part2.CFrame = self.BodyRoot.CFrame
    end
    local function unfocus()
        
        highlight:Destroy()
    end
    
    return unfocus, render
end

--// Override Protected Methods
function Branch.prototype:_renderBody(newRootPart, lastRootPart)
    
    if lastRootPart then
        
        self.Body = self.Body:Destroy()
        lastRootPart.Parent = nil
        
        if self._localRootPart == lastRootPart then lastRootPart:Destroy() end
    end
    
    if newRootPart then
        
        newRootPart.Transparency = 1.00
        newRootPart.Parent = workspace
        
        local children = { self._bodyBuilder(newRootPart, self:GetState("Thickness"), self:GetState("Length")) }
        self.Body = create("Model", { Parent = newRootPart, Name = "Body", PrimaryPart = children[1] }, children)
        self.BodyRoot = self.Body.PrimaryPart
        
        self._bodyWeld = create("WeldConstraint", {
            Part1 = self.BodyRoot,
            Part0 = newRootPart,
            Parent = self.BodyRoot,
        })
    end
end

--// End
local State: typeof(require(Packages.Core.State))
type numberState = State.numberState

export type Branch = typeof(Branch.prototype:constructor())

return Branch.ready() :: typeof(Branch)