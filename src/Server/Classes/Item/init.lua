--// Core
local PhysicsService = game:GetService("PhysicsService")
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>
type integer = number

--// Packages
local ProfiledObject = require(Packages.Server.ProfiledObject)
local RemoteObject = require(Packages.Server.RemoteObject)

local create = require(Packages.Libraries.Component).create
local Expectation = require(Packages.Core.Expectation)
local _expect = Expectation.new

local SkillHandler = require(Packages.Server.Classes.SkillHandler)
type SkillHandler = SkillHandler.SkillHandler

--// Setup
PhysicsService:RegisterCollisionGroup("Items")
PhysicsService:CollisionGroupSetCollidable("Items", "Characters", false)
PhysicsService:CollisionGroupSetCollidable("Items", "Items", false)

--// Abstract Class
local Item = Package.class("Item").extends(RemoteObject, ProfiledObject)
:: RemoteObject.Class<Item>

--// Vars
local itemConstructors = {}

--// Enums
export type ItemStatus = "suspended"|"equipped"|"handled"|"dropped"|"placed"|"stored"
local ItemStatus = {
    Suspended = "suspended",
    Equipped = "equipped",
    Handled = "handled",
    Dropped = "dropped",
    Placed = "placed",
    Stored = "stored",
}
Item.ItemStatus = ItemStatus

--// Class Functions
function Item.create(itemName: string,...: any): Item
    
    _expect(itemName).is("string"):Argument(1, "itemName")
    
    return itemConstructors[itemName](...)
end

--// Protected Functions
function Item.prototype:_register(name: string)
    
    _expect(name).is("string"):Argument(1, "name")
    
    itemConstructors[name] = self.new
end

--// Constructor
function Item.prototype:constructor(itemData)
    
    _expect(itemData).is.some("table", "nil"):Argument(1, "itemData")
    
    local itemName = if itemData then itemData.Name else self:GetType()
    
    --// Instance
    RemoteObject(self, itemName)
    ProfiledObject(self)
    
    self.profile.Name = itemName
    self.profile.Amount = 1
    
    self.client.Status = ItemStatus.Suspended   :: ItemStatus
    self.client.RootPart = nil  :: Part?
    self.client.Skills = {}     :: { [string]: SkillHandler }
    self.client.Owner = nil     :: Character?
    
    self.GripCFrame = CFrame.new()
    self.TwoHanded = false
    self.MaxAmount = 1
    
    self._weld = nil :: Weld?
    
    --// Setup
    self:_applyData(itemData)
    return self
end

--// Remote Signals
function Item.prototype.client.signal.Unowned(lastOwner: Character) end
function Item.prototype.client.signal.Owning(newOwner: Character) end

function Item.prototype.client.signal.Suspending() end
function Item.prototype.client.signal.Suspended() end
function Item.prototype.client.signal.Resuming() end
function Item.prototype.client.signal.Resumed() end

function Item.prototype.client.signal.Storing(bag: Bag, slot: integer) end
function Item.prototype.client.signal.Stored(bag: Bag, slot: integer) end
function Item.prototype.client.signal.Releasing() end
function Item.prototype.client.signal.Released() end

function Item.prototype.client.signal.Handling(handler: Character) end
function Item.prototype.client.signal.Handled(handler: Character) end
function Item.prototype.client.signal.Unhandling() end
function Item.prototype.client.signal.Unhandled() end

--// Methods
function Item.prototype:SetAmount(amount: integer)
    
    _expect(amount).is("integer"):Argument(1, "amount")
    
    self:_setState("Amount", amount)
end

function Item.prototype:Handle(handler: Character)
    
    _expect(handler).is("Character"):Argument(1, "handler")
    
    self.Handling(handler)
    self:_handle(handler)
    self.Handled(handler)
end
function Item.prototype:Store(bag: Bag, slot: integer)
    
    _expect(bag).is("Bag"):Argument(1, "bag")
    _expect(slot).is("integer"):Argument(2, "slot")
    
    self.Storing(bag, slot)
    self:_store(bag, slot)
    self.Stored(bag, slot)
end
function Item.prototype:Suspense()
    
    if self.Status == ItemStatus.Suspended then return end
    
    self.Suspending()
    self:_suspense()
    self.Suspended()
end

--// Virtual Protected Methods
function Item.prototype:_handle(handler: Character)
    
    self:_setOwner(handler)
    self:_setStatus(ItemStatus.Handled)
        .Changed:Once(self._unhandling, self)
    
    self.client:AddEveryone()
