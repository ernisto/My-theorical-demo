--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Connection = Package.Connection
type Promise<F, R...> = Package.Promise<F, R...>

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Placeable = require(Packages.Server.Classes.Item.Placeable)
local Item = require(Packages.Server.Classes.Item)
local ItemStatus = Item.ItemStatus

local State = require(Packages.Core.State)
local vector = State.vector
local cframe = State.cframe
local deg = State.deg

local Component = require(Packages.Libraries.Component)
local create = Component.create

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local isA = Package.IsA

--// Class
local Branch = Package.class("Branch").extends(RemoteObject, Item, Placeable)
:: RemoteObject.Class<Branch>

--// Consts
local LENGTH_PER_SECOND = 10/3

--// Constructor
Branch:_register("Branch")

function Branch.prototype:constructor(thickness: integer?, length: integer?)
    
    thickness = thickness or 0
    length = length or 0
    
    _expect(thickness).is("number"):Argument(2, "thickness")
    _expect(length).is("number"):Argument(3, "length")
    
    --// Instance
    Item(self)
    Placeable(self)
    
    self.client.Thickness = thickness
    self.client.Length = length
    
    self.client.GripCFrame = CFrame.new()
        ;(cframe(0, self:GetState("Thickness")/-2, 0) * deg(90, 0, 0)):Bind(self:GetState("GripCFrame"))
    
    self._branches = {}         :: {[Branch]: integer}
    self._growthPromise = nil   :: Promise<()->()>?
    self._orientation = nil     :: Vector3?
    
    self:GetState("Length").Changed:Connect(function(newLength, lastLength)
        
        if self.Status ~= ItemStatus.Dropped then return end
        
        self.RootPart.CFrame *= CFrame.new(0, (newLength - lastLength)/2, 0)
    end)
    
    return self
end

--// Methods
function Branch.prototype.async:ExtendAsync(promise, height: integer, rotX: number, rotY: number, thickness: integer?, length: integer?): Branch
    
    thickness = thickness or 0
    length = length or 0
    
    _expect(height).is("integer"):Argument(1, "height")
    _expect(rotX, rotY).is("number"):Argument(2, "rotX", "rotY")
    _expect(thickness).is.some("number", "nil"):Argument(4, "thickness")
    _expect(length).is.some("integer", "nil"):Argument(5, "length")
    
    while self.Length < height do
        
        self:GetState("Length").Changed:Await()
    end
    
    local subBranch = Item.create(self.Name, 1, thickness, length)
        :WeldToBranch(self, height, rotX, rotY)
    
    return subBranch
end
function Branch.prototype.async:GrowthAsync(promise, thicknessGoal: integer, lengthGoal: integer): Branch
    
    _expect(thicknessGoal).is("number"):Argument(1, "thicknessGoal")
    _expect(lengthGoal).is("number"):Argument(2, "lengthGoal")
    
    local lengthBegin = self.Length
    if lengthBegin >= lengthGoal then return end
    
    self:Kill()
    self._growthPromise = promise
    
    local thicknessBegin = self.Thickness
    local deltaThickness = thicknessGoal - thicknessBegin
    
    for fade = 0, 1, 1/(lengthGoal - lengthBegin) do
        
        if fade == 0 then continue end
        task.wait(1/LENGTH_PER_SECOND)
        
        self:_setState("Thickness", thicknessBegin + deltaThickness*fade)
        self:_increaseState("Length", 1)
    end
    
    self._growthPromise = nil
end

function Branch.prototype:Chop(cutHeight: integer, fallDirection: Vector3): Branch?
    
    fallDirection = fallDirection or self.RootPart.CFrame.UpVector
    
    _expect(cutHeight).is("integer"):Argument(1, "newLength")
    _expect(0 <= cutHeight and cutHeight <= self.Length):ThrowsMessage(2, "Length must to be 0 <= cutHeight (%s) <= self.Length (%s)", cutHeight, self.Length)
    expect(fallDirection.Magnitude <= 1.01, "Argument #2 (fallDirection) must to be a unitary Vector3, got %s", fallDirection)
    
    if cutHeight == 0 then return self:Drop() end
    
    local offLength = self.Length - cutHeight
    local offBranch
    
    self:_setState("Length", cutHeight)
    
    if offLength > 0 then
        
        offBranch = Item.create(self.Name, self.Thickness, offLength)
        offBranch:Drop(
            self:GetOriginWorldCFrame()
            * CFrame.new(0, cutHeight, 0)   -- = cut cframe
            * CFrame.lookAt(Vector3.zero, -fallDirection + Vector3.new(0, 3, 0))   -- + fall orientation
            * CFrame.Angles(-math.pi/2, 0, 0)   -- + angle compensation idk why
            * CFrame.new(0, offLength/2, 0) -- + size compensation
        )
    end
    
    for branch, height in self._branches do
        
        if height > cutHeight then
            
            branch:WeldToBranch(offBranch, height - cutHeight, unpack(branch._orientation))
            
        elseif height == cutHeight then
            
            branch:Drop()
        end
    end
    
    return offBranch
