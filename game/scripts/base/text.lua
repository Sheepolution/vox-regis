local _ = require "base.utils"
local Asset = require "base.asset"
local Rect = require "base.rect"
local Sprite = require "base.sprite"

local Text = Sprite:extend("Text")

Text.defaultFont = CONFIG.defaultFont
Text.defaultFontSize = CONFIG.defaultFontSize

for k, v in pairs(string) do
	Text[k] = function(self, ...)
		return string[k](self:read(), ...)
	end
end

function Text:new(x, y, text, font, size, force)
	Text.super.new(self, x, y)
	self.shadow = Rect(0, 0)
	self.shadow.alpha = 1
	self.shadow:setColor(0, 0, 0)

	self.border = Rect(0, 0)
	self.border.alpha = 1
	self.border:setColor(0, 0, 0)

	self.visible = true
	---------------
	self:write(text or "")
	self.align = { x = "left", y = "top" }
	self.limit = 999999

	if type(font) == "number" then
		size = font
		font = Text.defaultFont
	elseif not font then
		font = Text.defaultFont
	end

	if type(font) == "string" then
		self.font = Asset.font(font, (size or Text.defaultFontSize), force)
	else
		self.font = font
	end

	self.font:setFilter(CONFIG.defaultGraphicsFilter, CONFIG.defaultGraphicsFilter)

	self.size = size or Text.defaultFontSize
end

function Text:drawImage()
	love.graphics.setFont(self.font)
	local factor = 1

	if self.shadow.x ~= 0 or self.shadow.y ~= 0 then
		if self.shadow._hasColor then
			love.graphics.setColor(self.shadow._color[1], self.shadow._color[2], self.shadow._color[3], self.shadow
				.alpha * self.alpha)
		end

		love.graphics.push()
		love.graphics.translate((self.shadow.x) * factor, (self.shadow.y) * factor)
		self:print()
		if self.shadow._hasColor then
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.pop()
	end

	if self.border.x ~= 0 or self.border.y ~= 0 then
		love.graphics.setColor(self.border._color[1], self.border._color[2], self.border._color[3],
			self.border.alpha * self.alpha)
		for i = -self.border.x, self.border.x do
			for j = -self.border.y, self.border.y do
				love.graphics.translate((i) * factor, (j) * factor)
				self:print()
				love.graphics.translate(-i * factor, -j * factor)
			end
		end
	end

	love.graphics.setColor(self._color[1], self._color[2], self._color[3], self.alpha)
	self:print()
end

function Text:print()
	love.graphics.push()

	if self.clean then
		love.graphics.origin()
	end

	if self.align.y ~= "top" then
		local height = self:getFullHeight()
		height = height - (((self:getLineHeight() - 1) * self:getFontHeight()))
		if self.align.y == "center" then
			love.graphics.translate(0, -height / 2)
		elseif self.align.y == "bottom" then
			love.graphics.translate(0, -height)
		else
			error("Invalid vertical alignment!")
		end
	end

	local x = 0

	if self.align.x == "center" then
		x = -self.limit / 2
	elseif self.align.x == "right" then
		x = -self.limit
	end

	love.graphics.printf(self.content, (self.x + self.offset.x + self.origin.x + x),
		(self.y + self.offset.y + self.origin.y), self.limit, self.align.x,
		self.angle, self.scale.x, self.scale.y,
		self.origin.x, self.origin.y, self.shear.x, self.shear.y)
	love.graphics.pop()
end

function Text:write(text, color)
	if type(text) == "table" then
		self.content = text
	else
		self.content = { color and { unpack(color) } or { 1, 1, 1 }, text .. "" }
	end
end

function Text:append(text, color)
	table.insert(self.content, color and color or { 1, 1, 1 })
	table.insert(self.content, text .. "")
	return self.content
end

function Text:read()
	local str = ""
	for i, v in ipairs(self.content) do
		if type(v) == "string" then
			str = str .. v
		end
	end
	return str
end

function Text:setAlpha(alpha)
	self.alpha = alpha
	for i, v in ipairs(self.content) do
		if type(v) == "table" then
			v[4] = self.alpha
		end
	end
end

function Text:setAlign(align, limit)
	self.align.x = align
	self.limit = limit or self.limit
end

function Text:readReal()
	return self.content
end

function Text:centerY(y)
	local height = self:getFullHeight() / 2
	if y then
		self.y = y - height
	end

	return self.y + height
end

function Text:bottom(y)
	local height = self:getFullHeight()
	if y then
		self.y = y - height
	end

	return self.y + height
end

function Text:getFont()
	return self.font
end

function Text:getHeight()
	return self:getFontHeight() * self:getLineHeight()
end

function Text:getFontHeight()
	return self.font:getHeight()
end

function Text:getLineHeight()
	return self.font:getLineHeight()
end

function Text:getLength(s)
	return self.font:getWidth(s or self:read())
end

function Text:getWrap(s)
	local width, lines = self.font:getWrap(s or self.content, self.limit)
	return width, lines
end

function Text:getFullHeight(s)
	local width, lines = self:getWrap(s)
	return self:getHeight() * #lines
end

function Text:getWidth(s)
	return (self:getWrap(s))
end

function Text:centerOrigin()
	self.origin:set(
		self.align.x == "center" and self.limit / 2 or self.align.x == "right" and self.limit or 0,
		self.font:getHeight() / 2
	)
end

function Text:setFont(font, size, force, hinting)
	if type(font) == "string" then
		self.font = Asset.font(font, (size or 12), force, hinting)
	else
		self.font = font
	end
end

function Text:setFilter(filter)
	self.font:setFilter(filter, filter)
end

return Text
