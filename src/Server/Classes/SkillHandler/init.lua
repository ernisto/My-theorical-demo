--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local RemoteObject = require(Packages.Server.RemoteObject)

local Player = require(Packages.Server.Classes.Player)
local tryPromise = require(Packages.Core.Promise).try

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new

local Skill = require(script.Skill)
type Skill = Skill.Skill

--// Class
local SkillHandler = Package.class("SkillHandler").extends(RemoteObject)
:: RemoteObject.Class<SkillHandler> & {
    new: (name: string) -> SkillHandler
}

--// Constructor
function SkillHandler.prototype:constructor(name: string, handler: (skill: Skill, any...) -> any...)
    
    _expect(name).is("string"):Argument(1, "name")
    _expect(handler).is("function"):Argument(2, "handler")
    
    --// Instance
    RemoteObject(self, name)
    self.IsEnabled = false
    self.Name = name
    
    self._cooldownsFinishes = setmetatable({}, { __mode = "k" })
    self._activators = setmetatable({}, { __mode = "v" })
    self._handler = handler
    
    self.client.PlayersAdded:Connect(function(players)
        
        local enabledPlayers = {}
        
        for _,player in players do
            
            player = Player.getPlayer(player)
            if table.find(self._activators, player) then table.insert(enabledPlayers, player) end
        end
        
        self.Enabled.FireOnPlayers(self.Enabled, enabledPlayers)
    end)
    
    return self
end

--// Remote Signals
function SkillHandler.prototype.client.signal.Disabled() end
function SkillHandler.prototype.client.signal.Enabled() end

--// Remote Methods
function SkillHandler.prototype.client:HoldRemote(player,...: any): (Skill, any...)
    
    expect(self._everyoneAllowed or table.find(self._activators, player), `Permission denied for skill {self.Name}`)
    -- expect(not player.UsingSkill, "You already using a skill")
    
    local timeleft = os.clock() - (self._cooldownsFinishes[player] or 0)
    _expect(timeleft >= 0):Throws("SkillInCooldown", timeleft)
    
    local skill = Skill.new(self._handler, player,...)
    local skillDataGiver = tryPromise(skill.Approved.Await, skill.Approved)
    
    skill._promise:Finally(function(success: boolean)
        
        self._cooldownsFinishes[player] = os.clock() + skill.StageCooldowns[1]
        player:SetUsingSkill(nil)
        
        if not success then skillDataGiver:Cancel() end
    end)
    
    player:SetUsingSkill(skill)
    return skill, skillDataGiver:Expect()
end

--// Methods
function SkillHandler.prototype:SetActivators(activators: {Player}?)
    
    if activators ~= nil then _expect(activators).all.value.is("Player"):Argument(1, "activators") end
    
    self.Disabled:FireOnPlayers(self._activators)
    table.clear(self._activators)
    
    if activators then
        
        self:AddActivators(activators)
    else
        
        self:AddActivators(Player.getPlayers())
    end
end
function SkillHandler.prototype:AddActivators(activators: {Player})
    
    _expect(activators).all.value.is("Player"):Argument(1, "activators")
    
    for _,activator in activators do table.insert(self._activators, activator) end
    self.Enabled:FireOnPlayers(activators)
end

--// End
export type SkillHandler = typeof(SkillHandler.prototype:constructor()) & Package.Object

return SkillHandler