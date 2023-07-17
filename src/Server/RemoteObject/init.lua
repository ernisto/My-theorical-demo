--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ClassReplicator = require(script.ClassReplicator) task.wait()
type ClassReplicator = ClassReplicator.ClassReplicator

local _expect = require(Packages.Core.Expectation).new

--// Class
local RemoteObject = Package.class("RemoteObject")

--// Signals
RemoteObject.PlayerSessionLoaded = ClassReplicator.PlayerSessionLoaded

--// Constructor
function RemoteObject.prototype:constructor(...: any)
    
    local replicator = self._classReplicator:Object(self,...)
    
    --// Instance
    self.Token = replicator.Token :: number
    self.client = replicator :: ObjectReplicator
    return self
end
function RemoteObject.prototype:postconstruct()
    
    self.client:Ready()
end

--// Virtual Protected Methods
function RemoteObject.prototype:_awaitHaveReplicationAccess(userId: integer)
    
    _expect(userId).is("integer"):Argument(1, "userId")
    
    local replicator = self.client
    if replicator.Players[userId] then return true end
    
    if not replicator.ReplicatesWhenRequestEnabled then return false end
    
    replicator:AddPlayers{ userId }
    return true
end

--// Properties
RemoteObject.prototype._classReplicator = nil :: ClassReplicator

--// Behaviour
function RemoteObject.prototype:extended(subClass: Class,...)
    
    if subClass:IsA("RemoteObject") then
        
        subClass._baseClasses[self] = true
        Package.extended(self, subClass, "_classReplicator", "client",...)
    else
        
        return Package.extended(self, subClass,...)
    end
    
    for methodName, remoteMethod in self.prototype.client.methods do
        
        subClass.prototype.client.methods[methodName] = remoteMethod
    end
    for signalName, signalPath in self.prototype.client.signal do
        
        subClass.prototype.client.signal[signalName] = signalPath
    end
    for stateName, stateValue in self.prototype.client.state do
        
        subClass.prototype.client.state[stateName] = stateValue
    end
end
function RemoteObject:extended(subClass: Class,...)
    
    Package.extended(self, subClass,...)
    
    --// Create Replicator
    local subClassReplicator = ClassReplicator.new(subClass)
    subClass.prototype._classReplicator = subClassReplicator
    
    subClass.prototype.client = subClassReplicator._prototype
    subClass.client = subClassReplicator._static
    
    subClass._states = subClassReplicator._states
    subClass._baseClasses = {}
end

function RemoteObject.prototype:tostring(...)
    
    return "%t#%s(%*s)", self, self.Token, {...}
end

--// End
local ObjectReplicator: typeof(require(script.Parent._RemoteObject.ObjectReplicator))
type ObjectReplicator = ObjectReplicator.ObjectReplicator

export type RemoteObject = typeof(RemoteObject.prototype:constructor()) & Package.Object
export type Class<O> = Package.Class<O> & {
    prototype: {
        client: O & {
            signal: { [string]: () -> () },
            state: { [string]: any },
            
            [string]: (self: O, player: Player,...any) -> ()
        },
    },
    client: {
        signal: { [string]: (...any) -> () },
        state: { [string]: any },
        
        [string]: (player: Player,...any) -> ()
    },
}

return RemoteObject