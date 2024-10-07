local Sprite = require "base.sprite"
local Circle = require "base.circle"
local Faction = Circle:extend()

function Faction:new(x, y, colorName)
    Faction.super.new(self, x, y)
    self.members = list()
    self.radius = 50
    self.mode = "line"
    self.colorName = colorName
    self.flag = Sprite(0, 0, "faction_flag")
    self.flag.anim:set(colorName)
    self.flag:centerX(self.x)
    self.flag:bottom(self.y)
    self.flag:floor()
    self.z = -self.flag:bottom()

    self.name = FACTION_NAMES[colorName]
end

function Faction:finalize()
    self.flag.scene = self.scene
end

function Faction:update(dt)
    if self.flag:overlapsMouse() then
        self.hovering = true
        G.Town:displayFactionInfo(self)
        if #self.members > 0 and not G.GameManager.speeching and not G.GameManager.war and not G.GameManager.gameOver then
            Mouse:setCursor(Mouse.cursors.hand)
            if Mouse:isPressed(1) then
                G.Parchment:show(self)
                G.GameManager.CLICKED_ON_FACTION = true
            end
        end
    else
        if self.hovering then
            self.hovering = false
            G.Town:hideFactionInfo()
        end
    end
end

function Faction:inviteMember(member)
    member.faction = self
end

function Faction:makeMemberOfficial(member)
    member:joinFaction(self)
    self.members:add(member)
    if #self.members >= FACTION_SIZE_DEFEAT then
        G.GameManager:defeat()
    end
end

function Faction:removeMember(member)
    self.members:remove_value(member)
end

function Faction:getRandomLocation()
    local x, y
    repeat
        local angle = _.randomAngle()
        local distance = random(self.radius)
        x, y = self:centerX() + math.cos(angle) * distance, self:centerY() + math.sin(angle) * distance
    until not self.flag:overlapsPoint(x, y)

    return { x = x, y = y }
end

function Faction:getFactionColor()
    return Color["faction_" .. self.colorName](true)
end

function Faction:getMembers()
    return self.members
end

function Faction:getMemberCount()
    return #self.members
end

function Faction:getComplaintCount()
    local complaints = {}
    for __, member in ipairs(self.members) do
        if member.complaint then
            complaints[member.complaint] = (complaints[member.complaint] or 0) + 1
        end
    end

    return complaints
end

function Faction:draw()
    self.flag:draw()
end

function Faction:getName()
    return self.name
end

return Faction
