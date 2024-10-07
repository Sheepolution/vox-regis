local Audio = require("audio", ...)

local SFX = Audio:extend("SFX")

SFX.maxVolume = CONFIG.defaultSFXMax

function SFX.updateMaxVolume(max)
	SFX.maxVolume = CONFIG.defaultSFXMax * max
	for _, audio in ipairs(Audio.instances) do
		audio:_updateCurrentVolume()
	end
end

function SFX:new(directory)
	SFX.super.new(self, directory)
	self.sounds = {}

	self.sfx = {}
	self.sources = {}
end

function SFX:add(name, properties, amount)
	if amount then
		if not self.randoms then
			self.randoms = {}
		end

		self.randoms[name] = random.unique_weighted(1, amount, 0.5)

		for i = 1, amount do
			self:add(name .. i, properties)
		end

		return name
	end

	local path = self.directory .. "/" .. name

	self.sfx[name] = {
		path = path,
		max = properties and properties.max or 0,
		pitchRange = properties and properties.pitchRange or 0,
		effect = properties and properties.effect,
		sources = { Asset.audio(path, true) }
	}

	return name
end

function SFX:play(name)
	if self.randoms and self.randoms[name] then
		return self:play(name .. self.randoms[name]())
	end

	local sfx = self.sfx[name]

	for i, v in table.ripairs(sfx.sources) do
		if not v:isPlaying() then
			self:_play(v)
			return v
		end
	end

	if sfx.max > 0 and #sfx.sources >= sfx.max then
		return
	end

	local sound = Asset.audio(sfx.path, true, true)
	table.insert(sfx.sources, sound)
	self:_play(sound)
	return sound
end

function SFX:stop(name)
	if name then
		for _, v in ipairs(self.sfx[name].sources) do
			v:stop()
			v:seek(0)
		end
		return
	end

	for k, _ in pairs(self.sfx) do
		self:stop(k)
	end
end

function SFX:pause(name)
	if name then
		for _, v in ipairs(self.sfx[name].sources) do
			if v:tell() > 0 then
				v:stop()
			end
		end
	end

	for k, _ in pairs(self.sfx) do
		self:pause(k)
	end
end

function SFX:resume(name)
	if name then
		for _, v in ipairs(self.sfx[name].sources) do
			if v:tell() > 0 then
				v:play()
			end
		end
	end

	for k, _ in pairs(self.sfx) do
		self:pause(k)
	end
end

function SFX:_play(sound)
	sound:setVolume((self.volume or CONFIG.defaultSFXVolume) * SFX.maxVolume)

	if self.pitchRange then
		sound:setResamplingRatio(1 + random.float(-self.pitchRange, self.pitchRange))
	elseif self.pitch then
		sound:setResamplingRatio(self.pitch)
	end

	sound:play()
end

function SFX:_updateCurrentVolume()
	if self.muted and self.currentVolume > 0 then
		return
	end

	for _, sfx in pairs(self.sfx) do
		for _, source in table.ripairs(sfx.sources) do
			source:setVolume((self.currentVolume or self.defaultVolume)
				* (self.maxVolume or 1)
				* self.muteFactor)
		end
	end
end

return SFX
