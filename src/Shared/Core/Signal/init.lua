--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, R...> = Package.Promise<F, R...>

--// Packages
local Connection = require(script.Connection)
export type Connection = Connection.Connection

local _expect = require(Packages.Core.Expectation).new
local isA = Package.IsA

--// Class
local Signal = Package.class("Signal")
:: Package.Class<Signal> & {
    new: <F>(name: string, middleTask: F) -> Signal<F>,
}

--// Constructor
function Signal.prototype:constructor(name: string)
    
    name = name or "unnamed"
    
    _expect(name).is("string"):Argument(1, "name")
    
    local bindableEvent = Instance.new("BindableEvent")
    
    --// Instance
    self.HasConnected = false
    self.Name = name
    
    self._rbxSignal = bindableEvent.Event
    self._bindableEvent = bindableEvent
    
    self._taggedConnections = setmetatable({}, { __mode = "v" })
    self._connections = {}
    self._data = {}
    
    return self
end

--// Methods
function Signal.prototype:Once(callback: (...any) -> ...any, ...: any): Connection
    
    _expect(callback).is("function"):Argument(1, "callback")
    
    local connection; connection = self:Connect(function(...)
        
        connection:Disconnect()
        callback(...)
    end,...)
    
    return connection
end
function Signal.prototype:Connect(callback: (...any) -> ...any, ...: any): Connection
    
    _expect(callback).is.some("function", "Function", "Signal"):Argument(1, "callback")
    
    self.HasConnected = true
    
    local connection = if isA(callback, "Signal")
        then Connection.new(self, callback.__call, callback,...)
        else Connection.new(self, callback,...)
    
    connection:Reconnect()
    return connection
end
function Signal.prototype:GetConnection(connectionName: string): Connection?
    
    _expect(connectionName).is("string"):Argument(1, "connectionName")
    
    return self._taggedConnections[connectionName]
end

function Signal.prototype:Disconnect(connectionTag: string): Connection?
    
    _expect(connectionTag).is("string"):Argument(1, "connectionName")
    
    if not self._taggedConnections[connectionTag] then return end
    return self._taggedConnections[connectionTag]:Disconnect()
end
function Signal.prototype:DisconnectAll(): ()
    
    for _,connection in self._connections do
        
        connection:Disconnect()
    end
end

function Signal.prototype:AwaitWithTimeout(timeout: number): (boolean,...any)
    
    _expect(timeout).is("number"):Argument(1, "timeout")
    
    local resultGiver = Signal.new()
    local connection, thread
    
    connection = self:Connect(function(...)
        
        task.cancel(thread)
        resultGiver(true,...)
    end)
    thread = task.delay(timeout, function()
        
        connection:Disconnect()
        resultGiver(false)
    end)
    
    return resultGiver:Await()
end
function Signal.prototype:Await(): ...any
    
    self._rbxSignal:Wait()
    return unpack(self._data)
end
Signal.prototype.Wait = Signal.Await

--// Override Methods
function Signal.prototype:Destroy()
    
    self._bindableEvent:Destroy()
    self:DisconnectAll()
    
    Package.Destroy(self)
end

--// Behaviour
function Signal.prototype:TryCall(...: any)
    
    return pcall(self,...)
end
function Signal.prototype:__call(...: any)
    
    local connections = self._connections
    
    for _,connection in table.clone(connections) do connection(...) end
    
    self._data = {...}
    self._bindableEvent:Fire()
    self._data = nil
end
function Signal.prototype:components()
    
    return self.Name
end

--// End
export type Signal<F> = typeof(Signal.prototype:constructor()) & F & {
    Connect: (self: Signal<F>, callback: F, ...any) -> Connection,
    Once: (self: Signal<F>, callback: F, ...any) -> Connection,
}

return Signal