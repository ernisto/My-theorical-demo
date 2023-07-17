--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ProfiledObject = require(Packages.Server.ProfiledObject)
local RemoteObject = require(Packages.Server.RemoteObject)

local getPlayerFromId = require(Packages.Server.Classes.Player).getPlayerFromId
local _expect = require(Packages.Core.Expectation).new

--// Class
local ProductReceipt = Package.class("ProductReceipt").extends(RemoteObject, ProfiledObject)
:: Package.Class<ProductReceipt> & {
    new: (receiptData: receiptData, product: MarketProduct) -> ProductReceipt
}

--// Constructor
type receiptData = {
    PlaceIdWherePurchased: number,
    CurrencySpent: number,
    PurchaseId: number,
    PlayerId: number,
}

function ProductReceipt.prototype:constructor(receiptData: receiptData, product: MarketProduct)
    
    _expect(receiptData).is("table"):Argument(1, "receiptData")
    _expect(product).is("MarketProduct"):Argument(2, "product")
    
    local id = receiptData.PurchaseId
    
    --// Instance
    RemoteObject(self)
    ProfiledObject(self, id)
    
    self.profile.PlaceId = receiptData.PlaceIdWherePurchased
    self.profile.PurchaserId = receiptData.PlayerId
    self.profile.Spent = receiptData.CurrencySpent
    self.profile.PurchaseTimestamp = os.time()
    self.profile.HasProcessed = false
    self.profile.ClientData = nil
    self.profile.TargetId = nil
    self:GetDataAsync():Expect()
    
    self.client.Purchaser = if self.PurchaserId then getPlayerFromId(self.PurchaserId) else nil
    self.client.Target = if self.TargetId then getPlayerFromId(self.TargetId) else nil
    self.client.Product = product
    self.client.ID = id
    
    self.ProcessingLocked = false
    self._processor = product.Process
    return self
end

--// Methods
function ProductReceipt.prototype:SetData(targetId, data: {[string]: any})
    
    _expect(targetId).is("integer"):Argument(1, "targetId")
    _expect(data).all.index.is("string"):Argument(2, "data")
    
    self:_setState("ClientData", data)
    self:_setState("TargetId", targetId)
end
function ProductReceipt.prototype:LockProcessing()
    
    self.ProcessingLocked = true
end

function ProductReceipt.prototype:TryAwaitProcess(): (boolean, string)
    
    if self.HasProcessed then return true end
    
    self:_setState("Purchaser", if self.PurchaserId then getPlayerFromId(self.PurchaserId) else nil)
    self:_setState("Target", if self.TargetId then getPlayerFromId(self.TargetId) else nil)
    
    local success, exception = pcall(self._processor, self)
    self:_setState("HasProcessed", success)
    
    self.ProcessingLocked = false
    
    if success then
        
        self._profilePromise:Expect():Release()
        return self
    else
        
        return false, exception
    end
end

--// End
export type ProductReceipt = typeof(ProductReceipt.prototype:constructor()) & Package.Object

return ProductReceipt