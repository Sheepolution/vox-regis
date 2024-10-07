local Text = require "base.text"
local Button = require "base.button"
local Sprite = require "base.sprite"

local Parchment = Sprite:extend()

function Parchment:new(...)
    Parchment.super.new(self, ...)
    self:setImage("parchment")
    self:centerX(WIDTH / 2)
    self:bottom(HEIGHT - 20)
    self:setStart()
    self.y = HEIGHT
    self.hidden = true

    self.textFaction = Text(0, -48, "Leo Ruber", "pixel_tome", 16)
    self.textFaction:setAlign("center", 300)
    self.textFaction:setColor(Color.parchment_brown)

    self.textComplaint = Text(0, -16, "", "pixel_tome", 16)
    self.textComplaint:setAlign("center", 130)
    self.textComplaint:setColor(Color.parchment_brown)

    self.complaintIcon = Sprite(0, 2, "complaint_icon")

    -- BUTTONS
    self.buttons = list()

    local button_width = 28
    local total_button_width = button_width * #COMPLAINT_LIST

    for i, complaint in ipairs(COMPLAINT_LIST) do
        local button = Button(0, 0, "rectangle", "complaint_button")
        button.x = self:centerX() - total_button_width / 2 + (i - 1) * button_width

        button.name = complaint
        button:onPress(function()
            self:completeParchment(complaint)
        end)
        self.buttons:add(button)
    end
    --
end

function Parchment:update(dt)
    Parchment.super.update(self, dt)
    self.textFaction:update(dt)
    self.textComplaint:update(dt)
    if not self.completed then
        self.buttons:update(dt)
        self.buttons:set("y", self:centerY() + 2)
    end
end

function Parchment:show(faction)
    self.textFaction:write(faction:getName())
    self.textComplaint:write("")
    self.blamedFaction = faction
    if self.hidden then
        self.hidden = false
        self:tween(.5, { y = self.start.y })
    end
end

function Parchment:hide()
    self.completed = false
    if not self.hidden then
        self.hidden = true
        self:tween(.5, { y = HEIGHT })
    end
end

function Parchment:completeParchment(complaint)
    self.completed = true
    self.textComplaint:write(COMPLAINT_LIST_DESCRIPTION[complaint])
    G.GameManager:doSpeech(self.blamedFaction, complaint)
end

function Parchment:draw()
    Parchment.super.draw(self)
    self.textFaction:drawAsChild(self)
    self.textComplaint:drawAsChild(self)

    if not self.completed and not self.hidden then
        for i, button in ipairs(self.buttons) do
            button:draw()
            self.complaintIcon.anim:set(button.name)
            self.complaintIcon:drawAsChild(button, true)
        end
    end
end

return Parchment
