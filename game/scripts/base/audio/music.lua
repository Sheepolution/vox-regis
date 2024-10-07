local Audio = require("audio", ...)

local Music = Audio:extend("Music")

Music.maxVolume = CONFIG.defaultMusicMax

function Music.updateMaxVolume(max)
    Music.maxVolume = CONFIG.defaultMusicMax * max
    for _, music in ipairs(Audio.instances) do
        music:_updateCurrentVolume()
    end
end

function Music:new(directory, ...)
    Music.super.new(self, directory, ...)

    self.sources = {}
    for i, source in ipairs({ ... }) do
        self:add(source)
    end

    self.previousVolume = self.defaultVolume

    self.paused = false
    self.stacks.paused = 0
end

function Music:add(name, path, loopPoint)
    local source = Asset.audio(self.directory .. "/" .. (path or name), OS.WEB)
    self.sources[name] = source
    source:setLooping(true)
    source:setVolume(0)
    if loopPoint then
        source:setLoopPoints(loopPoint)
    end
    return source
end

-- Start the source but set the volume to 0
function Music:start(name)
    if not self.sources[name] then
        self:add(name)
    end

    local source = self.sources[name]
    source:setVolume(0)
    source:play()
end

function Music:play(name, transition)
    if type(name) ~= "string" then
        -- name is transition duration. Resume the current source.
        self:resume(name)
        return
    end

    self.stacks.pause = 0

    if not self.sources[name] then
        self:add(name)
    elseif self.currentSource == self.sources[name] and self.currentSource:isPlaying() then
        return
    end

    if self.currentSource and self.currentSource:isPlaying() and not self.stopped then
        self.previousVolume = self.currentVolume
        self.previousSource = self.currentSource
        if transition then
            self:_startPreviousSourceTween(transition)
        else
            self.previousSource:setVolume(0)
            self.previousSource = nil
        end
    else
        self.previousSource = nil
        self.previousVolume = nil
    end

    self.paused = false
    self.stopped = false

    self.currentSource = self.sources[name]
    self.currentSourceName = name

    self.currentSource:play()

    if transition then
        self.currentVolume = 0
        self:_updateCurrentVolume()
        self:_startVolumeTween(transition, self.targetVolume)
    else
        self.currentVolume = self.targetVolume
        self:_updateCurrentVolume()
    end

    return self:getSource()
end

function Music:restart(name, transition)
    if not name then
        name = self.currentSourceName
    elseif type(name) == "number" then
        transition = name
        name = self.currentSourceName
    end

    self.sources[name]:stop()
    self:play(name, transition)
end

function Music:pause(transition)
    if not self.currentSource then return end
    if self.stopped then return end

    self.stacks.pause = self.stacks.pause + 1

    if self.paused then return end

    self.paused = true

    if transition then
        -- Change the volume to 0 and pause the source
        self:_startVolumeTween(transition, 0, function() self.currentSource:pause() end)
    else
        self.previousVolume = self.currentVolume
        self.currentSource:pause()
    end
end

-- Resume audio in case it was paused
function Music:resume(transition)
    if not self.currentSource then return end
    if not self.paused then return end
    if self.stopped then return end

    self.stacks.pause = self.stacks.pause - 1
    if self.stacks.pause > 0 then
        return
    end

    self.paused = false

    self.currentSource:play()

    if transition then
        self:_startVolumeTween(transition, self.targetVolume)
    else
        self.currentVolume = self.targetVolume
        self:_updateCurrentVolume()
    end
end

function Music:stop(transition, clear)
    if not self.currentSource then return end

    self.paused = false
    self.stopped = true

    if transition then
        self:_startVolumeTween(transition, 0, function()
            self.currentSource:stop()
            if clear then self:clear() end
        end)
    else
        self.currentSource:stop()
        if clear then
            self:clear()
        end
    end
end

function Music:clear()
    if self.currentSource then
        self.currentSource:stop()
    end

    self.currentSource = nil
end

function Music:isPlaying()
    return self.currentSource and self.currentSource:isPlaying()
end

function Music:getSource(name)
    if not name then
        return self.currentSource
    else
        if not self.sources[name] then
            self:addSource(name)
        end

        return self.sources[name]
    end
end

function Music:_updateCurrentVolume()
    if self.currentSource then
        self.currentSource:setVolume((self.currentVolume or self.defaultVolume)
            * (self.maxVolume or 1)
            * self.muteFactor)
    end
end

function Music:_startPreviousSourceTween(time)
    if self.previousSourceTween then
        self.previousSourceTween:stop()
    end

    self.previousSourceTween = self:tween(time, { previousVolume = 0 })
        :onupdate(self.F:_updatePreviousVolume())
        :oncomplete(function()
            self.previousSourceTween = nil
            -- self.previousSong:stop()
        end)
        :ease("circout")
end

function Music:_updatePreviousVolume()
    self.previousSource:setVolume(self.previousVolume * Audio.maxVolume * self.muteFactor)
end

function Music:destroy()
    if self.currentSource then
        self.currentSource:stop()
    end

    Audio.super.destroy(self)
end

return Music
