--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local Function = require(Packages.Core.Function)
local _expect = require(Packages.Core.Expectation).new

local async = Package.async

--// Class
local Connection = Package.class("Connection").extends(Function)
:: Package.Class<Connection> & {
    new: (signal: Signal, callback: (...any) -> (), ...any) -> Connection,
}

--// Constructor
function Connection.prototype:constructor(signal: Signal, callback: (...any) -> (),...: any)
    
    _expect(signal).is("Signal"):Argument(1, "signal")
    _expect(callback).is.some("function", "Function"):Argument(3, "callback")
    
    --// Instance
    Function(self, callback,...)
    
    self.Tag = nil  :: string?
    self.IsConnected = false
    self.Priority = 0
    
    self._signal = setmetatable({ signal }, { __mode = "v" })
    return self
end

--// Methods
function Connection.prototype:SetPriority(priority: integer): Connection
    
    _expect(priority).is("integer"):Argument(1, "priority")
    
    return self:Reconnect(priority)
end
function Connection.prototype:SetTag(tag: string?): Connection
    
    _expect(tag).is.some("string", "nil"):Argument(1, tag)
    
    local signal = self._signal[1]
    if not signal then return self end
    
    local taggedConnections = signal._taggedConnections
    
    if self.Tag then taggedConnections[self.Tag] = nil end
    self.Tag = tag
    
    if not tag then return self end
    if taggedConnections[tag] then taggedConnections[tag]:Disconnect() end
    taggedConnections[tag] = self
    
    return self
end

function Connection.prototype:Disconnect(): ()
    
    local signal = self._signal[1]
    if not signal then return end
    
    local connections = signal._connections
    local index = table.find(connections, self)
    
    if not index then return self end
    table.remove(connections, index)
    
    self.IsConnected = false
    return self
end
function Connection.prototype:Reconnect(priority: integer): ()
    
    priority = priority or 0
    
    _expect(priority).is("integer"):Argument(1, "priority")
    
    local signal = self._signal[1]
    if not signal then return self end
    
    local selfTag = self.Tag
    local taggedConnections = signal._taggedConnections
    if selfTag and taggedConnections[selfTag] then taggedConnections[selfTag]:Disconnect() end
    
    if self.IsConnected then self:Disconnect() end
    self.IsConnected = true
    
    --// Insert Connection
    local connections = signal._connections
    self.Priority = priority
    
    for index, connection in connections do
        
        if connection.Priority > priority then
            
            table.insert(connections, index, self)
            return self
        end
    end
    
    table.insert(connections, self)
    return self
end

function Connection.prototype:Destroy(): ()
    
    self:Disconnect()
    Package.Destroy(self)
end

--// Behaviour
function Connection.prototype:components()
    
    return self.Tag or self.Name or (self.Path..":"..self.Line) or "unnamed", if self.IsConnected then "'connected'" else "'disconnected'"
end
function Connection.prototype:__call(...)
    
    async(self.call, self,...)
end

Connection.prototype.tostring = Package.tostring

--// End
export type Connection = typeof(Connection.prototype:constructor())

return Connection