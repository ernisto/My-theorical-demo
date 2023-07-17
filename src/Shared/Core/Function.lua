--// Core
local Package = require(game:GetService("ReplicatedStorage").Package)
local Packages = Package.Packages

--// Packages
local _expect = require(Packages.Core.Expectation).new
local isA = Package.IsA

--// Class
local Function = Package.class("Function")

--// Config
local PARALLEL_SAFING = false   --# true: +cpu usage, false: =parallel unsafe
local MEMORY_ECO = false --# true: +cpu usage, false: +memory usage

--// Constructor
function Function.prototype:constructor(func: (...any) -> ...any,...: any)
    
    local argumentsCount = select("#",...)
    local path, line, name
    local begin = 1
    
    if isA(func, "Function") then
        
        table.move(func, 1, func._begin, 1, self)
        begin = func._begin
        
        path, line, name = func.Path, func.Line, func.Name
    else
        
        _expect(func).is("function"):Argument(1, "func")
        
        path, line, name = debug.info(func, "sln")
        if name == "" then name = nil end
    end
    
    --// Instance
    table.move({...}, 1, argumentsCount, begin, self)
    begin += argumentsCount
    
    self.Path = path
    self.Line = line
    self.Name = name
    
    self._begin = begin
    self._task = func
    
    --// Optimizations
    if MEMORY_ECO then
        
        self.call = if argumentsCount == 0 then self._call0
                elseif argumentsCount == 1 then self._call1
                elseif argumentsCount == 2 then self._call2
                elseif argumentsCount == 3 then self._call3
                elseif argumentsCount == 4 then self._call4
                else self.call
    else
        
        if argumentsCount == 0 then
            
            function self:call(...)
                
                return func(...)
            end
            
        elseif argumentsCount == 1 then
            
            local v1 = self[1]
            
            function self:call(...)
                
                return func(v1,...)
            end
            
        elseif argumentsCount == 2 then
            
            local v1, v2 = unpack(self, 1, 2)
            
            function self:call(...)
                
                return func(v1, v2,...)
            end
            
        elseif argumentsCount == 3 then
            
            local v1, v2, v3 = unpack(self, 1, 3)
            
            function self:call(...)
                
                return func(v1, v2, v3,...)
            end
            
        elseif argumentsCount == 4 then
            
            local v1, v2, v3, v4 = unpack(self, 1, 4)
            
            function self:call(...)
                
                return func(v1, v2, v3, v4,...)
            end
        else
            
            function self:call(...)
                
                return func(
                    unpack(
                        table.move(
                            {...},
                            1,
                            select("#",...),
                            begin,
                            if PARALLEL_SAFING then {unpack(self, 1, begin)} else self
                        )
                    )
                )
            end
        end
    end
end

--// Behaviour
function Function.prototype:components()
    
    return self.Name or (self.Path..":"..self.Line) or "unnamed"
end
function Function.prototype:tostring(path, name)
    
    return "Function(%s %s [%*s])", path, name, self
end

function Function.prototype:__call(...)
    
    return self:call(...)
end
function Function.prototype:call(...: any)
    
    return self._task(
        unpack(
            table.move(
                {...},
                1,
                select("#",...),
                self._begin,
                if PARALLEL_SAFING then {unpack(self)} else self
            )
        )
    )
end
function Function.prototype:_call0(...: any)
    
    return self._task(...)
end
function Function.prototype:_call1(...: any)
    
    return self._task(self[1],...)
end
function Function.prototype:_call2(...: any)
    
    return self._task(self[1], self[2],...)
end
function Function.prototype:_call3(...: any)
    
    return self._task(self[1], self[2], self[3],...)
end
function Function.prototype:_call4(...: any)
    
    return self._task(self[1], self[2], self[3], self[4],...)
end

--// End
return Function