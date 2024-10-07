local _ = require "base.utils"
local HC = require "libs.HC"
local SpatialHash = require "base.components.spatial_hash"
local Sprite = require "base.sprite"
local Input = require "base.input"
local World = require "base.map.world"
local Camera = require "base.camera"
local Rect = require "base.rect"

local Scene = Sprite:extend("Scene")

Scene:implement(SpatialHash)

function Scene:new(x, y, width, height)
	self.canvas = love.graphics.newCanvas(width or GAME_WIDTH, height or GAME_HEIGHT)
	self.canvas:setFilter(CONFIG.defaultGraphicsFilter, CONFIG.defaultGraphicsFilter)

	Scene.super.new(self, x, y, self.canvas)

	self.entities = list()
	self.overlay = list()
	self.underlay = list()
	self.particles = list()
	self.everything = list({ self.entities, self.particles, self.overlay, self.underlay })

	self.backgroundColor = { 0, 0, 0 }
	self.backgroundAlpha = 0

	self.camera = Camera(0, 0, width or GAME_WIDTH, height or GAME_HEIGHT)
	self.camera:setWindow(0, 0, width or GAME_WIDTH, height or GAME_HEIGHT)

	self.fadeRect = Rect(0, 0, self.width, self.height)
	self.fadeRect:setColor(0, 0, 0)
	self.fadeRect.alpha = 0

	self.showEffects = true
	self.useStencil = false

	if CONFIG.useSpatialHash then
		self:addSpatialHash()
	end
end

