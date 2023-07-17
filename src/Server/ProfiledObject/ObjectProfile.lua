--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local _expect = require(Packages.Core.Expectation).new

--// Class
local ObjectProfile = Package.class("ObjectProfile")
:: Package.Class<ObjectProfile> & {
    new: (object: ProfiledObject) -> ObjectProfile
}

--// Constructor
function ObjectProfile.prototype:constructor(object: ProfiledObject)    --! FINISH ON FUTURE
    
    return self
end

--// Methods
function ObjectProfile.prototype.async:ActivateProfileAsync(promise, profileKey: string)
    
    self._profilePromise = promise
    
    local profile = self._profileStore:LoadProfileAsync(profileKey, "ForceLoad")
    self.Destroyed:Connect(profile.Release, profile)
    
    self:_applyData(profile.Data, true)
    return profile
end
function ObjectProfile.prototype.async:PreviewProfileAsync(promise, profileKey: string)
    
    local profile = if self._profilePromise then self._profilePromise:Expect() else nil
    
    if profile and profile:IsActive() then
        
        profile:Release()
    else
        
        self._profileStore:ViewProfileAsync(profileKey)
    end
end

--// Behaviour
function ObjectProfile.prototype:set(index: string, defaultValue: any)
    
    self._replicator[index] = defaultValue
    
    local state = self.client[index]
    self[index] = state
end

--// End
export type ObjectProfile = typeof(ObjectProfile.prototype:constructor()) & Package.Object

return ObjectProfile