end
function Item.prototype:_store(bag: Bag, slot: integer)
    
    self:_setOwner(bag.Owner)
    self:_setStatus(ItemStatus.Stored)
        .Changed:Once(self._release, self)
    
    self.client:SetPlayers{ if bag.Owner then bag.Owner.Player else nil }
    
    self.Slot = slot
    self.Bag = bag
end
function Item.prototype:_suspense()
    
    self:_setOwner(nil)
    self:_setStatus(ItemStatus.Suspended)
        .Changed:Once(self._resume, self)
    
    self.client:SetPlayers{}
end

function Item.prototype:_unhandle()
end
function Item.prototype:_release()
    
    self.Slot = nil
    self.Bag = nil
end
function Item.prototype:_resume()
end

function Item.prototype:_createRootPart(): Part
    
    local rootPart = create("Part", {
        Name = tostring(self),
        Size = Vector3.one,
        Parent = workspace,
        CanCollide = false,
        CanTouch = false,
        RootPriority = -127,
        CollisionGroup = "Items",
    })

    return rootPart
end
function Item.prototype:_unweld()
    
    if not self._weld then return end
        
    self._weld:Destroy()
    self._weld = nil
end

--// Protected Methods
function Item.prototype:_setSkill(category: string, name: string, handler: (self: Item, skill: Skill,...any) -> ...any)
    
    _expect(category, name).is("string"):Argument(1, "category", "name")
    _expect(handler).is("function"):Argument(3, "handler")
    
    local skillHandler = SkillHandler.new(name, function(...) return handler(self,...) end)
    self.Skills[category] = self:Hoste(skillHandler)
    
    return skillHandler
end

function Item.prototype:_weldTo(basePart: BasePart, offset: CFrame|CFrameState?): Weld
    
    _expect(basePart).is("BasePart"):Argument(1, "basePart")
    _expect(offset).is.some("CFrame", "State", "nil"):Argument(2, "offset")
    
    self:_unweld()
    
    local rootPart = self:_enableRootPart()
    local weld = create("Weld", {
        Parent = rootPart,
        Part1 = rootPart,
        Part0 = basePart,
        C0 = offset,
    })
    
    self._weld = weld
    return weld
end
function Item.prototype:_setOwner(newOwner: Character?): State<Character?>
    
    _expect(newOwner).is.some("Character", "nil"):Argument(1, "newOwner")
    
    local lastOwner = self.Owner
    if newOwner == lastOwner then return end
    
    if lastOwner then self.Unowned(lastOwner) end
    if newOwner and lastOwner then self:Suspense() end
    if newOwner then self.Owning(newOwner) end
    
    for _,skillHandler in self.Skills do skillHandler:SetActivators{ if newOwner then newOwner.Player else nil } end
    return self:_setState("Owner", newOwner)
end
function Item.prototype:_setStatus(status: ItemStatus): State<ItemStatus>
    
    _expect(status).is("string"):Argument(1, "newStatus")
    
    return self:_setState("Status", status)
end

function Item.prototype:_disableRootPart(): Part
    
    if not self.RootPart then return end
    self.RootPart:Destroy()
    
    self:_setState("RootPart", nil)
end
function Item.prototype:_enableRootPart(): Part
    
    if self.RootPart then return self.RootPart end
    
    local rootPart = self:_createRootPart()
    self:_setState("RootPart", rootPart)
    
    return rootPart
end

--// Private Methods
function Item.prototype:_unhandling()
    
    self.Unhandling()
    self:_unhandle()
    self.Unhandled()
end
function Item.prototype:_releasing()
    
    self.Releasing()
    self:_release()
    self.Released()
end
function Item.prototype:_resuming()
    
    self.Resuming()
    self:_resume()
    self.Resumed()
end

--// Behaviour
function Item.prototype:destroying()
    
    self:Suspense()
end

--// Types
local Branch: typeof(require(Packages.Server.Classes.Item.Building.Branch))
export type Branch = Branch.Branch

local Axe: typeof(require(Packages.Server.Classes.Item.Tool.Axe))
export type Axe = Axe.Axe

local Bag: typeof(require(Packages.Server.Classes.Item.Tool.Bag))
export type Bag = Bag.Bag

local Character: typeof(require(Packages.Server.Classes.Character))
type Character = Character.Character

local State: typeof(require(Packages.Core.State))
type numberState = State.numberState

type statusChanged = (self: Item, newOwner: Character?, lastOwner: Character?, newStatus: ItemStatus, lastStatus: ItemStatus) -> ()

--// End
export type Item = typeof(Item.prototype:constructor()) & RemoteObject.RemoteObject

return Item :: typeof(Item) & {
    create: typeof(Item.create)
        & ((itemName: "OakBranch") -> Branch)
        & ((itemName: "Axe") -> Axe)
        & ((itemName: "Bag") -> Bag)
}