function Scene:update(dt)
	if self.showScene then
		self.showScene:update(dt)
		return
	end

	self:removeEverythingDestroyed()

	self:updateEntities(dt)

	if self.hasSpatialHash then
		self:handleOverlap(self)
	end

	for i, v in ipairs(self.underlay) do
		if v.update then
			v:update(dt)
		end
	end

	for i, v in ipairs(self.overlay) do
		if v.update then
			v:update(dt)
		end
	end

	Scene.super.update(self, dt)

	if self.camera then
		self:updateCamera(dt)
	end

	if self.map then
		self.map:update(dt)
	end

	if self.music then
		self.music:update(dt)
	end

	if DEBUG_INFO then
		DEBUG_INFO:addInfo(self.__name:sub(1, 10) .. " E", #self.entities)
		DEBUG_INFO:addInfo(self.__name:sub(1, 10) .. " O", #self.overlay)
	end
end

function Scene:updateEntities(dt)
	local everything_sorted_to_update = self:getEverythingSorted("updatePriority")
	for i, v in ipairs(everything_sorted_to_update) do
		if v.update and not v.destroyed then
			v:update(dt)
		end
	end
end

function Scene:updateCamera(dt)
	self.camera:update(dt)
end

function Scene:draw()
	if self.showScene then
		if (self.effects or self.shader) and self.showEffects then
			if self.effects then
				self.effects(function()
					self.showScene:draw()
				end)
			else
				love.graphics.setShader(self._shaders[self.shader].shader)
				self.showScene:draw()
				love.graphics.setShader()
			end
		else
			self.showScene:draw()
		end
		return
	end

	if not self.visible then
		return
	end

	love.graphics.push("all")
	if self.canvas then
		love.graphics.origin()
		love.graphics.setCanvas({ self.canvas, stencil = self.useStencil })
		love.graphics.clear(self.backgroundColor[1], self.backgroundColor[2], self.backgroundColor[3],
			self.backgroundAlpha)
	end

	self:drawInCanvas()

	love.graphics.pop()

	if self.canvas then
		if self.effects and self.showEffects then
			self.effects(function()
				self:drawCanvas()
			end)
		else
			self:drawCanvas()
		end
	end

	self:drawOutsideCanvas()
	self.fadeRect:draw()
end

function Scene:drawInCanvas()
	self:drawOutsideCamera()

	if self.camera then
		if self.showEffects and self.effectsCamera then
			self.effectsCamera(function()
				self.camera:draw(function()
					self:drawInCamera()
				end)
			end)
		else
			self.camera:draw(function()
				self:drawInCamera()
			end)
		end
	else
		-- ???
	end

	love.graphics.setScissor()

	self:drawOverlay()
end

function Scene:drawCanvas()
	Scene.super.draw(self)
end

function Scene:drawOverlay()
	local overlay_copy = table.shallow_copy(self.overlay)

	table.sort(overlay_copy, function(a, b)
		local za, zb = a["z"] or 0, b["z"] or 0
		if za == zb then
			return a.__id < b.__id
		end
		return za > zb
	end)

	for i, v in ipairs(overlay_copy) do
		v:draw()
	end
end

function Scene:drawOutsideCanvas()
end

function Scene:drawOutsideCamera()
	if self.backgroundSprite then
		self.backgroundSprite:draw()
	elseif self.backgroundImage then
		love.graphics.draw(self.backgroundImage, 0, 0)
	end

	for i, v in _.ripairs(_.sort(self.underlay, "z")) do
		v:draw()
	end
end

function Scene:drawInCamera()
	for i, v in ipairs(self:getEverythingSorted("z")) do
		if v.draw then
			v:draw()
		end
	end

	if DEBUG then
		if Input:isDown("tab") then
			if self.hasSpatialHash then
				self:drawSpatialHash(self)
			end
			self.entities:drawDebug()
		end
	end
end

function Scene:setBackgroundColor(r, g, b, a)
	if type(r) == "table" then
		self.backgroundColor = { r[1] or self.backgroundColor[1], r[2] or self.backgroundColor[2],
			r[3] or self.backgroundColor[3] }
		if g then
			self.backgroundAlpha = g
		elseif r[4] then
			self.backgroundAlpha = a
		end
	else
		if r then self.backgroundColor[1] = r end
		if g then self.backgroundColor[2] = g end
		if b then self.backgroundColor[3] = b end
		if a then
			self.backgroundAlpha = a
		end
	end
end

function Scene:setBackgroundAlpha(a)
	self.backgroundAlpha = a
end

function Scene:setBackgroundImage(path)
	self.backgroundImage = Asset.image(path)
	if self.backgroundAlpha == 0 then
		self.backgroundAlpha = 1
	end
end

function Scene:setBackgroundSprite(path)
	if type(path) == "string" then
		self.backgroundSprite = Sprite(0, 0, path)
	else
		self.backgroundSprite = path
	end

	if self.backgroundAlpha == 0 then
		self.backgroundAlpha = 1
	end
end

function Scene:addSpatialHash()
	SpatialHash.new(self)
	self.hasSpatialHash = true
end

function Scene:getEverythingSorted(k)
	local combined = {}
	for _, obj in ipairs(self.entities) do
		table.insert(combined, obj)
	end
	for _, obj in ipairs(self.particles) do
		table.insert(combined, obj)
	end

	table.sort(combined, function(a, b)
		local za, zb = a[k] or 0, b[k] or 0
		if za == zb then
			-- Handle Z-fighting by using unique ID for deterministic order
			return a.__id < b.__id
		end
		return za > zb
	end)

	return combined
end

function Scene:removeEverythingDestroyed()
	if #self.entities > 0 then self:removeDestroyed(self.entities) end
	if #self.particles > 0 then self:removeDestroyed(self.particles) end
	if #self.overlay > 0 then self:removeDestroyed(self.overlay) end
end

function Scene:removeDestroyed(t)
	t:filter_inplace(function(e) return not e.destroyed end)
end

function Scene:setMap(map, level, properties)
	self.map = World(self, map, level, properties)
end

function Scene:getMap(map)
	return self.map
end

function Scene:setLevel(id)
	return self.map:toLevel(id)
end

function Scene:getLevel()
	return self.map:getCurrentLevel()
end

function Scene:onChangingLevel(level)
	self.entities:filter_inplace(function(e) return not e.removeOnLevelChange end)
	self.overlay:filter_inplace(function(e) return not e.removeOnLevelChange end)
end

function Scene:addEntity(...)
	for i, v in ipairs({ ... }) do
		if self.entities:contains(v) then
			warning("Adding entity twice!")
			return
		end
		self:finishObject(v)
		self.entities:add(v)
	end
	return ({ ... })[1]
end

Scene.add = Scene.addEntity

function Scene:addOverlay(...)
	for i, v in ipairs({ ... }) do
		self:finishObject(v)
		self.overlay[#self.overlay + 1] = v
	end
	return ({ ... })[1]
end

function Scene:addUnderlay(...)
	for i, v in ipairs({ ... }) do
		self:finishObject(v)
		self.underlay[#self.underlay + 1] = v
	end
	return ({ ... })[1]
end

function Scene:removeEntity(v)
	if not v.scene then return end
	if v.interactable then
		v:resetHitboxes()
	end
	v.scene = nil
	self.entities:removeValue(v)
end

Scene.remove = Scene.removeEntity

function Scene:finishObject(obj)
	obj.scene = self
	if not obj.__done then
		obj:finalize()
		obj.__done = true
	end
end

function Scene:addParticle(class, ...)
	local Particles = require "head.particles"
	local p = Particles[class](...)
	p.scene = self
	return self.particles:add(p)
end

function Scene:findEntity(f)
	return self.entities:find(f)
end

function Scene:findEntities(f)
	return self.entities:filter(f)
end

function Scene:findEntitiesOfType(a, f)
	local t
	if f then
		t = self.entities:filter(function(x) return x:is(a) and f(x) end)
	else
		t = self.entities:filter(function(x) return x:is(a) end)
	end
	return t
end

function Scene:findEntityOfType(a, f)
	return self:findEntitiesOfType(a, f)[1]
end

function Scene:findEntitiesWithTag(a, f)
	local t
	if f then
		t = self.entities:filter(function(x) return x.tag == a and f(x) end)
	else
		t = self.entities:filter(function(x) return x.tag == a end)
	end
	return t
end

function Scene:findEntityWithTag(a, f)
	return self:findEntitiesWithTag(a, f)[1]
end

function Scene:findNearestEntity(p, f)
	local d = math.huge
	local d2, e
	for i, v in ipairs(self.entities:filter(f)) do
		d2 = v:getDistance(p)
		if d2 < d then
			e = v
			d = d2
		end
	end
	return e, d
end

function Scene:findNearestEntityOfType(p, a, f)
	local d = math.huge
	local d2, e
	for i, v in ipairs(self:findEntitiesOfType(a, f)) do
		d2 = v:getDistance(p)
		if d2 < d then
			e = v
			d = d2
		end
	end
	return e, d
end

function Scene:getCamera()
	return self.camera
end

function Scene:setScene(scene)
	self.showScene = scene
	if self.showScene then
		self.showScene.scene = self
	end
	return scene
end

function Scene:fadeOut(duration, onComplete, fadeMusic, force)
	if self.fadingInProgress and not force then
		return
	end

	self.fadeRect.alpha = 0
	self.fadingInProgress = true
	local tween = self:tween(self.fadeRect, duration or 1, { alpha = 1 })
	tween:oncomplete(function()
		self.fadingInProgress = false

		if onComplete then
			self:nextFrame(onComplete)
		end
	end)

	if self.music and fadeMusic ~= false then
		self.music:stop(duration or 1)
	end
end

function Scene:fadeIn(duration, onComplete, resumeMusic, force)
	if self.fadingInProgress and not force then
		return
	end

	self.fadeRect.alpha = 1
	self.fadingInProgress = true
	local tween = self:tween(self.fadeRect, duration or 1, { alpha = 0 })
	tween:oncomplete(function()
		self.fadingInProgress = false

		if onComplete then
			self:nextFrame(onComplete)
		end
	end)

	if self.music and resumeMusic ~= false then
		self.music:resume(duration or 1)
	end
end

function Scene:addHC()
	self.HC = HC.new()
end

return Scene
