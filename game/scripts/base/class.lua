local Object = require "libs.classic"

local id = 0

local Class = Object:extend()

function Class:new()
    self.__id = id
    id = id + 1
end

function Class:build()
end

function Class:finalize()
end

function Class:setProperties(properties)
    for k, v in pairs(properties) do
        self[k] = v
    end
    return self
end

function Class:getMetatable()
    return getmetatable(self)
end

function Class:getClassName()
    return tostring(self)
end

function Class:getInstanceID()
    return self.__id
end

function Class:destroy()
    self.destroyed = true
end

function Class:__call(...)
    local obj = setmetatable({}, self)

    obj:new(...)
    obj:build()

    return obj
end

return Class
