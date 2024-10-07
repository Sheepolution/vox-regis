local Sprite = require "base.sprite"
local Text = require "base.text"
local Button = require "base.button"
local Scene = require "base.scene"

local Menu = Scene:extend()

function Menu:new(...)
    Menu.super.new(self, ...)
    self:setBackgroundImage("title_sky")

    self.tower = self:add(Sprite(34, 59, "title_tower"))
    self.fist = self:add(Sprite(321, 264, "title_fist"))
    self.fist:setStart()
    self.logo = self:add(Sprite(219, 5, "logo_small"))

    self.infoText = self:add(Text(4, 450, "Made by Sheepolution\nLudum Dare #56"))
    self.infoText.border:setColor(0, 0, 0)
    self.infoText.border:set(1, 1)

    self.startButton = self:add(Button(0, 404, "rectangle", "start"))
    self.startButton:centerX(WIDTH / 2)

    self.startButton:onPress(function()
        if not self.fadingInProgress then
            local clock = Asset.audio("clock")
            clock:play()
            self:fadeOut(1, function()
                self:delay(.2, function()
                    self.scene:toGame()
                end)
            end)
        end
    end)

    self.timer = 0
end

function Menu:update(dt)
    Menu.super.update(self, dt)
    self.timer = self.timer + dt
    self.fist.y = self.fist.start.y + math.sin(self.timer * PI * .5) * 10

    local x = Mouse.x - WIDTH / 2
    local y = Mouse.y - HEIGHT / 2

    self.tower.offset.x = x * -.015
    self.tower.offset.y = y * -.015

    self.fist.offset.x = x * .08
    self.fist.offset.y = y * .08
end

return Menu
