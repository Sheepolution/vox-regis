local Text = require "libs.text"
local Sprite = require "base.sprite"

local TextWriter = Sprite:extend()

local default_settings = {
    color = { 1, 1, 1, 1 },
}

function TextWriter:new(x, y, align, settings)
    TextWriter.super.new(self, x, y)
    self.text = Text.new(align or "left", settings or default_settings)
end

function TextWriter:update(dt)
    self.text:update(dt)
end

function TextWriter:draw()
    self.text:draw(self.x, self.y)
end

function TextWriter:getText()
    return self.text
end

function TextWriter:send(...)
    self.text:send(...)
end

return TextWriter
