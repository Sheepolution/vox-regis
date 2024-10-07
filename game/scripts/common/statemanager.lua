local Scene = require "base.scene"
local GameManager = require "gamemanager"
local Menu = require "menu"
local Ending = require "ending"

local StateManager = Scene:extend("State")

function StateManager:new()
	self:toMenu()
end

function StateManager:toMenu()
	self:setScene(Menu())
end

function StateManager:toGame()
	self:setScene(GameManager())
end

function StateManager:toEnding(win)
	self:setScene(Ending(win))
end

return StateManager
