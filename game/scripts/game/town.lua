local Faction = require "faction"
local Sprite = require "base.sprite"
local Pleb = require "pleb"
local Rect = require "base.rect"
local Gate = require "gate"
local FactionInfo = require "faction_info"
local Blood = require "blood"
local Scene = require "base.scene"

local Town = Scene:extend()

function Town:new(...)
    Town.super.new(self, -222, -153, 1000, 1000)
    self.background = self:add(Sprite(0, 10, "town"))
    self.background.z = 10000

    -- FACTIONS
    self.factionList = list()
    self.factions = {}
    self.factions.red = self:add(Faction(375, 270, "red"))
    self.factions.blue = self:add(Faction(555, 270, "blue"))
    self.factions.green = self:add(Faction(375, 440, "green"))
    self.factions.yellow = self:add(Faction(555, 440, "yellow"))
    self.factionList:add(self.factions.red, self.factions.blue, self.factions.green, self.factions.yellow)
    self.factionList(function(e) e.visible = false end)

    -- PLEBS
    self.plebs = list()
    self.townSquare = self:add(Rect(328, 256, 274, 202))
    self.townSquare.visible = false
    self.townSquare.mode = "line"
    for i = 1, PLEB_START_COUNT do
        local location = self:findRandomNonFactionLocation()
        local pleb = self:add(Pleb(location.x, location.y))
        self.plebs:add(pleb)
    end
    self.createPlebInterval = step.every(unpack(NEW_PLEB_INTERVAL))
    self.gate = self:add(Gate())

    self:setStart()

    self.grain = self:addOverlay(Sprite(0, 0, "grain"))
    self.factionInfo = self:addOverlay(FactionInfo())
end

function Town:update(dt)
    if not G.GameManager.tutorial and not G.GameManager.speeching and not G.GameManager.war then
        if self.createPlebInterval(dt) then
            self:addPleb()
        end
    end

    self:handlePlebsEntering()

    Town.super.update(self, dt)

    self:handleCamera()
end

function Town:addPleb()
    local pleb = self:add(Pleb(self.gate:centerX() + random(-100, 100), 100))
    pleb:startEntering()
    self.plebs:add(pleb)
end

function Town:handlePlebsEntering()
    local gate_center_y = self.gate:centerY()
    for i, pleb in ipairs(self.plebs) do
        if pleb.state == Enums.PlebState.Entering then
            if pleb.y > gate_center_y then
                pleb:onEnterGate()
            end
        end
    end
end

function Town:havePlebJoinFaction(pleb)
    local faction = self.factionList:random()
    faction:inviteMember(pleb)
end

function Town:findRandomNonFactionLocation()
    local location = {}
    repeat
        location.x = random(self.townSquare:left(), self.townSquare:right(), true)
        location.y = random(self.townSquare:top(), self.townSquare:bottom(), true)
    until not self:isSpotOccupied(location)

    return location
end

function Town:isSpotOccupied(target)
    local radius = self.factionList[1].radius
    for i, faction in ipairs(self.factionList) do
        if faction == self.blamedFaction then
            faction.radius = radius * 2
        end
        if faction:overlaps(target) then
            faction.radius = radius
            return true
        end
        faction.radius = radius
    end
    return false
end

function Town:displayFactionInfo(faction)
    self.factionInfo:displayInfo(faction)
end

function Town:hideFactionInfo()
    self.factionInfo:hideInfo()
end

function Town:handleCamera()
    local x = Mouse.x - WIDTH / 2
    local y = Mouse.y - HEIGHT / 2
    self.x = self.start.x - x * .04
    self.y = self.start.y - y * .04
end

function Town:startWar(faction, complaint)
    self.blamedFaction = faction
    self.blamedFor = complaint

    self.defenders = self.blamedFaction:getMembers()
    self.attackers = list()
    self.innocent = list()

    for i, pleb in ipairs(self.plebs) do
        if not pleb.factionOfficial then
            pleb.faction = nil
            self.innocent:add(pleb)
        elseif pleb.faction ~= faction and
            pleb.complaint == complaint then
            self.attackers:add(pleb)
        end
    end

    if #self.attackers == 0 then
        return false
    end

    self.attackers:searchForDefender()
    self.innocent:runAwayFromFight(self.blamedFaction)

    return true
end

function Town:onPlebDeath(pleb)
    local p = self.defenders:remove_value(pleb) or self.attackers:remove_value(pleb) or self.innocent:remove_value(pleb)
    if not p then return end
    self.plebs:remove_value(pleb)
    pleb.faction:removeMember(pleb)
    local blood = self:add(Blood())
    blood:center(pleb:center())

    if #self.defenders == 0 or #self.attackers == 0 then
        self:handleWarEnd()
    end
end

function Town:handleWarEnd()
    if not G.GameManager.war then return end

    for i, pleb in ipairs(self.plebs) do
        pleb.attacker = false
    end

    self.plebs:walkBackToFaction()
    self.blamedFaction = nil
    G.GameManager:onWarEnd()
end

function Town:checkIfWarHasEnded()
    if #self.defenders == 0 or #self.attackers == 0 then
        self:handleWarEnd()
    end
end

function Town:onSpeech()
    self.plebs(function(p)
        if p.faction and not p.factionOfficial then
            p.faction = nil
            p:moveToTarget(self:findRandomNonFactionLocation())
        end
    end)
end

return Town
