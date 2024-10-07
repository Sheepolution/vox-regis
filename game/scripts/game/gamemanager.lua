local King = require "king"
local Town = require "town"
local Parchment = require "parchment"
local Text = require "base.text"
local Rect = require "base.rect"
local Scene = require "base.scene"
local GameManager = Scene:extend("GameManager")

function GameManager:new(...)
    GameManager.super.new(self, ...)
    G.GameManager = self
    G.Town = self:add(Town())
    G.King = self:add(King())
    G.Parchment = self:add(Parchment())

    self.music = Music()
    self.music:play("town_ambience")

    self.trumpets = Asset.audio("trumpets")
    self.speeches = list()
    for i = 1, 7 do
        self.speeches:add(Asset.audio("speech" .. i))
    end
    self.speechRandom = self.speeches:pick_random_unique_weighted()

    self:fadeIn(1)

    self.gameStarted = false

    if not SEEN_TUTORIAL then
        self.tutorial = true
        self.tutorialRect = self:addOverlay(Rect(0, 0, WIDTH, HEIGHT))
        self.tutorialRect:setColor(0, 0, 0, .8)
        self.tutorialRect.z = 10

        self.tutorialText = self:addOverlay(Text(0, 200, "", "pixel_tome", 16))
        self.tutorialText:centerX(WIDTH / 2)
        self.tutorialText:setAlign("center", WIDTH * .8)

        local years = GAME_DURATION_VICTORY / 60

        self.tutorialTextList = {
            "- Advisor -\nYour grace, the people of the kingdom are unsatisfied, to put it mildly.",
            "- Advisor -\nThe taxes are too high, the food is too scarce, disease is spreading, and crime is rampant.",
            "- King -\nI have heard their complaints, Sandor, but to fix all this will take time.",
            "- King -\n" .. years .. " years! In " .. years .. " years I will have fixed everything.",
            "- Advisor -\nYears we don't have, your grace. They have started forming factions. There are now four different groups gathering in the town square.",
            "- King -\nAnd what of it? Let them gather and share their sorrows. Perhaps it saves my ears from their endless pleas.",
            "- Advisor -\nYour grace, if these factions grow too strong, they might start a rebellion.",
            "- Advisor -\nA faction the size of " ..
            FACTION_SIZE_DEFEAT ..
            " members will most likely succeed in storming the castle, and you will be overthrown.",
            "- King -\nDo these fools not understand that all these problems and their solutions are not within my power alone?!",
            "- Advisor -\nYour grace, the act of assigning blame is often as gratifying as resolving the issue itself.",
            "- King -\n...",
            "- King -\nSandor, I think it's time for a speech, don't you?",
            "- Advisor -\nA speech? What will you say?",
            "- King -\nThe truth, Sandor.\nFor the king always speaks the truth, and I am the king.",
            "- Tutorial -\nHover with your mouse over a flag to see information about a faction.",
            "- Tutorial -\nClick on the flag to blame them for a type of complaint.",
            "- Tutorial -\nWhen you do, all members from other factions will come attack them.",
            "- Tutorial -\nNot *all* members though. Only those who have that particular complaint.",
            "- Tutorial -\nYour goal is to try and keep the factions from growing too large (below " ..
            FACTION_SIZE_DEFEAT .. " members).",
            "- Tutorial -\nTry to survive for " ..
            years .. " years (minutes) with as few speeches as possible.\nTime pauses during speeches and fights.",
            "- Tutorial -\nGood luck, your grace."
        }

        local caps = {
            A = "{",
            B = "|",
            C = "}",
            D = "~",
            E = "¡",
            F = "¢",
            G = "£",
            H = "€",
            I = "¤",
            J = "¥",
            K = "¦",
            L = "§",
            M = "¨",
            N = "©",
            O = "ª",
            P = "«",
            Q = "¬",
            R = "®",
            S = "¯",
            T = "°",
            U = "±",
            V = "²",
            W = "³",
            X = "´",
            Y = "µ",
            Z = "¶"
        }

        for i, __ in ipairs(self.tutorialTextList) do
            for k, v in pairs(caps) do
                self.tutorialTextList[i] = self.tutorialTextList[i]:gsub(k, v)
            end
        end

        local text = table.remove(self.tutorialTextList, 1)
        self.tutorialText:write(text)
    else
        self.gameStarted = true
    end

    self.timer = 0
    self.speechCounter = 0
end

function GameManager:update(dt)
    if self.tutorial then
        if Mouse:isPressed(1) then
            if #self.tutorialTextList > 0 then
                local text = table.remove(self.tutorialTextList, 1)
                self.tutorialText:write(text)
                self.tutorialText.offset.y = -5
                self:tween(self.tutorialText.offset, .2, { y = 0 })
            else
                self.tutorial = false
                self.tutorialRect:destroy()
                self.tutorialText:destroy()
                SEEN_TUTORIAL = true
                self.gameStarted = true
            end
        end
    end

    if self.gameStarted and not self.gameOver and not self.speeching and not self.war then
        self.timer = self.timer + dt
        if self.timer > GAME_DURATION_VICTORY then
            self:victory()
            return
        end
    end

    self.CLICKED_ON_FACTION = false
    GameManager.super.update(self, dt)
    if not self.speeching then
        if Mouse:isPressed(1) then
            if not self.CLICKED_ON_FACTION then
                G.Parchment:hide()
            end
        end
    end
end

function GameManager:doSpeech(faction, complaint)
    self.speechCounter = self.speechCounter + 1
    self.speeching = true
    self.music:setVolume(0, 1)
    self.trumpets:play()
    self:delay(3, function()
        local speech = self.speechRandom()
        speech:play()
        speech:setPitch(.94)
        self:delay(speech:getDuration() + 1, function()
            G.Parchment:hide()
            self.speeching = false
            if G.Town:startWar(faction, complaint) then
                self.music:setVolume(self.music:getDefaultVolume())
                self.music:play("angry_ambience", 4)
                self.war = true
            else
                self:onWarEnd()
            end
        end)
    end)
end

function GameManager:onWarEnd()
    self.war = false
    local clock = Asset.audio("clock")
    clock:play()
    self.music:play("town_ambience", 4)
end

function GameManager:defeat()
    if self.gameOver then return end
    self.gameOver = true
    self:fadeOut(1, function()
        self.scene:toEnding(false)
    end)
end

function GameManager:victory()
    if self.gameOver then return end
    self.gameOver = true
    self:fadeOut(1, function()
        self.scene:toEnding(true)
    end)
end

function GameManager:drawInCanvas()
    GameManager.super.drawInCanvas(self)

    love.graphics.arc("fill", 40, 40, 20, -PI / 2, -PI / 2 + self.timer / GAME_DURATION_VICTORY * 2 * PI)
end

return GameManager
