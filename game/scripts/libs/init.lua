local libs = {}

-- love.audio.newAdvancedSource = require "scripts.libs.asl.asl"

libs.push = require "libs.push"

require("libs.batteries"):camelCase():export()
color = nil
step = require "libs.step"
count = require "libs.count"
xool = require "libs.xool"
json = require "libs.json"
Enum = require "libs.enum"

function table.print(t)
	bprint(2, pretty.string(t))
end

function set.print(t)
	bprint(2, pretty.string(t._ordered))
end

math.random = love.math.random
math.randomseed = love.math.setRandomSeed

if (DEBUG_TYPE == "test" or DEBUG_TYPE == "debug") and CONFIG.useLurker then
	local lurker = require "libs.lurker"
	lurker.ignores = { "/scripts", "/LICENSE", "/conf.lua", "/data" }
	lurker.start()
	libs.lurker = lurker
end

function libs.update(dt)
	if libs.lurker then
		libs.lurker.update(dt)
	end
end

function libs.preDraw()
	libs.push:start()
end

function libs.postDraw()
	libs.push:finish()
end

function libs.resize(w, h)
	libs.push:resize(w, h)
end

return libs
