--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

type Promise<F, R...> = Package.Promise<F, R...>
type Signal<F> = Package.Signal<F>

--// Services
local PlayersService = game:GetService("Players")

--// Packages
local Character: typeof(require(Packages.Server.Classes.Character))
type Character = Character.Character

local ProfiledObject = require(Packages.Server.ProfiledObject)
local RemoteObject = require(Packages.Server.RemoteObject)

local tryPromise = require(Packages.Core.Promise).try
local format = require(Packages.Core.Format)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

task.defer(function()
    
    Character = require(Packages.Server.Classes.Character)
end)

--// Class
local Player = Package.class("Player").extends(RemoteObject, ProfiledObject)
:: RemoteObject.Class<Player> & {
    PlayerJoined: Signal<(player: Player) -> ()>,
    PlayerLeaved: Signal<(player: Player) -> ()>,
    PlayersCount: number,
    
    new: (rbxPlayer: rbxPlayer) -> Player,
}

--// Consts
local RESPAWN_TIME = 5

--// Vars
local playersFromUserId = {}
local playersFromName = {}

--// Remote States
Player.client.state.PlayersCount = 0

--// Remote Signals
function Player.client.signal.PlayerJoined(player: Player) end
function Player.client.signal.PlayerLeaved(player: Player) end

--// Class Functions
function Player.getPlayerFromName(playerName: string): Player?
    
    _expect(playerName).is("string"):Argument(1, "playerName")
    
    return playersFromName[playerName]
end
function Player.getPlayerFromId(playerId: number): Player?
    
    _expect(playerId).is("number"):Argument(1, "playerId")
    
    return playersFromUserId[playerId]
end
function Player.getPlayer(player: Player|rbxPlayer): Player
    
    _expect(player).is("Player"):Argument(1, "player")
    
    return Player.getPlayerFromId(player.UserId)
end

function Player.removePlayer(rbxPlayer)
    
    local player = Player.getPlayer(rbxPlayer)
    if not player then return end
    
    Player:_decreaseState("PlayersCount", 1)
    Player.PlayerLeaved(player)
    
    player:Destroy()
end
function Player.addPlayer(rbxPlayer)
    
    local player = Player.new(rbxPlayer)
    player:GetDataAsync():Await()
    
    Player:_increaseState("PlayersCount", 1)
    Player.PlayerJoined(player)
    
    Package.async(function()
        
        while rbxPlayer.Parent do
            
            local character = player:Spawn()
            character.Destroyed:Await()
            
            task.wait(RESPAWN_TIME)
        end
    end)
end

function Player.getPlayers(): {Player}
    
    local players = {}
    for _,player in playersFromName do table.insert(players, player) end
    
    return players
end

--// Behaviour
function Player:start()
    
    for _,player in PlayersService:GetPlayers() do
        
        Player.addPlayer(player)
    end
    
    PlayersService.PlayerRemoving:Connect(Player.removePlayer)
    PlayersService.PlayerAdded:Connect(Player.addPlayer)
    
    game:BindToClose(function()
        
        for _,player in playersFromName do
            
            Player.removePlayer(player)
        end
    end)
end

--// Constructor
function Player.prototype:constructor(rbxPlayer: rbxPlayer)
    
    _expect(rbxPlayer).is("Player"):Argument(1, "rbxPlayer")
    
    --// Instance
    RemoteObject(self, rbxPlayer)
    ProfiledObject(self, rbxPlayer.UserId)
    
    self.profile.Keybinds = {
        Pickup = "E",
        Drop = "Q",
        
        Attack = "MouseButton1",
        Skill1 = "E",
        Skill2 = "R",
        Skill3 = "V",
        Skill4 = "C",
    }
    
    self.client.UsingSkill = nil    :: Skill?
    self.client.Character = nil     :: Character?
    self.client.Party = nil         :: Party?
    
    self.DisplayName = rbxPlayer.DisplayName
    self.UserId = rbxPlayer.UserId
    self.Name = rbxPlayer.Name
    
    self.HumanoidDescriptionPromise = tryPromise(PlayersService.GetHumanoidDescriptionFromUserId, PlayersService, self.UserId):Retry(-1) :: Promise<(humanoidDescription: HumanoidDescription) -> (), HumanoidDescription>
    self.RbxPlayer = rbxPlayer
    return self
end
function Player.prototype:postconstruct(rbxPlayer)
    
    self:GetState("Character"):Updater(self._updateRbxPlayer, self)
    
    --// Log
    playersFromUserId[self.UserId] = self
    playersFromName[self.Name] = self
end

--// Remote Signals
function Player.prototype.client.signal.CharacterSpawning(character: Character) end
function Player.prototype.client.signal.CharacterSpawned(character: Character) end
function Player.prototype.client.signal.CharacterDied(character: Character) end

--// Remote Methods
function Player.prototype.client:RespawnRemote(player): Character
    
    expect(player == self, "Permission denied")
    
    return self:Spawn()
end

--// Methods
function Player.prototype:SetUsingSkill(usingSkill: Skill?)
    
    _expect(usingSkill).is.some("Skill", "nil"):Argument(1, "usingSkill")
    
    if self.UsingSkill then self.UsingSkill:Release() end
    self:_setState("UsingSkill", usingSkill)
end

function Player.prototype:JoinParty(party: Party)
    
    if self.Party then self:LeaveParty() end
    
    party.client:AddPlayers{ self }
    self:_setState("Party", party)
end
function Player.prototype:LeaveParty()
    
    local party = self.Party
    if not party then return end
    
    party.client:RemovePlayers{ self }
    self:_setState("Party", nil)
end

function Player.prototype:Spawn(rigInfo: rigInfo?): Character
    
    rigInfo = rigInfo or {}
    
    _expect(rigInfo).all.index.equals.some("Model", "HumanoidDescription"):Argument(1, "rigInfo")
    
    --// Kill Character
    if self.Character then self.Character:Destroy() end
    
    --// Create Character
    local character = Character.new(rigInfo, self)
    
    character.Destroyed:Connect(self._setState, self, "Character", nil)
    self:_setState("Character", character)
    
    character.Destroyed:Connect(self.CharacterDied)
    character.Loaded:Connect(self.CharacterSpawned, character)
    self.CharacterSpawning(character)
    
    self.HumanoidDescriptionPromise:Then(character.ApplyDescriptionAsync, character)
    
    --// End
    return character
end
function Player.prototype:Kick(message: any,...: any): ()
    
    _expect(message).is("string"):Argument(1, message)
    
    self.RbxPlayer:Kick(format(tostring(message),...))
end

--// Behaviour
function Player.prototype:destroying()
    
    if self.Character then self.Character:Destroy() end
    
    playersFromUserId[self.UserId] = nil
    playersFromName[self.Name] = nil
    
    Player:_decreaseState("PlayersCount", 1)
    Player.PlayerLeaved(self)
end

--// Updaters
function Player.prototype:_updateRbxPlayer(character: Character?)
    
    if character then
        
        self.RbxPlayer.ReplicationFocus = character.Model
        self.RbxPlayer.Character = character.Model
    else
        
        self.RbxPlayer.Character = nil
    end
end

--// End
local Skill: typeof(require(Packages.Server.Classes.Skill))
type SkillExecution = Skill.SkillExecution

local Party: typeof(require(Packages.Server.Classes.Party))
type Party = Party.Party

type rbxPlayer = typeof(Instance.new("Player"))
type rigInfo = {
    HumanoidDescription: HumanoidDescription?,
    Model: Model?,
}

export type Player = typeof(Player.prototype:constructor()) & RemoteObject.RemoteObject

return Player