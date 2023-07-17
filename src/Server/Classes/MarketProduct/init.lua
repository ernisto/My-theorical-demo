--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local MarketplaceService = game:GetService("MarketplaceService")
local RemoteObject = require(Packages.Server.RemoteObject)

local ProductReceipt = require(script.ProductReceipt)
type ProductReceipt = ProductReceipt.ProductReceipt

local getPlayerFromId = require(Packages.Server.Classes.Player).getPlayerFromId
local Promise = require(Packages.Core.Promise)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local EMPTY_FUNCTION = Package.EMPTY_FUNCTION
local SET = Package.SET
local isA = Package.IsA

--// Class
local MarketProduct = Package.class("MarketProduct").extends(RemoteObject)
:: Package.Class<MarketProduct> & {
    new: (productId: number, processor: (receipt: ProductReceipt) -> (), checker: checker?) -> MarketProduct
}

--// Vars
local receipts = {}
local products = {}

--// Class Functions
function MarketProduct.async.getProductsAsync()
end

--// Constructor
type checkData = {
    PurchaserId: number,
    TargetId: number,
    Purchaser: Player?,
    Target: Player?,
    [string]: any,
}

function MarketProduct.prototype:constructor(productId: number, processor: (receipt: ProductReceipt)->()?, checker: (checkData: checkData)->()?)
    
    processor = processor or error
    checker = checker or EMPTY_FUNCTION
    
    _expect(productId).is("integer"):Argument(1, "productId")
    _expect(processor).is("function"):Argument(2, "processor")
    _expect(checker).is("function"):Argument(3, "checker")
    
    local info = Promise.try(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
        :Retry(-1)
        :Expect()
    
    --// Instance
    RemoteObject(self)
    
    self.client.Description = info.Description :: string?
    self.client.IconId = info.IconImageAssetId :: number
    self.client.IsForSale = info.IsForSale :: boolean
    self.client.Price = info.PriceInRobux :: number
    self.client.Name = info.Name :: string
    self.client.ID = productId :: number
    
    self.Process = processor
    self.Check = checker
    
    self._pendingReceiptDatas = {}
    self.client:AddEveryone()
    
    products[productId] = self
    return self
end

--// Client Signals
function MarketProduct.prototype.client.signal.ReceiptDataLost(receipt: Receipt) end

--// Client Methods
function MarketProduct.prototype.client:_purchaseRemote(player, targetId: number?, data: table?)
    
    expect(targetId == nil or type(targetId) == "number" or isA(targetId, "Player"), "Invalid argument #1 (target)")
    expect(data == nil or type(data) == "table", "Invalid argument #2 (data)")
    
    return self:PromptAsync(player, targetId, data):Expect()
end

--// Methods
function MarketProduct.prototype.async:PromptAsync(promise, purchaser: Player, targetId: number?, data: table?)
    
    targetId = if isA(targetId, "Player") then targetId.UserId else targetId or purchaser.UserId
    data = data or {}
    
    _expect(purchaser).is("Player"):Argument(1, "purchaser")
    _expect(targetId).is("integer"):Argument(2, "targetId")
    _expect(data).all.index.is("string"):Argument(3, "data")
    
    setmetatable(data, {__index = {
        Target = getPlayerFromId(targetId),
        PurchaserId = purchaser.UserId,
        Purchaser = purchaser,
        TargetId = targetId,
    }})
    
    expect(self._pendingReceiptDatas[purchaser] == nil, "A receipt already pending")
    self.Check(data)
    
    local receiver = Promise.new()
    receiver:Finally(SET, self._pendingReceiptDatas, purchaser, nil)
    
    self._pendingReceiptDatas[purchaser] = {data, targetId, receiver}
    
    MarketplaceService:PromptProductPurchase(purchaser.RbxPlayer, self.ID)
    return receiver:Then(assert):Expect()
end

--// Private Methods
function MarketProduct.prototype:_getReceipt(receiptData: table): ProductReceipt
    
    _expect(receiptData).is("table"):Argument(1, "receiptData")
    
    local receipt = receipts[receiptData.PurchaseId]
    if receipt then return receipt end
    
    receipt = ProductReceipt.new(receiptData, self)
    receipts[receiptData.PurchaseId] = receipt
    
    return receipt
end

function MarketProduct.prototype:_awaitLoadReceiptData(receipt: ProductReceipt): Promise<(success: boolean, exception: string)->(), boolean, string>?
    
    local data, targetId, receiver = unpack(self._pendingReceiptDatas[receipt.Purchaser] or self:_awaitPromptDataLost(receipt))
    receipt:SetData(targetId, data)
    
    return receiver
end
function MarketProduct.prototype:_awaitPromptDataLost(receipt: ProductReceipt)
    
    print("coming soon")    --! IDK WHAT I DO HERE
    coroutine.yield()
    
    self.ReceiptDataLost:FireOnPlayers{ receipt.Purchaser }
    return {}
end

--// Callbacks
function MarketplaceService.ProcessReceipt(receiptData)
    
    local product = expect(products[receiptData.ProductId], "Product not found")
    
    local receipt = product:_getReceipt(receiptData)
    local success, exception, receiver
    
    expect(not receipt.ProcessingLocked, "Processing is locked")
    receipt:LockProcessing()
    
    if not receipt.ClientData then
        
        receiver = product:_awaitLoadReceiptData(receipt)
    end
    
    success, exception = receipt:TryAwaitProcess()
    
    if receiver then receiver:Resolve(success, exception) end
    if success then return Enum.ProductPurchaseDecision.PurchaseGranted end
end
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
    
    if isPurchased then return end
    
    local product = expect(products[productId], "Product not found")
    
    local purchaser = getPlayerFromId(userId)
    if not purchaser then return end
    
    local pendingReceiptData = product._pendingReceiptDatas[purchaser]
    if not pendingReceiptData then return end
    
    local receiver = pendingReceiptData[3]
    if not receiver then return end
    
    receiver:Cancel()
end)

--// End
export type MarketProduct = typeof(MarketProduct.prototype:constructor()) & Package.Object

return MarketProduct