local SpatialHash = Class:extend("Scene")

function SpatialHash:new(size)
    self.spatialHash = {}
    self.spatialHashSize = size or CONFIG.defaultSpatialHashSize
end

function SpatialHash:handleOverlap()
    local i = 0
    local leftovers = {}
    local nextLeftovers = {}
    local leftoverCount = 0
    local on_leftovers = false
    local cache = {}
    local done = {}

    for j, entity in ipairs(self.entities) do
        if not entity.destroyed and entity.interactable then
            entity:setSpatialHash()
        end
    end

    local max = 1000

    while true do
        i = i + 1

        for _1, v in pairs(self.spatialHash) do
            for _2, hash in pairs(v) do
                for j = 1, #hash - 1 do
                    for k = j + 1, #hash do
                        local a, b = hash[j], hash[k]
                        if a and b and a.active and b.active
                            and a.parent ~= b.parent
                            and not (cache[a] and cache[a][b])
                            and not (cache[b] and cache[b][a])
                            and not (done[a] and done[a][b])
                            and not (done[b] and done[b][a])
                            and (not on_leftovers or ((leftovers[a] or leftovers[b]) or (a.parent.pushed or b.parent.pushed))) then
                            if not cache[a] then
                                cache[a] = {}
                            end

                            cache[a][b] = true

                            local overlap, reserve, separated = a.parent:handleOverlap(b.parent, a, b, i == 1)

                            if reserve then
                                nextLeftovers[a] = true
                                nextLeftovers[b] = true
                                leftoverCount = leftoverCount + 2
                            else
                                if overlap then
                                    if not separated then
                                        if not done[a] then
                                            done[a] = {}
                                        end
                                        done[a][b] = true
                                    end

                                    if a.parent.pushed then
                                        a:setSpatialHash(self)
                                        a.parent.pushed = false
                                        nextLeftovers[a] = true
                                        leftoverCount = leftoverCount + 1
                                    end

                                    if b.parent.pushed then
                                        b:setSpatialHash(self)
                                        b.parent.pushed = false
                                        nextLeftovers[b] = true
                                        leftoverCount = leftoverCount + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if leftoverCount == 0 then
            break
        end

        leftovers = nextLeftovers
        on_leftovers = true
        nextLeftovers = {}
        leftoverCount = 0
        cache = {}

        if i > max then
            warning("Max reached in overlap while loop!")
            break
        end
    end

    self:removeEmptySpatialHashes()

    for i, entity in ipairs(self.entities) do
        if not entity.destroyed and entity.interactable then
            entity:handleOverlapWatches()
        end
    end
end

function SpatialHash:removeEmptySpatialHashes()
    for k, v in pairs(self.spatialHash) do
        for l, w in pairs(v) do
            if #w == 0 then
                v[l] = nil
            end
        end
        if _.count(v) == 0 then
            self.spatialHash[k] = nil
        end
    end
end

function SpatialHash:getCoordsToSpatialHash(left, top, right, bottom)
    local x1, y1 = self:getNormalizedSpatialHashPosition(left, top)
    local x2, y2 = self:getNormalizedSpatialHashPosition(right, bottom)

    return x1, y1, x2, y2
end

function SpatialHash:addHitboxToSpatialHash(hitbox, x1, y1, x2, y2)
    for i = y1, y2 do
        for j = x1, x2 do
            if not self.spatialHash[i] then self.spatialHash[i] = {} end
            if not self.spatialHash[i][j] then self.spatialHash[i][j] = {} end
            local hash = self.spatialHash[i][j]
            hash[#hash + 1] = hitbox
        end
    end
end

function SpatialHash:removeHitboxFromSpatialHash(hitbox)
    for i = hitbox.hashCoords.y1, hitbox.hashCoords.y2 do
        for j = hitbox.hashCoords.x1, hitbox.hashCoords.x2 do
            _.remove(self.spatialHash[i][j], hitbox)
        end
    end
end

function SpatialHash:getNormalizedSpatialHashPosition(x, y)
    x = math.floor(x / self.spatialHashSize)
    y = math.floor(y / self.spatialHashSize)
    return x + 1, y + 1
end

function SpatialHash:drawSpatialHash()
    for _1, v in pairs(self.spatialHash) do
        for _2, hash in pairs(v) do
            for i2 = 1, #hash - 1 do
                for j2 = i2 + 1, #hash do
                    local a, b = hash[i2], hash[j2]
                    if a.parent ~= b.parent and not (a.parent.tile and b.parent.tile) then
                        local x1, y1 = a.bb.x + a.bb.width / 2, a.bb.y + a.bb.height / 2
                        local x2, y2 = b.bb.x + b.bb.width / 2, b.bb.y + b.bb.height / 2
                        love.graphics.setColor(1, .4, .4, .8)
                        if (a.parent.tile or b.parent.tile) then
                            love.graphics.setColor(.4, .4, 1, .3)
                        end
                        love.graphics.line(x1, y1, x2, y2)
                        love.graphics.setColor(1, .4, .4)
                    end
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
    for i, v in pairs(self.spatialHash) do
        for j, w in pairs(v) do
            love.graphics.rectangle("line", (j - 1) * self.spatialHashSize, (i - 1) * self.spatialHashSize,
                self.spatialHashSize
                , self.spatialHashSize)
            love.graphics.print(tostring(#w), (j - 1) * self.spatialHashSize + self.spatialHashSize / 2,
                (i - 1) * self.spatialHashSize + self.spatialHashSize / 2)
        end
    end
end

return SpatialHash
