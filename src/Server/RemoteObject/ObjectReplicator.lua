--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local PlayersService = game:GetService("Players")

local ClassReplicator = require(script.Parent.ClassReplicator)
local playerSessionLoaded = ClassReplicator.PlayerSessionLoaded
local replicateState = ClassReplicator._replicateState
local replicate = ClassReplicator._replicate

local newRemoteSignal = require(script.Parent.RemoteSignal).new
local _expect = require(Packages.Core.Expectation).new

local VOID = Package.VOID

--// Class
local ObjectReplicator = Package.class("ObjectReplicator")
:: Package.Class<ObjectReplicator>

--// Constructor
function ObjectReplicator.prototype:constructor(className: string, object: Object, token: any, stateValues, signalPaths,...: any)
    
    _expect(object).is(className):Argument(1, "object")
    
    local states = object._states
    local players = {}
    
    --// Instance
    self.ReplicatesWhenRequestEnabled = true
    self.ClassName = className
    self.Players = players
    self.Token = token
    
    self._addEveryoneConnection = false
    self._filtredPlayers = {}
    self._addedPlayers = {}
    self._ready = false
    
    self._data = table.pack(...)
    self._states = states
    self._object = object
    
    --// Load States & Signals
    for signalName, signalPath in signalPaths do
        
        local signal = newRemoteSignal(signalPath, {
            ClassName = className,
            Players = players,
            Token = token,
            Name = signalName,
            IsState = false,
        })
        
        object[signalName] = signal
        object:Hoste(signal)
    end
    for stateName, stateValue in stateValues do
        
        object:GetState(stateName, if stateValue == VOID then nil else stateValue)
    end
    
    object:Hoste(self)
    return self
end

--// Signals
function ObjectReplicator.prototype.signal.PlayersRemoved(players: {Player}) end
function ObjectReplicator.prototype.signal.PlayersAdded(players: {Player}) end

--// Methods
function ObjectReplicator.prototype:RemoveFiltredPlayers(users: {integer|Player})
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    local filtredPlayers = self._filtredPlayers
    local addedPlayers = self._addedPlayers
    local players = self.Players
    
    local newPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        
        newPlayers[userId] = if players[userId] == nil then addedPlayers[userId] else nil
        players[userId] = addedPlayers[userId]
        filtredPlayers[userId] = nil
    end
    
    if not self._ready then return end
    
    self:_replicateConstruction(newPlayers)
    self.PlayersAdded(newPlayers)
end
function ObjectReplicator.prototype:AddFiltredPlayers(users: {integer|Player})
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    local filtredPlayers = self._filtredPlayers
    local players = self.Players
    
    local lastPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        
        lastPlayers[userId] = players[userId] or nil
        filtredPlayers[userId] = true
        players[userId] = nil
    end
    
    if not self._ready then return end
    
    self:_replicateDestruction(lastPlayers)
    self.RemovedPlayers(lastPlayers)
end
function ObjectReplicator.prototype:SetFiltredPlayers(users: {integer|Player}?)
    
    users = users or {}
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    --// Set Filter
    local filtredPlayers = self._filtredPlayers
    local addedPlayers = self._addedPlayers
    local players = self.Players
    
    local filtringPlayers = {}
    local lastPlayers = {}
    local newPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        
        lastPlayers[userId] = players[userId]
        filtringPlayers[userId] = true
        filtredPlayers[userId] = true
        players[userId] = nil
    end
    
    for userId in filtredPlayers do
        
        local isFiltring = filtringPlayers[userId]
        
        newPlayers[userId] = if not isFiltring and players[userId] == nil then addedPlayers[userId] else nil
        players[userId] = if not isFiltring then addedPlayers[userId] else nil
        filtredPlayers[userId] = isFiltring
    end
    
    if not self._ready then return end
    
    self:_replicateConstruction(newPlayers)
    self.PlayersAdded(newPlayers)
    
    self:_replicateDestruction(lastPlayers)
    self.PlayersRemoved(lastPlayers)
end

function ObjectReplicator.prototype:RemovePlayers(users: {integer|Player})
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    local addedPlayers = self._addedPlayers
    local players = self.Players
    
    local lastPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        
        lastPlayers[userId] = players[userId]
        addedPlayers[userId] = nil
        players[userId] = nil
    end
    
    if not self._ready then return end
    
    self:_replicateDestruction(lastPlayers)
    self.PlayersRemoved(lastPlayers)
end
function ObjectReplicator.prototype:AddPlayers(users: {integer|Player})
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    local filtredPlayers = self._filtredPlayers
    local addedPlayers = self._addedPlayers
    local players = self.Players
    
    local newPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        local player = PlayersService:GetPlayerByUserId(userId) or false
        local isFiltred = filtredPlayers[userId]
        
        newPlayers[userId] = if not isFiltred and players[userId] == nil then player else nil
        players[userId] = if not isFiltred then player else nil
        addedPlayers[userId] = player
    end
    
    if not self._ready then return end
    
    self:_replicateConstruction(newPlayers)
    self.PlayersAdded(newPlayers)
