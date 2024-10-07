-- Utils, using lume as base.
local utils = {}

local lume = require "libs.lume"

math.random = love.math.random

for k, v in pairs(lume) do
	utils[k] = v
end

for k, v in pairs(love.math) do
	if not utils[k] then
		utils[k] = v
	end
end

for k, v in pairs(math) do
	if not utils[k] then
		utils[k] = v
	end
end

for k, v in pairs(functional) do
	if not utils[k] then
		utils[k] = v
	end
end

for k, v in pairs(table) do
	if not utils[k] then
		utils[k] = v
	end
end

local Direction = require "base.enums".Direction

local math_random = math.random
local math_abs = math.abs
local math_cos = math.cos
local math_sin = math.sin
local math_floor = math.floor
local pi = math.pi

local print_cache = {}

function utils.noop()
end

local random = lume.random

function utils.random(a, b, int)
	if b == true or int == true then
		if b == true then
			b = a
			a = 1
		end
		return math_random(a, b)
	end

	return random(a, b)
end

local default_print = print

function utils.print(n, ...)
	local info = debug.getinfo(2 + n, "Sl")
	local t = { info.short_src:gsub("scripts/", "./game/scripts/") .. ":" .. info.currentline .. ":" }
	local j = 0
	local str = info.short_src .. info.currentline
	local pr = print_cache[str]
	if not pr then
		for line in love.filesystem.lines(info.short_src) do
			j = j + 1
			if j == info.currentline then
				pr = line
				print_cache[str] = line
			end
		end
	end

	local match = pr:match("print%((.+)%)")
	pr = match and (match .. ",") or pr

	for i = 1, select("#", ...) do
		local x = select(i, ...)
		if type(x) == "number" then
			x = tonumber(string.format("%g", utils.round(x, .001)))
		end

		x = pretty.string(x)

		-- Makes it so that 'print(self.x)' outputs 'x = 10'
		local name = pr:match("([^, (]+).*,")
		if name and not name:find("\"") then
			local stripped_name = name:gsub(" ", ""):gsub("self.", "")
			x = stripped_name .. " = " .. (x or "nil")
			pr = pr:sub((name:find(":") and name:find("),")) and (pr:find("),") + 3) or #name + 2)
		end
		t[#t + 1] = x
	end

	default_print(table.concat(t, " "))
end

function utils.debug(n, ...)
	local info = debug.getinfo(2 + n, "Sl")
	local t = { info.short_src .. ":" .. info.currentline .. ":" }
	for i = 1, select("#", ...) do
		local x = select(i, ...)
		if type(x) == "number" then
			x = tonumber(string.format("%g", utils.round(x, .01)))
		end
		x = pretty.string(x)
		t[#t + 1] = x
	end
	default_print(table.concat(t, " "))
end

-- Creates a list of numbers
function utils.numbers(a, b, ignore)
	if not b then
		b = a
		a = 1
	end
	local t = {}
	for i = a, b, a > b and -1 or 1 do
		if not ignore or not utils.find(ignore, i) then
			t[#t + 1] = i
		end
	end
	return t
end

-- Simple coin flip
function utils.coin()
	return math_random(1, 2) == 1
end

-- Sign coin, either -1 or 1
utils.scoin = utils.random_sign

-- Sin and cos but always positive
function utils.absincos(t)
	return 0.5 + math_sin(t) / 2, 0.5 + math_cos(t) / 2
end

-- Same as sign but 0 = 1 instead of 0
utils.sign2 = lume.sign
utils.sign = math.sign

-- Starting from angle a1 rotating towards angle a2 with a speed of v, return angle
function utils.rotate(a1, a2, v)
	if a1 == a2 then return a1 end
	local diff = utils.anglediff(a1, a2)
	if math_abs(diff) < math_abs(v) then
		return a2
	else
		return a1 + (diff < 0 and -1 or 1) * v
	end
end

-- Get the optimal direction for a1 to rotate towards a2
function utils.angledir(a1, a2)
	local diff = utils.anglediff(a1, a2)
	return diff < 0 and -1 or 1
end

-- Get the difference between angle a1 and angle a2
function utils.anglediff(a1, a2)
	local diff = a2 - a1
	while diff > pi do
		diff = diff - 2 * pi
	end
	while diff < -pi do
		diff = diff + 2 * pi
	end
	return diff
end

function utils.randomAngle()
	return _.random(-PI, PI)
end

-- Bool to sign
function utils.boolsign(a)
	return a and 1 or -1
end

-- Sign to bool
function utils.signbool(x)
	return x >= 0
end

function utils.triangle(n)
	if n == 0 then return 0 end
	if n == 1 then return 1 end
	for i = 2, n - 1 do
		n = n + i
	end
	return n
end

function utils.trueByDefault(value)
	return value == nil and true or value
end

-- Auto converts the value of a string
function utils.autoConvert(v)
	if v == nil then return nil end
	local a
	a = tonumber(v)
	if a then return a end
	if type(v) == "boolean" then return v end
	a = v == "true" and true or nil
	if a then return a end
	if v == "false" then
		return false
	end
	if a ~= nil then return a end
	a = rawget(_G, v)
	if a ~= nil then return a end
	if v:sub(1, 1) == "{" then return utils.dostring("return " .. v) end
	return v
end

function utils.convert(v, typ)
	if not typ then return utils.autoConvert(v) end
	if typ == "string" then return v end
	if typ == "number" then return tonumber(v) end
	if typ == "table" then return utils.dostring("return" .. v) end
	if typ == "bool" then return v == "true" end
	return nil
end

function utils.parse(data, sep)
	local t = {}

	local parts = _.split(data, sep)
	for i, part in ipairs(parts) do
		local d = _.split(part, "=")
		t[d[1]] = _.convert(d[2])
	end

	return t
end

function utils.point_to_list(points)
	local t = {}
	for i, v in ipairs(points) do
		t[#t + 1] = v.x
		t[#t + 1] = v.y
	end

	return t
end

function utils.list_to_point(points)
	local t = {}

	for i = 1, #points, 2 do
		t[#t + 1] = { x = points[i], y = points[i + 1] }
	end

	return t
end

function utils.empty(t)
	return next(t) == nil
end

function utils.is(a, first, ...)
	if select('#', ...) > 1 then
		return a == first or utils.is(a, ...)
	else
		return a == first
	end
end

function utils.mod(v, max)
	return utils.wrap(v, 1, max + 1)
end

function utils.chance(c)
	return utils.random() * 100 < c
end

utils.average = utils.mean
utils.pick = utils.randomchoice

-- e.g. utils.get(t, "name.position.x") returns t[name][position][x]
function utils.get(obj, path, make)
	local list = type(path) == "string" and utils.split(path, ".") or path

	for i, v in ipairs(list) do
		local n = tonumber(v)
		if n then
			list[i] = n
		end
	end

	for i, v in ipairs(list) do
		if i < #list then
			if not obj[v] then
				if make then
					obj[v] = {}
				else
					return nil
				end
			end
			obj = obj[v]
		end
	end
	return obj[list[#list]]
end

-- e.g. utils.set(t, "name.position.x", 5) sets t[name][position][x] to 5
function utils.set(obj, path, value, make)
	local list = type(path) == "string" and utils.split(path, ".") or path

	for i, v in ipairs(list) do
		local n = tonumber(v)
		if n then
			list[i] = n
		end
	end

	for i, v in ipairs(list) do
		if i < #list then
			if not obj[v] and make then
				obj[v] = {}
			end
			obj = obj[v]
		end
	end
	obj[list[#list]] = value
end

-- Check if all values in a list are the same
function utils.same(t, key)
	if #t == 0 then return true end

	local value = key and t[1][key] or t[1]

	for i, v in ipairs(t) do
		if key then
			if v[key] ~= value then
				return false
			end
		elseif v ~= value then
			return false
		end
	end

	return true
end

-- For comparing lists
function utils.compare(a, b)
	if a == b then
		return true
	end

	if #a ~= #b then
		return false
	end

	for i, v in ipairs(a) do
		if not utils.equal(v, b[i]) then
			return false
		end
	end

	return true
end

function utils.equal(a, b)
	if a == b then
		return true
	end

	local typeA = type(a)
	local typeB = type(b)

	if typeA ~= typeB then
		if typeA == "string" or typeB == "string" then
			if tostring(a) == tostring(b) then
				return true
			end
		end
		return false
	end

	if typeA == "table" then
		if #a > 0 then
			if #a ~= #b then
				return false
			end

			for i, v in ipairs(a) do
				if not utils.equal(v, b[i]) then
					return false
				end
			end
		else
			for k, v in pairs(a) do
				if not utils.equal(a[k], b[k]) then
					return false
				end
			end

			for k, v in pairs(b) do
				if not utils.equal(a[k], b[k]) then
					return false
				end
			end
		end
	end

	return false
end

function utils.title(str)
	return str:gsub("^%l", string.upper)
end

local directionCoordinates = {
	[Direction.Left] = { -1, 0 },
	[Direction.Right] = { 1, 0 },
	[Direction.Up] = { 0, -1 },
	[Direction.Down] = { 0, 1 },
	[Direction.UpLeft] = { -1, -1 },
	[Direction.DownLeft] = { -1, 1 },
	[Direction.UpRight] = { 1, -1 },
	[Direction.DownRight] = { 1, 1 },
	[Direction.Center] = { 0, 0 }
}

function utils.directionToCoordinates(direction)
	return unpack(directionCoordinates[direction])
end

local directionOpposites = {
	[Direction.Left] = Direction.Right,
	[Direction.Right] = Direction.Left,
	[Direction.Up] = Direction.Down,
	[Direction.Down] = Direction.Up,
	[Direction.UpLeft] = Direction.DownRight,
	[Direction.DownLeft] = Direction.UpRight,
	[Direction.UpRight] = Direction.DownLeft,
	[Direction.DownRight] = Direction.UpLeft,
	[Direction.Center] = Direction.Center
}

function utils.directionOpposite(direction)
	return directionOpposites[direction]
end

function utils.directionToAngle(direction)
	if direction == Direction.Left then
		return pi
	elseif direction == Direction.Right then
		return 0
	elseif direction == Direction.Up then
		return -pi / 2
	elseif direction == Direction.Down then
		return pi / 2
	elseif direction == Direction.Upleft then
		return -pi * 3 / 4
	elseif direction == Direction.DownLeft then
		return pi * 3 / 4
	elseif direction == Direction.UpRight then
		return -pi / 4
	elseif direction == Direction.downRight then
		return pi / 4
	elseif direction == Direction.Center then
		return 0
	end
end

function utils.isDirectionHorizontal(direction)
	return direction == Direction.Left or direction == Direction.Right
end

function utils.isDirectionVertical(direction)
	return direction == Direction.Up or direction == Direction.Down
end

return utils
