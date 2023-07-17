--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local PlayersService = game:GetService("Players")

local Character = require(Packages.Client.Classes.Character)
type Character = Character.Character

local ServerObject = require(Packages.Client.ServerObject)
local newPromise = require(Packages.Core.Promise).new
local _expect = require(Packages.Core.Expectation).new

--// Class
local Player = Package.class("Player").extends(ServerObject)
:: Package.Class<Player>

--// Vars
local playersFromUserId = setmetatable({}, { __mode = "v" })
local playersFromName = setmetatable({}, { __mode = "v" })
local camera = workspace.CurrentCamera

--// Class Vars
local localPlayerPromise = newPromise()

--// Class Functions
function Player.getPlayerFromName(playerName: string): Player?
    
    _expect(playerName).is("string"):Argument(1, "playerName")
    
    return playersFromName[playerName]
end
function Player.getPlayerFromId(playerId: number): Player?
    
    _expect(playerId).is("number"):Argument(1, "playerId")
    
    return playersFromUserId[playerId]
end
function Player.getPlayer(player: Player): Player
    
    _expect(player).is("Player"):Argument(1, "player")
    
    return Player.getPlayerFromId(player.UserId)
end
function Player.awaitLocalPlayer(): Player

    return localPlayerPromise:Expect()
end

--// Class Behaviour
function Player:running()
    
    Player.awaitLocalPlayer():GetState("Character"):Updater(function(character)
    
        camera.CameraSubject = if character then character.Humanoid else nil
    end)
end

--// Constructor
function Player.prototype:constructor(serverData, rbxPlayer: rbxPlayer)
    
    --// Instance
    ServerObject(self, serverData)
    
    self.DisplayName = rbxPlayer.DisplayName
    self.UserId = rbxPlayer.UserId
    self.Name = rbxPlayer.Name
    
    self.RbxPlayer = rbxPlayer
    return self
end
function Player.prototype:postconstruct(serverData, rbxPlayer)
    
    playersFromUserId[self.UserId] = self
    playersFromName[self.Name] = self
    
    if rbxPlayer == PlayersService.LocalPlayer then
        
        localPlayerPromise:Resolve(self)
    end
end

--// Behaviour
function Player.prototype:components()
    
    return self.Name
end

--// End
type rbxPlayer = typeof(Instance.new("Player"))

export type Player = typeof(Player.prototype:constructor()) & ServerObject.ServerObject

return Player.ready() :: typeof(Player)