end
function ObjectReplicator.prototype:SetPlayers(users: {integer|Player}?)
    
    users = users or {}
    
    _expect(users).all.value.is.some("integer", "Player"):Argument(1, "userId")
    
    --// Disable Everyone Adder
    if self._addEveryoneConnection then
        
        self._addEveryoneConnection:Disconnect()
        self._addEveryoneConnection = false
    end
    
    --// Set Players
    local filtredPlayers = self._filtredPlayers
    local addedPlayers = self._addedPlayers
    local players = self.Players
    
    local addingPlayers = {}
    local lastPlayers = {}
    local newPlayers = {}
    
    for _,user in users do
        
        local userId = if type(user) == "number" then user else user.UserId
        local player = PlayersService:GetPlayerByUserId(userId) or false
        local hasFiltred = filtredPlayers[userId]
        
        newPlayers[userId] = if not hasFiltred and players[userId] == nil then player else nil
        players[userId] = if not hasFiltred then player else nil
        addingPlayers[userId] = player
        addedPlayers[userId] = player
    end
    
    for userId, player in addedPlayers do
        
        local isAdding = addingPlayers[userId]
        
        lastPlayers[userId] = if not isAdding and players[userId] ~= nil then player else nil
        players[userId] = if isAdding then player else nil
        addedPlayers[userId] = isAdding
    end
    
    if not self._ready then return end
    
    self:_replicateConstruction(newPlayers)
    self.PlayersAdded(newPlayers)
    
    self:_replicateDestruction(lastPlayers)
    self.PlayersRemoved(lastPlayers)
end

function ObjectReplicator.prototype:AddCurrentEveryone()
    
    self:AddPlayers(PlayersService:GetPlayers())
end
function ObjectReplicator.prototype:SetCurrentEveryone()
    
    self:SetPlayers(PlayersService:GetPlayers())
end
function ObjectReplicator.prototype:AddEveryone()
    
    if self._addEveryoneConnection then return end
    
    self._addEveryoneConnection = playerSessionLoaded:Connect(function(player)
        
        self:AddPlayers{ player }
        
        player.Destroying:Connect(function()
            
            self:RemovePlayers{ player }
        end)
    end)
    
    self:AddCurrentEveryone()
end

function ObjectReplicator.prototype:EnableReplicatesWhenRequest(isEnabled: boolean)
    
    _expect(isEnabled).is("boolean"):Argument(1, "isEnabled")
    
    self.ReplicatesWhenRequestEnabled = isEnabled
end
function ObjectReplicator.prototype:Ready()
    
    for name, state in self._states do
        
        state.Changed:Connect(replicateState, {
            ClassName = self.ClassName,
            Players = self.Players,
            Token = self.Token,
            Name = name,
            IsState = true,
        })
    end
    
    self._ready = true
    self:_replicateConstruction(self.Players)
end

--// Private Methods
function ObjectReplicator.prototype:_replicateConstruction(targetPlayers: {[integer]: Player|boolean})
    
    if next(targetPlayers) == nil then return end
    
    local replication = {
        ClassName = self.ClassName,
        Players = targetPlayers,
        Token = self.Token,
        IsState = true,
        Name = nil,
    }
    
    local states = {}
    
    for name, state in self._states do
        
        local value = state.Value
        
        states[name] = if value == nil then VOID else value
    end
    
    replicate(replication, states, unpack(self._data))
end
function ObjectReplicator.prototype:_replicateDestruction(targetPlayers: {[integer]: Player|boolean})
    
    if next(targetPlayers) == nil then return end
    
    replicate({
        ClassName = self.ClassName,
        Players = targetPlayers,
        Token = self.Token,
        IsState = false,
        Name = nil,
    })
end
function ObjectReplicator.prototype:_getState(stateName: string, defaultValue: any): State<any>
    
    _expect(stateName).is("string"):Argument(1, "stateName")
    
    local state = self._states[stateName]
    if state then return state end
    
    state = self._object:GetState(stateName, defaultValue)
    
    if self._ready then
        
        local replicatorConnection = state.Changed:Connect(replicateState, {
            ClassName = self.ClassName,
            Players = self.Players,
            Token = self.Token,
            Name = stateName,
            IsState = true,
        })
        
        if defaultValue ~= nil then replicatorConnection(defaultValue) end
    end
    
    return state
end

--// Behaviour
function ObjectReplicator.prototype:set(stateName: string, value: any)
    
    _expect(stateName).is("string"):Argument(1, "stateName")
    _expect(value).is.nt("function"):Argument(2, "value")
    
    self:_getState(stateName, value):Set(value)
end
function ObjectReplicator.prototype:get(stateName: string): State<any>
    
    _expect(stateName).is("string"):Argument(1, "stateName")
    
    return self:_getState(stateName)
end
function ObjectReplicator.prototype:destroying()
    
    if self._addEveryoneConnection then self._addEveryoneConnection:Destroy() end
    if self._ready then self:_replicateDestruction(self.Players) end
end
function ObjectReplicator.prototype:tostring()
    
    return "remote %s", self._object
end

--// End
export type ObjectReplicator = typeof(ObjectReplicator.prototype:constructor())

return ObjectReplicator