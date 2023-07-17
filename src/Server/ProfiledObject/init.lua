--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ProfileService = require(script.ProfileService)
local RemoteObject = require(Packages.Server.RemoteObject)

local Expectation = require(Packages.Core.Expectation)
local expect = Expectation.assertMessage
local _expect = Expectation.new
local isA = Package.IsA

--// Class
local ProfiledObject = Package.class("ProfiledObject").implements(RemoteObject)
:: Package.Class<ProfiledObject> & {
    new: (profileKey: string) -> ProfiledObject
}

--// Constructor
function ProfiledObject.prototype:constructor(profileKey: string)
    
    profileKey = if profileKey then tostring(profileKey) else nil
    
    _expect(profileKey).is.some("string", "nil"):Argument(1, "profileKey")
    
    --// Instance
    self.Data = nil :: any?
    self.profile = setmetatable({}, {
        __newindex = function(states, index, defaultValue)
            
            expect(isA(self.client, "ObjectReplicator"), "You must to construct RemoteObject before ProfiledObject")
            self.client[index] = defaultValue
            
            local state = self.client[index]
            rawset(states, index, state)
        end
    })
    self._profilePromise = nil
    
    if profileKey then self:_activateProfileAsync(profileKey) end
    return self
end

--// Methods
function ProfiledObject.prototype.async:GetDataAsync(promise): table
    
    while not self.Data do task.wait(1/10) end
    return self.Data
end
function ProfiledObject.prototype:IsActive(): boolean
    
    local profilePromise = self._profilePromise
    if not profilePromise then return false end
    
    local isLoaded, profile = profilePromise:Get()
    if isLoaded then return profile:IsActive() end
    
    return false
end

--// Virtual Protected Methods
function ProfiledObject.prototype:_applyData(datas: any, fromProfile: boolean)
    
    if self.Data or (self._profilePromise and not fromProfile) then return end
    if typeof(datas) ~= "table" then datas = {} end
    
    for index, state in self.profile do
        
        local value = state.Value
        local data = datas[index]
        
        if isA(value, "ProfiledObject") then
            
            data = value:_applyData(data)
        else
            
            if data == nil then data = value end
            state:Set(data)
            
            state.Changed:Connect(function(newValue, lastValue)
                
                if isA(newValue, "Object") then return state:Set(lastValue) end
                datas[index] = newValue
            end)
        end
        
        datas[index] = data
    end
    
    self.Data = datas
    return datas
end

--// Override Protected Methods
function ProfiledObject.prototype:_awaitHaveReplicationAccess(userId: number)
    
    local released = false
    
    task.delay(5, function() if not released then warn(`infinity yield ({self}:_awaitHaveReplicationAccess)`) end end)
    while not self.Data do task.wait() end
    
    released = true
    return RemoteObject._awaitHaveReplicationAccess(self, userId)
end

--// Protected Methods
function ProfiledObject.prototype.async:_activateProfileAsync(promise, profileKey: string)
    
    self._profilePromise = promise
    
    local profile = self._profileStore:LoadProfileAsync(profileKey, "ForceLoad")
    self.Destroyed:Connect(profile.Release, profile)
    
    self:_applyData(profile.Data, true)
    return profile
end
function ProfiledObject.prototype.async:_previewProfileAsync(promise, profileKey: string)
    
    local profile = if self._profilePromise then self._profilePromise:Expect() else nil
    
    if profile and profile:IsActive() then
        
        profile:Release()
    else
        
        self._profileStore:ViewProfileAsync(profileKey)
    end
end

--// Behaviour
function ProfiledObject:extended(subClass)
    
    Package.extended(self, subClass)
    
    subClass.PROFILE_VERSION = subClass.PROFILE_VERSION or 1
    local profileName = subClass:GetType().." v"..subClass.PROFILE_VERSION
    
    subClass.prototype._profileStore = ProfileService.GetProfileStore(profileName, {})
end

--// End
export type ProfiledObject = typeof(ProfiledObject.prototype:constructor()) & Package.Object

return ProfiledObject