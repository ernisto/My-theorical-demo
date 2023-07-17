--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local isSubClass, isA = Package.isSubClass, Package.IsA

local Exception = require(Packages.Core.Exception)
local getEmitterData = Exception.getEmitterData
local createException = Exception.create

local newFunction = require(Packages.Core.Function).new
local _expect = require(Packages.Core.Expectation).new

local EMPTY_FUNCTION = Package.EMPTY_FUNCTION

--// Class
local Promise = Package.class("Promise")
:: Package.Class<Promise> & {
    new: <R...>(task: (promise: Promise, ...any) -> R..., ...any) -> Promise<(R...) -> ...any, R...>
}

--// Enums
export type PromiseStatus = "fulfilled"|"rejected"|"pending"
local PromiseStatus = {
    Fulfilled = "fulfilled",
    Rejected = "rejected",
    Pending = "pending",
}
Promise.PromiseStatus = PromiseStatus

--// Private Functions
local function serializeException(exception: string|Exception|any)
    
    if not isA(exception, "Exception") then
        
        exception = createException("Exception", getEmitterData(2), 2, tostring(exception):gsub("%%", "%%"))
    end
    
    return exception
end
local function exceptionUnhandled(promise, exception)
    
    task.spawn(error, exception.Message..(exception.Traceback or exception.EmitterTraceback or ""), 0)
end

--// Class Functions
function Promise.promisify(asyncFunction: (promise: Promise, ...any) -> (...any)): (any...) -> Promise
    
    _expect(asyncFunction).is("function"):Argument(1, "asyncFunction")
    
    return function(...)
        
        return Promise.new(asyncFunction,...)
    end
end
function Promise.try(asyncFunction: (any...) -> (any...), ...: any): Promise
    
    _expect(asyncFunction).is("function"):Argument(1, "asyncFunction")
    
    return Promise.new(function(promise,...)
        
        return asyncFunction(...)
    end,...)
end
function Promise.all(promises: {Promise}): Promise
    
    if #promises == 0 then return Promise.value() end
    
    return Promise.new(function(promise)
        
        local results = {}
        
        for index, subPromise in promises do
            
            results[index] = {subPromise:Expect()}
        end
        
        return results
    end)
end
function Promise.value(...: any): Promise
    
    local promise = Promise.new()
    promise:Resolve(...)
    
    return promise
end

--// Constructor
function Promise.prototype:constructor(work: (promise: Promise, any...) -> (any...), ...: any)
    
    work = work or coroutine.yield
    
    _expect(work).is("function"):Argument(2, "work")
    
    self.Status = PromiseStatus.Pending :: PromiseStatus
    self.Traceback = Package.traceback(3)
    self.Timestamp = os.clock()
    self.AttemptTimestamp = -1
    self.IsCancelled = false
    self.TimeoutSeconds = -1
    self.RetryInterval = 0
    self.MaxAttempts = 1
    self.Attempt = 0
    
    self._bindableEvent = Instance.new("BindableEvent")
    self._finishedEvent = self._bindableEvent.Event
    self._result = table.pack(true)
    
    self.onCancel = EMPTY_FUNCTION
    self._exceptionHandlers = {
        { "PromiseCancelledException", EMPTY_FUNCTION },
        { "Exception", newFunction(exceptionUnhandled, self) },
    }
    
    self._thread = task.defer(function(...)
        
        for attempt = 1, self.MaxAttempts do
            
            self.AttemptTimestamp = os.clock()
            self.Attempt = attempt
            
            if self.Status ~= PromiseStatus.Pending then return end
            local result = table.pack(xpcall(work, serializeException, self,...))
            
            if result[1] or attempt == self.MaxAttempts then
                
                self:_resolve(unpack(result, 1, result.n))
                return
            else
                
                task.wait(self.RetryInterval)
            end
        end
    end,...)
    
    return self
end

--// Methods
function Promise.prototype:Catch(exceptionName: string, exceptionHandler: (exception: Exception) -> ()?,...: any): Promise
    
    exceptionHandler = exceptionHandler or EMPTY_FUNCTION
    
    _expect(exceptionName).is("string"):Argument(1, "exceptionName")
    _expect(isSubClass(exceptionName, "Exception")):Throws(2, "Exception", "Invalid exception name '%s'", exceptionName)
    _expect(exceptionHandler).is("function"):Argument(2, "exceptionHandler")
    
    exceptionHandler = newFunction(exceptionHandler,...)
    
    if self.Status == PromiseStatus.Pending then
        
        for index, exceptionHandlerInfo in self._exceptionHandlers do
        
            if exceptionHandlerInfo[1] == exceptionName then
                
                exceptionHandlerInfo[2] = exceptionHandler
                break
                
            elseif isSubClass(exceptionName, exceptionHandlerInfo[1]) then
                
                table.insert(self._exceptionHandlers, index, {exceptionName, exceptionHandler})
                break
            end
        end
        
    elseif self.Status == PromiseStatus.Rejected then
        
        local exception = self._result[2]
        
        if isSubClass(exception, exceptionName) then
            
            Package.async(exceptionHandler.call, exceptionHandler, exception)
        end
    end
    
    return self
