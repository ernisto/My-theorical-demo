--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Signal<F> = Package.Signal<F>

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)
local Invite = require(script.Invite)
type PartyInvite = Invite.PartyInvite

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new
local isA = Package.IsA

--// Class
local Party = Package.class("Party").extends(RemoteObject)
:: RemoteObject.Class<Party>

--// Remote Signals
function Party.client.invited(invite: PartyInvite) end

--// Remote Functions
function Party.client.createPartyRemote(player): Party
    
    expect(player.Party == nil, "You already have in party")
    
    return Party.new(player)
end
function Party.client.leavePartyRemote(player)
    
    expect(player.Party, "You havent in party")
    
    player.Party:Remove(player)
end

--// Constructor
function Party.prototype:constructor(owner: Player)
    
    _expect(owner).is("Player"):Argument(1, "owner")
    
    --// Instance
    RemoteObject(self, owner)
    self.client.Members = {}
    
    self.Owner = owner
    
    self._memberDatas = {} :: { [Player]: Invite|Connection }
    return self
end
function Party.prototype:postconstruct(owner: Player)
    
    self:Add(owner)
end

--// Remote Signals
function Party.prototype.client.signal.MemberRemoved(member: Player) end
function Party.prototype.client.signal.MemberAdded(member: Player) end

--// Remote Methods
function Party.prototype.client:InviteRemote(player, subject: Player): Invite
    
    expect(player == self.Owner, "Permission denied")
    expect(isA(subject, "Object", "Player"), "Subject of type Player expected")
    expect(self._memberDatas[subject] == nil, "Subject already is a member or pending")
    
    return self:Invite(subject)
end
function Party.prototype.client:KickRemote(player, subject: Player)
    
    expect(player == self.Owner, "Permission denied")
    expect(isA(subject, "Object", "Player"), "Subject of type Player expected")
    expect(subject.Party == self, "Subject is not in this party")
    
    return self:Remove(subject)
end

--// Methods
function Party.prototype:Invite(subject: Player): Invite
    
    _expect(subject).is("Player"):Argument(1, "subject")
    
    local invite = Invite.new(self, subject)
    self._memberDatas[subject] = invite
    
    invite.Response:Finally(function(success, accepted)
        
        if success and accepted then
            
            if subject.Party then subject.Party:Remove(subject) end
            self:Add(subject)
        else
            
            self._memberDatas[subject] = nil
        end
    end)
    
    Party.invited:FireOnPlayers({ subject }, invite)
    return invite
end
function Party.prototype:Remove(subject: Player)
    
    _expect(subject).is("Player"):Argument(1, "subject")
    if subject.Party ~= self then return end
    
    subject:LeaveParty()
    
    self.MemberRemoved(subject)
    self._memberDatas[subject] = nil
    
    local index = table.find(self.Members, subject)
    if index then table.remove(self.Members, index) end
    
    if #self.Members == 0 then self:Destroy() end
end
function Party.prototype:Add(subject: Player)
    
    _expect(subject).is("Player"):Argument(1, "subject")
    expect(subject.Party == nil, "subject.Party must to be nil")
    
    local onLeave = subject.Destroyed:Connect(function()
        
        self:Remove(subject)
    end)
    
    table.insert(self.Members, subject)
    self._memberDatas[subject] = onLeave
    self.MemberAdded(subject)
    
    subject:JoinParty(self)
end

--// Behaviour
function Party.prototype:destroying()
    
    for _,data in self._memberDatas do
        
        data:Destroy()
    end
end

--// End
export type Party = typeof(Party.prototype:constructor()) & RemoteObject.RemoteObject & {
    MemberRemoved: Signal<(member: Player) -> ()>,
    MemberAdded: Signal<(member: Player) -> ()>,
}

return Party