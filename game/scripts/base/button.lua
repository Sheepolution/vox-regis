local Mouse = require "base.mouse"
local Input = require "base.input"
local Circle = require "base.circle"
local Sprite = require "base.sprite"

local Button = Sprite:extend("Button")

Button.defaultShape = "rectangle"
Button.Tags = {}

function Button.enable(tag)
	if type(tag) == "table" then
		error("Don't use colon with Button.enable")
	end

	Button.Tags[tag] = true
end

function Button.disable(tag)
	if type(tag) == "table" then
		error("Don't use colon with Button.disable")
	end

	Button.Tags[tag] = false
end

function Button.neutralize(tag)
	if type(tag) == "table" then
		error("Don't use colon with Button.neutralize")
	end

	Button.Tags[tag] = nil
end

function Button.getEnabledStatus(tag)
	if type(tag) == "table" then
		error("Don't use colon with Button.getEnabledStatus")
	end

	return Button.Tags[tag]
end

function Button:new(x, y, shape, ...)
	Button.super.new(self, x, y, ...)
	self.radius = 0

	self.shape = shape or Button.defaultShape

	self.onRelease = false

	self.buttons = { 1 }
	self.keys = {}

	self.active = true

	self.hovering = false
	self.hold = false
	self.activated = false

	self.tags = { { tag = "main", priority = 0 } }
end

function Button:update(dt)
	Button.super.update(self, dt)

	if not self.active then
		Button.super.update(self, dt)
		return
	end

	if #self.tags > 1 then
		for __, v in ipairs(self.tags) do
			if Button.Tags[v.tag] ~= nil then
				if Button.Tags[v.tag] then
					break
				else
					return
				end
			end
		end
	else
		if Button.Tags["main"] == false then
			return
		end
	end

	self.activated = false
	local a = self.hovering

	if self:hovers(Mouse) then
		if self.hoverFunc then self.hoverFunc(self) end
		if self:isTriggerPressed() then
			self.hold = true
			if not self.onRelease then
				self.activated = true
				self.hold = false
			end
		end
	else
		if a then
			if self.offFunc then self.offFunc(self) end
		end
	end

	if self.image then
		if not self.anim:is("active") or self.anim.ended then
			if self.hovering and not self.hold then
				self.anim:set("hover")
			elseif self.hold then
				self.anim:set("hold")
			elseif not self.hovering and not self.hold then
				self.anim:set("idle")
			end
		end
	end

	if self.onRelease then
		if self:isTriggerReleased() then
			if self.hovering and self.hold then
				self.activated = true
				self.hold = false
			end
			self.hold = false
		end
	end

	if self.activated then
		if self.image then
			self.anim:set("active", true)
		end
		if self.func then self.func(self) end
	end
end

function Button:onPress(func)
	self.func = func
	return self
end

function Button:onHover(func)
	self.hoverFunc = func
	return self
end

function Button:onLeave(func)
	self.offFunc = func
	return self
end

function Button:hovers(p)
	if self.fakeScale then
		-- Sort of a hack really
		local x = self.x / self.fakeScale
		local y = self.y / self.fakeScale
		local w = self.width / self.fakeScale
		local h = self.height / self.fakeScale
		local px = p.x
		local py = p.y
		self.hovering = px >= x and px <= x + w and py >= y and py <= y + h
	elseif self.shape == "rectangle" then
		self.hovering = self:overlapsPointReal(p.x, p.y)
	else
		self.hovering = Circle.overlaps(self, p)
	end

	if self.hovering then
		Mouse:setCursor(Mouse.cursors.hand)
	end

	return self.hovering
end

function Button:setImage(...)
	Button.super.setImage(self, ...)

	if self.shape == "circle" then
		self:centerOffset()
		self.radius = self.width
		self.width = nil
		self.height = nil
	end

	local had_animation_already = self.anim.hasAnimation

	local a1, a2, a3

	a1 = #self._frames > 1 and 2 or 1
	a2 = #self._frames > 2 and 3 or a1
	a3 = #self._frames > 3 and 4 or a2

	if not self.anim:has("idle") then
		self.anim:add("idle", { 1 })
	end

	if not self.anim:has("hover") then
		if had_animation_already then
			self.anim:clone("idle", "hover")
		else
			self.anim:add("hover", { a1 })
		end
	end

	if not self.anim:has("hold") then
		if had_animation_already then
			self.anim:clone("hover", "hold")
		else
			self.anim:add("hold", { a2 })
		end
	end

	if not self.anim:has("active") then
		if had_animation_already then
			self.anim:clone("hold", "active")
		else
			self.anim:add("active", { a3, a3 }, "once", 12)
		end
	end

	self.anim:set("idle", true)

	return self
end

function Button:isTriggerPressed()
	return Mouse:isPressed(unpack(self.buttons)) or Input:isPressed(unpack(self.keys))
end

function Button:isTriggerReleased()
	return Mouse:isReleased(unpack(self.buttons)) or Input:isReleased(unpack(self.buttons))
end

function Button:set(...)
	if self.shape == "circle" then
		Circle.set(self, ...)
	else
		Button.super.set(self, ...)
	end
end

function Button:setScale(n)
	self.fakeScale = n
end

function Button:addTag(tag, priority)
	if _.find(self.tags, function(t)
			return t.tag == tag
		end) then
		return
	end

	if not priority then
		table.insert(self.tags, 1, { tag = tag, priority = self.tags[1].priority + 1 })
		return
	end

	for i, v in ipairs(self.tags) do
		if priority > v.priority then
			table.insert(self.tags, i, { tag = tag, priority = priority })
			return
		end
	end

	table.insert(self.tags, { tag = tag, priority = priority })
end

return Button
