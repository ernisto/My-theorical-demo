--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local ProfiledObject = require(Packages.Server.ProfiledObject)
local RemoteObject = require(Packages.Server.RemoteObject)
local _expect = require(Packages.Core.Expectation).new

local NULL = Package.NULL

--// Class
local ProfiledStruct = Package.class("ProfiledStruct").extends(RemoteObject, ProfiledObject)
:: Package.Class<ProfiledStruct> & {
    new: (struct: {[string]: any}) -> ProfiledStruct
}

--// Constructor
function ProfiledStruct.prototype:constructor(struct: {[string]: any})
    
    _expect(struct).all.index.is("string"):Argument(1, "struct")
    
    --// Instance
    ProfiledObject(self)
    
    for index, value in struct do
        
        self.profile[index] = if value == NULL then nil else value
    end
    
    --// End
    return self
end

--// End
export type ProfiledStruct = typeof(ProfiledStruct.prototype:constructor()) & Package.Object

return ProfiledStruct