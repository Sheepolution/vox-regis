local Flow = require "base.components.flow"
local Class = require "base.class"

local Audio = Class:extend("Music")

Audio:implement(Flow)

Audio.maxVolume = 1
Audio.instances = list()

function Audio:new(directory)
    self.defaultVolume = CONFIG.defaultMusicVolume
    self.targetVolume = self.defaultVolume
    self.currentVolume = self.defaultVolume
    self.previousTargetVolumes = {}

    self.directory = directory or ""

    self.muteFactor = 1
    self.muted = false

    self.stacks = {
        mute = 0
    }

    Flow.new(self)
    Audio.instances:add(self)
end

function Audio:update(dt)
    Flow.update(self, dt)
end

function Audio:setDefaultVolume(volume)
    self.defaultVolume = volume
end

function Audio:getDefaultVolume()
    return self.defaultVolume
end

function Audio:setVolume(volume, transition)
    volume = math.clamp01(volume)
    table.insert(self.previousTargetVolumes, self.targetVolume)
    self.targetVolume = volume
    if not self._currentVolumeTween then
        if transition then
            self:_startVolumeTween(transition, volume)
        else
            self.currentVolume = volume
            self:_updateCurrentVolume()
        end
    end
end

function Audio:popVolume(transition)
    self.targetVolume = table.remove(self.previousTargetVolumes)
    if not self._currentVolumeTween then
        if transition then
            self:_startVolumeTween(transition, self.targetVolume)
        else
            self.currentVolume = self.targetVolume
            self:_updateCurrentVolume()
        end
    end
end

function Audio:getVolume()
    return self.targetVolume
end

function Audio:getRealVolume()
    return self.currentVolume
end

function Audio:mute(transition)
    if self.muted then return end
    self.muted = true

    self.stacks.mute = self.stacks.mute + 1

    if transition then
        self:_startMuteFactorTween(transition, true)
    else
        self.muteFactor = 0
        self:_updateCurrentVolume()
    end
end

function Audio:unmute(transition)
    if not self.muted then return end

    self.stacks.mute = self.stacks.mute - 1

    if self.stacks.mute > 0 then
        return
    end

    self.muted = false

    if transition then
        self:_startMuteFactorTween(transition, false)
    else
        self.muteFactor = 1
        self:_updateCurrentVolume()
    end
end

function Audio:toggleMute()
    if self.muted then
        self:unmute()
    else
        self:mute()
    end
end

function Audio:destroy()
    Audio.instances:remove(self)
end

function Audio:_startVolumeTween(time, volume, callback)
    if self._currentVolumeTween then
        self._currentVolumeTween:stop()
    end

    self._currentVolumeTween = self:tween(time, { currentVolume = (volume or self.defaultVolume) })
        :onupdate(self.F:_updateCurrentVolume())
        :oncomplete(function()
            self._currentVolumeTween = nil
            if callback then callback() end
        end)
        :ease("circout")
end

function Audio:_updateCurrentVolume()
end

function Audio:_startMuteFactorTween(time, mute)
    if self.currentMuteFactorTween then
        self.currentMuteFactorTween:stop()
    end

    self.currentMuteFactorTween = self:tween(time, { muteFactor = (mute and 0 or 1) })
        :onupdate(self.F:_updateCurrentVolume())
        :oncomplete(function()
            self.currentMuteFactorTween = nil
        end)
        :ease("circout")
end

return Audio
