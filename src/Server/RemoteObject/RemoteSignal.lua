--// Core
local Players = game:GetService("Players")
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local replicate = require(script.Parent.ClassReplicator)._replicate
local getPlayer: typeof(require(Packages.Server.Classes.Player).getPlayer)

local _expect = require(Packages.Core.Expectation).new
local Signal = require(Packages.Core.Signal)

task.defer(function()
    
    getPlayer = require(Packages.Server.Classes.Player).getPlayer
end)

--// Class
local RemoteSignal = Package.class("RemoteSignal").extends(Signal)
:: Package.Class<RemoteSignal>

--// Constructor
function RemoteSignal.prototype:constructor(path: string, replicationData: Replication)
    
    --// Instance
    Signal(self, path)
    
    self._replicationData = replicationData
    
    self.ClassName = replicationData.ClassName
    self.Players = replicationData.Players
    self.Token = replicationData.Token
    self.Index = replicationData.Name
end

--// Methods
function RemoteSignal.prototype:FireOffPlayers(blacklist: {Player},...: any)
    
    _expect(blacklist).all.value.is("Player"):Argument(1, "blacklist")
    
    local players = {}
    
    for _,player in self.Players or Players:GetPlayers() do
        
        if table.find(blacklist, getPlayer(player)) then continue end
        players[player.UserId] = player
    end
    
    Signal.__call(self,...)
    replicate({
        ClassName = self.ClassName,
        IsState = false,
        Players = players,
        Token = self.Token,
        Name = self.Index,
    }, nil,...)
end
function RemoteSignal.prototype:FireOnPlayers(whitelist: {Player},...: any)
    
    _expect(whitelist).all.value.is("Player"):Argument(1, "whitelist")
    
    local players = {}
    
    for _,player in self.Players or Players:GetPlayers() do
        
        if not table.find(whitelist, getPlayer(player)) then continue end
        players[player.UserId] = player
    end
    
    Signal.__call(self,...)
    replicate({
        ClassName = self.ClassName,
        IsState = false,
        Players = players,
        Token = self.Token,
        Name = self.Index,
    }, nil,...)
end

--// Behaviour
function RemoteSignal.prototype:__call(...: any)
    
    Signal.__call(self,...)
    replicate(self._replicationData, nil,...)
end

--// End
export type RemoteSignal<F> = typeof(RemoteSignal.prototype:constructor()) & Package.Signal<F>

return RemoteSignal