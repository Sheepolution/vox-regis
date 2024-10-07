local Sprite = require "base.sprite"
local Entity = require "base.entity"

local Pleb = Entity:extend()

local PlebState = Enums.PlebState

function Pleb:new(x, y)
    Pleb.super.new(self, x, y)
    self:setImage("pleb")
    self:center(self.x, self.y)
    self.x = math.floor(self.x)
    self.y = math.floor(self.y)

    self.anim:set("idle")
    self.anim:setRandomFrame()

    self.factionSearchInterval = step.every(2, 5)
    self.targetSearchInterval = step.every(2, 8)

    self.state = PlebState.Searching

    self.speed = PLEB_SPEED
    self:matchColorWithFaction()

    self.health = PLEB_HEALTH
    self.attackInterval = step.every(unpack(PLEB_ATTACK_INTERVAL))

    self.speechBubble = self.globalSpeechBubble or Sprite(-1, -18, "speech_bubble")
    self.complaintIcon = self.globalComplaintIcon or Sprite(-1, -21, "complaint_icon")
    Pleb.globalSpeechBubble = self.speechBubble
    Pleb.globalComplaintIcon = self.complaintIcon
end

function Pleb:update(dt)
    if self.dead then return end
    Pleb.super.update(self, dt)
    self.z = -self:bottom()

    if self.state == PlebState.Searching then
        if self.faction then
            self:searchForTarget(dt)
        else
            if not G.Town.war and not self:searchForFaction(dt) then
                self:searchForTarget(dt)
            end
        end
    elseif self.state == PlebState.WalkingToFaction then
        self:handleWalkingToFaction(dt)
    elseif self.state == PlebState.WalkingToTarget then
        self:handleWalkingToTarget(dt)
    elseif self.state == PlebState.WalkingToDefender then
        self:handleWalkingToDefender(dt)
    elseif self.state == PlebState.Attacking then
        self:handleAttacking(dt)
    end
end

function Pleb:startEntering()
    self.anim:set("walk")
    self:moveToEntity(G.Town.gate)
    self.state = Enums.PlebState.Entering
end

function Pleb:onEnterGate()
    self.state = Enums.PlebState.Idle
    self:stopMoving()
    self.anim:set("walk")
    self:moveDown()
    self:delay(3, function()
        self:moveToTarget(G.Town:findRandomNonFactionLocation())
    end)
end

function Pleb:walkToRandomLocation()
    self:moveToTarget(G.Town:findRandomNonFactionLocation())
end

function Pleb:searchForFaction(dt)
    if self.factionSearchInterval(dt) then
        if random.chance(PLEB_JOIN_FACTION_CHANCE) then
            G.Town:havePlebJoinFaction(self)
            self.state = PlebState.WalkingToFaction
            self:moveToEntity(self.faction)
            self.anim:set("walk")
            return true
        end
    end

    return false
end

function Pleb:handleWalkingToFaction()
    if self:getDistance(self.faction) < self.faction.radius then
        self.state = PlebState.Searching
        self:stopMoving()
        self:moveToTarget(self.faction:getRandomLocation())
        self:getRandomComplaint()
        self.faction:makeMemberOfficial(self)
    end
end

function Pleb:searchForTarget(dt)
    if self.targetSearchInterval(dt) then
        if self.faction then
            self:moveToTarget(self.faction:getRandomLocation())
        else
            self:walkToRandomLocation()
        end
    end
end

function Pleb:handleWalkingToTarget()
    local angle = self:getAngle(self.target)
    if math.abs(math.angle_difference(self.targetAngle, angle)) > 1 then
        self:center(self.target.x, self.target.y)
        self:floor()
        self.target = nil
        self.state = PlebState.Searching
        self:stopMoving()
    end
end

function Pleb:moveToTarget(target)
    self.target = target
    self.targetAngle = self:getAngle(target)
    self.state = PlebState.WalkingToTarget
    self:moveToEntity(target)
    self.anim:set("walk")
end

function Pleb:handleWalkingToDefender()
    if self.plebToAttack.dead then
        self:searchForDefender()
        return
    end

    self:moveToEntity(self.plebToAttack, self.speed * PLEB_WAR_SPEEDUP)
    self.anim:set("walk")
    if self:getDistance(self.plebToAttack) < 5 then
        self.state = PlebState.Attacking
        self:stopMoving()
        self.anim:set("attack")
        self.plebToAttack:onBeingAttacked(self)
    end
end

function Pleb:handleAttacking(dt)
    if self.plebToAttack.dead and self.attacker then
        self:searchForDefender()
        return
    end

    if self.attackInterval(dt) then
        self.anim:set("attack")
        self.plebToAttack:takeDamage(1)
    end
end

function Pleb:joinFaction(faction)
    self:matchColorWithFaction(faction)
    self.factionOfficial = true
end

function Pleb:matchColorWithFaction(faction)
    self:changeColors({
        {
            from = { 0, 0, 1 },
            to = faction and faction:getFactionColor() or Color.faction_neutral(true),
        },
    }, true)
end

function Pleb:getRandomComplaint()
    self.complaint = random(COMPLAINT_LIST)
    self.showComplaint = true
    self:delay(3, function()
        self.showComplaint = false
    end)
end

function Pleb:searchForDefender()
    self:stopMoving()
    self.attacker = true
    local pleb = G.Town.defenders:random()
    self.plebToAttack = pleb
    self.state = PlebState.WalkingToDefender

    if not pleb then
        self.state = PlebState.Searching
        G.Town:checkIfWarHasEnded()
    end
end

function Pleb:takeDamage(damage)
    self.health = self.health - damage
    if self.health <= 0 then
        self:die()
        return true
    end
end

function Pleb:die()
    self.dead = true
    G.Town:onPlebDeath(self)
    self:destroy()
end

function Pleb:onKillingPleb()
    if self.attacker then
        self:searchForDefender()
    end
end

function Pleb:runAwayFromFight(faction)
    if self.state == PlebState.Entering then
        return
    end

    self:stopMoving()
    self.state = PlebState.Searching
    faction.radius = faction.radius * 2
    if faction:overlaps(self) then
        faction.radius = faction.radius / 2
        self:moveToTarget(G.Town:findRandomNonFactionLocation())
        return
    end
    faction.radius = faction.radius / 2
end

function Pleb:onBeingAttacked(pleb)
    self.plebToAttack = pleb
    self.state = PlebState.Attacking
    self:stopMoving()
end

function Pleb:walkBackToFaction()
    if self.faction then
        self:moveToTarget(self.faction:getRandomLocation())
    end
end

function Pleb:stopMoving()
    Pleb.super.stopMoving(self)
    self.anim:set("idle")
end

function Pleb:draw()
    Pleb.super.draw(self)
    if self.complaint and self.showComplaint then
        self.speechBubble:drawAsChild(self)
        self.complaintIcon.anim:set(self.complaint)
        self.complaintIcon:drawAsChild(self)
    end
end

return Pleb
