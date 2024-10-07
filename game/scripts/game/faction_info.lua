local Text = require "base.text"
local Sprite = require "base.sprite"

local FactionInfo = Sprite:extend()

function FactionInfo:new(...)
    FactionInfo.super.new(self, ...)
    self:setImage("faction_info")
    self.complaintIcon = Sprite(0, 0, "complaint_icon")
    self.complaintText = Text(0, 0, "test")
    self.complaintText:setColor(0, 0, 0)
    self.complaintText:setAlign("center", 100)
    self.complaintText:centerOrigin()

    self.nameText = Text(0, 0, "", "pixel_tome", 16)
    self.nameText:setAlign("center", 200)

    self.membersText = Text(0, 0, "")
    self.membersText:setColor(0, 0, 0)
    self.membersText:setAlign("center", 200)
    self.visible = false
end

function FactionInfo:displayInfo(faction)
    self.visible = true
    self:centerX(faction.x)
    self:bottom(faction.y - 50)
    self:floor()
    self.nameText:centerX(self:centerX() + 2)
    self.nameText.y = self.y + 6
    self.nameText:write(faction:getName())

    self.membersText:centerX(self:centerX())
    self.membersText.y = self.nameText:bottom() - 2
    self.membersText:write("Members: " .. faction:getMemberCount())
    self.faction = faction
    self.anim:set(faction.colorName)
end

function FactionInfo:hideInfo()
    -- TODO: Fancy animation?
    self.visible = false
end

function FactionInfo:draw()
    if not self.visible then return end
    FactionInfo.super.draw(self)
    self.nameText:draw()
    self.membersText:draw()
    self:drawIcons()
end

function FactionInfo:drawIcons()
    local icon_width = self.complaintIcon.width
    local total_icon_width = icon_width * #COMPLAINT_LIST
    local complaint_count = self.faction:getComplaintCount()

    for i, complaint in ipairs(COMPLAINT_LIST) do
        self.complaintIcon.anim:set(complaint)
        local icon_x = self:centerX() - total_icon_width / 2 + (i - 1) * icon_width
        self.complaintIcon.x = icon_x
        self.complaintIcon:bottom(self:bottom() - self.complaintText:getFullHeight())
        self.complaintIcon:draw()

        self.complaintText:centerX(icon_x + icon_width / 2)
        self.complaintText:bottom(self:bottom() - 2)
        self.complaintText:write(complaint_count[complaint] or 0)
        self.complaintText:draw()
    end
end

return FactionInfo