end
function Promise.prototype:Timeout(timeout: number, exceptionName: string,...: any): Promise
    
    timeout = timeout or 1
    exceptionName = exceptionName or "PromiseTimedOutException"
    
    _expect(timeout).is("number"):Argument(1, "timeout")
    _expect(exceptionName).is("string"):Argument(2, "exceptionName")
    
    self.TimeoutSeconds = timeout
    
    if self.Status == PromiseStatus.Pending then
        
        local exception = createException(exceptionName, getEmitterData(2), 0,...)
        
        task.delay(timeout, function(...)
            
            self:_resolve(false, exception)
        end,...)
    end
    
    return self
end
function Promise.prototype:Retry(attempts: integer, interval: number): Promise
    
    attempts = attempts or -1
    interval = interval or 5
    
    _expect(attempts).is("integer"):Argument(1, "attempts")
    _expect(interval).is("number"):Argument(2, "interval")
    
    self.MaxAttempts = if attempts < 1 then 9e999 else attempts
    self.RetryInterval = interval
    
    return self
end
function Promise.prototype:Cancel(...: any): ()
    
    self:onCancel()
    self:_resolve(false, createException("PromiseCancelledException", getEmitterData(2), 2,...))
    self.IsCancelled = self.Status ~= Promise.Fulfilled
end

function Promise.prototype:Finally(finishedCallback: (success: boolean, any...) -> (),...: any): Promise
    
    _expect(finishedCallback).is("function"):Argument(1, "finishedCallback")
    
    finishedCallback = newFunction(finishedCallback,...)
    
    return Promise.new(function(promise)
        
        return finishedCallback(self:Await())
    end)
end
function Promise.prototype:ThenPromise(promisifyFunction: (any...) -> (Promise, ...any),...: any): Promise
    
    _expect(promisifyFunction).is("function"):Argument(1, "promisifyFunction")
    
    promisifyFunction = newFunction(promisifyFunction,...)
    
    return self:Then(function(...)
    
        local result = table.pack(promisifyFunction(...))
        if not result[1] then coroutine.yield() end
        
        return unpack(result, 2, result.n)
    end)
end
function Promise.prototype:Then(callback: (any...) -> (any...),...: any): Promise
    
    _expect(callback).is("function"):Argument(1, "callback")
    
    callback = newFunction(callback,...)
    
    return Promise.new(function(promise)
        
        local result = table.pack(self:Await())
        if not result[1] then coroutine.yield() end
        
        return callback(unpack(result, 2, result.n))
    end)
end
function Promise.prototype:ThenValue(...: any): Promise
    
    local values = table.pack(...)
    
    return self:Then(function()
        
        return unpack(values, 1, values.n)
    end)
end

function Promise.prototype:Await(): (boolean, any...)
    
    if self.Status == PromiseStatus.Pending then self._finishedEvent:Wait() end
    
    return unpack(self._result, 1, self._result.n)
end
function Promise.prototype:Expect(): (...any)
    
    local result = table.pack(self:Await())
    
    if result[1] then
        
        return unpack(result, 2, result.n)
    else
        
        result[2]:Throw(2)
    end
end
function Promise.prototype:Get(): (boolean?,...any)
    
    if self.Status == PromiseStatus.Pending then return nil end
    return unpack(self._result)
end
function Promise.prototype:Resolve(...: any)
    
    self:_resolve(true,...)
    return self
end

function Promise.prototype:Destroy()
    
    self:Cancel()
    Package.Destroy(self)
end

--// Private Methods
function Promise.prototype:_resolve(success: boolean,...: any)
    
    if self.Status ~= PromiseStatus.Pending then return end
    
    self._result = table.pack(success,...)
    if coroutine.running() ~= self._thread then task.cancel(self._thread) end
    
    if success then
        
        self.Status = PromiseStatus.Fulfilled
    else
        
        self.Status = PromiseStatus.Rejected
        local exception = ...
        
        --// Handle Exception
        for _,handlerInfo in self._exceptionHandlers do
            
            local handlerExceptionType, handler = handlerInfo[1], handlerInfo[2]
            
            if isA(exception, handlerExceptionType) then
                
                handler(exception)
                break
            end
        end
    end
    
    --// Give Result
    self._bindableEvent:Fire()
    self._bindableEvent:Destroy()
    self._finishedCallbacks = nil
    self._exceptionHandlers = nil
    self._awaitingThreads = nil
    self._finishedEvent = nil
    self._bindableEvent = nil
end

--// End
type Exception = Exception.Exception

export type Promise<F, R...> = typeof(Promise.prototype:constructor()) & {
    Finally: (Promise<F, R...>, callback: (success: boolean, R...) -> (),...any) -> Promise<F, R...>,
    ThenValue: <V...>(Promise<F, R...>, V...) -> Promise<(V...)->(), V...>,
    Then: (Promise<F, R...>, callback: F,...any) -> Promise<F, R...>,
    Await: (Promise<F, R...>) -> (boolean, R...),
    Expect: (Promise<F, R...>) -> R...,
}

return Promise