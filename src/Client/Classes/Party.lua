--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ServerObject = require(Packages.Client.ServerObject)

--// Class
local Party = Package.class("Party").extends(ServerObject)
:: Package.Class<Party>

--// Constructor
function Party.prototype:constructor(serverData, owner: Player, members: {Player})
    
    --// Instance
    ServerObject(self, serverData)
    
    self.Members = members
    self.Owner = owner
    
    --// Listeners
    self.MemberRemoved:Connect(self._memberRemoved, self)
    self.MemberAdded:Connect(self._memberAdded, self)
    return self
end

--// Listeners
function Party.prototype:_memberRemoved(member: Player)
    
    local index = table.find(self.Members, member)
    if index then table.remove(self.Members, index) end
end
function Party.prototype:_memberAdded(member: Player)
    
    table.insert(self.Members, member)
end

--// End
export type Party = typeof(Party.prototype:constructor()) & ServerObject.ServerObject

return Party.ready() :: typeof(Party)