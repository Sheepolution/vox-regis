local Rect = require "base.rect"
local Point = require "base.point"
local Circle = Point:extend("Circle")

Circle:implement(Rect)

function Circle:new(x, y, radius)
	Circle.super.new(self, x, y)
	self.radius = radius or 0
	self.thickness = 2
	self.lineStyle = "smooth"
	self._color = { 255, 255, 255 }
	self.alpha = 1
	self.visible = true
end

function Circle:draw(mode, segments)
	mode = mode or self.mode or "fill"

	if mode == "line" then
		love.graphics.setLineWidth(self.thickness)
		love.graphics.setLineStyle(self.lineStyle)
	end

	if self.blend then
		love.graphics.setBlendMode(self.blend, self.blendAlpha)
	end

	if self._hasColor or self.alpha < 1 then
		love.graphics.setColor(self._color[1], self._color[2], self._color[3], self.alpha)
	end

	love.graphics.circle(mode, self.x, self.y, self.radius, self.segments or segments)

	if self._hasColor or self.alpha < 1 then
		love.graphics.setColor(1, 1, 1, 1)
	end

	if mode == "line" then
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(1)
	end

	if self.blend then
		love.graphics.setBlendMode("alpha")
	end
end

function Circle:set(x, y, radius)
	Circle.super.new(self, x, y)
	self.radius = radius or self.radius
end

function Circle:get()
	return self.x, self.y, self.radius
end

function Circle:clone(c)
	Circle.super.clone(self, c)
	if c:is(Circle) then
		self.radius = c.radius
	elseif c:is(Rect) then
		self.radius = math.max(c.width, c.height)
	end
end

function Circle:overlaps(c)
	return math.sqrt((self.x - c.x) ^ 2 + (self.y - c.y) ^ 2) < self.radius + (c.radius or 0)
end

function Circle:overlapsX(c)
	if c:is(Circle) then
		return self.x - self.radius / 2 < c.x + c.radius / 2
			and self.x + self.radius / 2 > c.x - c.radius / 2
	else
		return self.x - self.radius / 2 < c.x + (c.width or 0)
			and self.x + self.radius / 2 > c.x
	end
end

function Circle:overlapsY(c)
	if c:is(Circle) then
		return self.y - self.radius / 2 < c.y + c.radius / 2
			and self.y + self.radius / 2 > c.y - c.radius / 2
	else
		return self.y - self.radius / 2 < c.y + (c.width or 0)
			and self.y + self.radius / 2 > c.y
	end
end

function Circle:overlapsPointReal(px, py)
	local x, y = self:getRealX(), self:getRealY()
	return math.sqrt((x - px) ^ 2 + (y - py) ^ 2) < self.radius
end

function Circle:overlapsMouse()
	if Mouse:isClaimed() then return false end
	return self:overlapsPointReal(Mouse.x, Mouse.y)
end

function Circle:left(val)
	if val then self.x = val + self.radius / 2 end
	return self.x - self.radius / 2
end

function Circle:right(val)
	if val then self.x = val - self.radius / 2 end
	return self.x + self.radius / 2
end

function Circle:top(val)
	if val then self.y = val + self.radius / 2 end
	return self.y - self.radius / 2
end

function Circle:bottom(val)
	if val then self.y = val - self.radius / 2 end
	return self.y + self.radius / 2
end

function Circle:centerX(val)
	if val then self.x = val end
	return self.x
end

function Circle:centerY(val)
	if val then self.y = val end
	return self.y
end

function Circle:center(x, y)
	if x then self.x = x end
	if y then self.y = y end
	return self.x, self.y
end

function Circle:setBlend(blend)
	self.blend = blend

	if ("multiply_lighten_darken"):find(blend) then
		self.blendAlpha = "premultiplied"
	else
		self.blendAlpha = "alphamultiply"
	end
end

return Circle