end
function Branch.prototype:Divise()
    
    local selfThickness = self.Thickness/2
    local selfCFrame = self.RootPart.CFrame
    local selfLength = self.Length
    
    self:Destroy()
    Branch.new(selfThickness, selfLength):Drop(selfCFrame * CFrame.new( selfThickness/4, 0,  selfThickness/4))
    Branch.new(selfThickness, selfLength):Drop(selfCFrame * CFrame.new( selfThickness/4, 0, -selfThickness/4))
    Branch.new(selfThickness, selfLength):Drop(selfCFrame * CFrame.new(-selfThickness/4, 0,  selfThickness/4))
    Branch.new(selfThickness, selfLength):Drop(selfCFrame * CFrame.new(-selfThickness/4, 0, -selfThickness/4))
end

function Branch.prototype:WeldToBranch(rootBranch: Branch, height: integer, rotX: number, rotY: number): Branch
    
    _expect(rootBranch).is("Branch"):Argument(1, "rootBranch")
    _expect(height).is("integer"):Argument(2, "height")
    _expect(rotX, rotY).is("number"):Argument(3, "rotX", "rotY")
    
    self._orientation = {rotX, rotY}
    self:WeldedPlaceTo(rootBranch,
        deg(0, rotY, 0)
        * cframe(0, height - rootBranch._computedHeight, rootBranch:GetState("Thickness")/2)
        * deg(rotX, 0, 0)
        * cframe(0, self._computedHeight, self:GetState("Thickness")/-2)
    )
    
    rootBranch:_addBranch(self, height)
    return self
end
function Branch.prototype:Kill()
    
    for branch in self._branches do branch:Kill() end
    
    if self._growthPromise then self._growthPromise:Cancel() end
    self._growthPromise = nil
end

--// Override Protected Methods
function Branch.prototype:_createRootPart()
    
    return create("Part", {
        CustomPhysicalProperties = PhysicalProperties.new(10.00, 0.60, 0.00),
        Name = tostring(self),
        Parent = workspace,
        Size = vector(
            self:GetState("Thickness"),
            self:GetState("Length"),
            self:GetState("Thickness")
        ),
    })
end
function Branch.prototype:_unweld()
    
    if isA(self.Surface, "Branch") then self.Surface:_removeBranch(self) end
    self:Kill()
    
    Placeable._unweld(self)
end

--// Private Methods
function Branch.prototype:_addBranch(branch: Branch, height: integer)
    
    _expect(branch).is("Branch"):Argument(1, "branch")
    _expect(height).is("integer"):Argument(2, "height")
    
    self._branches[branch] = height
    branch:GetState("Surface").Changed:Once(self._removeBranch, self, branch)
end
function Branch.prototype:_removeBranch(branch: Branch)
    
    _expect(branch).is("Branch"):Argument(1, "branch")
    
    self._branches[branch] = nil
end

--// Behaviour
function Branch.prototype:destroying()
    
    for branch in self._branches do
        
        branch:_unweld()
    end
    
    Placeable.destroying(self)
    Item.destroying(self)
end

--// End
export type Branch = typeof(Branch.prototype:constructor()) & Item.Item & Placeable.Placeable & {
    ExtendAsync: (height: integer, orientation: Vector3, thickness: integer?, length: integer?) -> Promise<(self: Branch)->(), Branch>,
    GrowthAsync: (thicknessGoal: integer, lengthGoal: integer) -> Promise<(self: Branch) -> (), Branch>,
}

return Branch