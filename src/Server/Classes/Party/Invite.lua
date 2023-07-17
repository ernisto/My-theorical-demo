--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, V...> = Package.Promise<F, V...>

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local newPromise = require(Packages.Core.Promise).new

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

--// Class
local PartyInvite = Package.class("PartyInvite").extends(RemoteObject)
:: RemoteObject.Class<PartyInvite> & {
    new: (party: Party, subject: Player) -> PartyInvite
}

--// Constructor
function PartyInvite.prototype:constructor(party: Party, subject: Player)
    
    _expect(party).is("Party"):Argument(1, "party")
    _expect(subject).is("Player"):Argument(2, "subject")
    
    local sender = party.Owner
    
    --// Instance
    RemoteObject(self)
    self.client.Subject = subject
    self.client.Sender = sender
    
    self.Response = newPromise():Timeout(30)
    self.Party = party
    
    self.Response
        :Catch("PromiseTimedOutException", function()
            
            self.TimedOut()
        end)
        :Then(function(accepted: boolean)
            
            if accepted then self.Accepted() else self.Rejected() end
            self:Destroy()
        end)
    
    --// Setup
    self.client:SetPlayers{ subject, sender }
    return self
end

--// Remote Signals
function PartyInvite.prototype.client.signal.Accepted() end
function PartyInvite.prototype.client.signal.Rejected() end
function PartyInvite.prototype.client.signal.TimedOut() end

--// Remote Methods
function PartyInvite.prototype.client:AcceptRemote(player)
    
    expect(player == self.Subject, "Permission denied")
    
    self.Response:Resolve(true)
end
function PartyInvite.prototype.client:RejectRemote(player)
    
    expect(player == self.Subject, "Permission denied")
    
    self.Response:Resolve(false)
end

--// Types
local Player: typeof(require(Packages.Server.Classes.Player))
type Player = Player.Player

local Party: typeof(require(Packages.Server.Classes.Party))
type Party = Party.Party

--// End
export type PartyInvite = typeof(PartyInvite.prototype:constructor()) & RemoteObject.RemoteObject & {
    Response: Promise<(accepted: boolean) -> (), boolean>
}

return PartyInvite