-- Add scripts folder to paths
local paths = love.filesystem.getRequirePath()
love.filesystem.setRequirePath(paths .. ";scripts/?.lua;scripts/?/init.lua;scripts/game/?.lua")

-- Launch type
local launch_type = arg[2]

DEBUG = false
DEBUG_TYPE = false
DEBUG_INFO = false

OS = {}
local os = love.system.getOS()
OS[os:upper()] = true

if launch_type then
    DEBUG = true
    DEBUG_TYPE = launch_type

    DEBUGGER = require "lldebugger"

    if DEBUG_TYPE == "debug" then
        DEBUGGER.start()
    elseif DEBUG_TYPE == "record" then
        CONFIG.window.borderless = true
    end
end

love.window.setTitle(CONFIG.title)

if CONFIG.icon then
    love.window.setIcon(CONFIG.icon)
end

-- Require files
-- Load libs and base
local libs = require "libs"
local base = require "base"

require "common.constants"
require "common.enums"
require "common.colors"
require "common.zmap"

-- Prevent any more globals
require "base.strict"

local StateManager = require "common.statemanager"

local stateManager, pause

function love.load()
    stateManager = StateManager()
end

function love.update(t)
    local dt = math.min(t, CONFIG.minFPS)

    dt = base.preUpdate(dt)
    libs.update(dt)

    stateManager:update(dt)

    base.postUpdate(dt)
end

function love.draw()
    base.preDraw()
    libs.preDraw()

    stateManager:draw()

    libs.postDraw()
    base.postDraw()
end

function love.keypressed(key, scancode)
    if DEBUG then
        if key == "pause" then
            pause = not pause
        end
        if key == "f5" then
            love.load()
        end
        if key == "`" then
            love.event.quit()
        end
    end

    base.keypressed(key)
end

function love.keyreleased(key, scancode)
    base.keyreleased(key)
end

function love.textinput(t)
end

function love.mousepressed(x, y, button)
    base.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    base.mousereleased(x, y, button)
end

function love.mousemoved(x, y)
    base.mousemoved(x, y)
end

function love.resize(w, h)
    libs.resize(w, h)
end

function love.wheelmoved(x, y)
    base.wheelmoved(x, y)
end

function love.gamepadpressed(joystick, button)
    base.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    base.gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    base.gamepadaxis(joystick, axis, value)
end

function love.quit()
end
