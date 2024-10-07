local ColorBatteries = require "libs.batteries.colour"

local PaletteColorMeta = {}

PaletteColorMeta.__newindex = function(_, k)
	error("Color " .. k .. " is read-only.")
end

PaletteColorMeta.__index = function(self, c)
	if c == "r" then
		return self[1]
	elseif c == "g" then
		return self[2]
	elseif c == "b" then
		return self[3]
	elseif c == "a" then
		return self[4] or 1
	elseif PaletteColorMeta[c] then
		return PaletteColorMeta[c]
	else
		error("Color " .. c .. " does not exist.")
	end
end

PaletteColorMeta.__call = function(self, r, g, b, a, t)
	if not r then
		return self[1], self[2], self[3], self[4] or 1
	end

	if r == true then
		return { self[1], self[2], self[3], self[4] or 1 }
	elseif t then
		return { self[1] or r, self[2] or g, self[3] or b, self[4] or a }
	else
		return self[1] or r, self[2] or g, self[3] or b, self[4] or a
	end
end

PaletteColorMeta.red = function(self, v, t)
	if t then
		return { v, self[2], self[3], self[4] or 1 }
	else
		return v, self[2], self[3], self[4] or 1
	end
end

PaletteColorMeta.green = function(self, v, t)
	if t then
		return { self[1], v, self[3], self[4] or 1 }
	else
		return self[1], v, self[3], self[4] or 1
	end
end

PaletteColorMeta.blue = function(self, v, t)
	if t then
		return { self[1], self[2], v, self[4] or 1 }
	else
		return self[1], self[2], v, self[4] or 1
	end
end

PaletteColorMeta.alpha = function(self, v, t)
	if t then
		return { self[1], self[2], self[3], v }
	else
		return self[1], self[2], self[3], v
	end
end

local palette = {
	red = { 255, 0, 0 },
	lightred = { 255, 25, 25 },
	blue = { 0, 0, 255 },
	green = { 0, 255, 0 },
	pink = { 255, 0, 255 },
	cyan = { 0, 255, 255 },
	yellow = { 255, 255, 0 },
	orange = { 255, 255 / 2, 0 },
	cyangreen = { 0, 255, 255 / 2 },
	lime = { 255 / 2, 255, 0 },
	purple = { 255 / 2, 0, 255 },
	hotpink = { 255, 0, 255 / 2 },
	white = { 255, 255, 255 },
	lightgray = { 200, 200, 200 },
	gray = { 255 / 2, 255 / 2, 255 / 2 },
	darkgray = { 24, 24, 24 },
	black = { 0, 0, 0 },
	transparent = { 0, 0, 0, 0 }
}

local unpack_colors = function(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = unpack(r)
	end

	return r, g, b, a
end

local ColorMeta = {}

ColorMeta.__index = function(self, k)
	local color = palette[k]
	if not color then
		error("Color " .. k .. " does not exist.")
	end

	return color
end

ColorMeta.toHex = function(r, g, b, a)
	r, g, b, a = unpack_colors(r, g, b, a)

	if a then
		return string.format("#%02x%02x%02x%02x", r * 255, g * 255, b * 255, a * 255)
	end

	return string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
end

ColorMeta.to255 = function(r, g, b, a)
	r, g, b, a = unpack_colors(r, g, b, a)

	if a then
		return r * 255, g * 255, b * 255, a * 255
	end

	return r * 255, g * 255, b * 255
end

ColorMeta.from255 = function(r, g, b, a)
	r, g, b, a = unpack_colors(r, g, b, a)

	if a then
		return r / 255, g / 255, b / 255, a / 255
	end

	return r / 255, g / 255, b / 255
end

function ColorMeta.fromHex(hex)
	local r, g, b, a = ColorBatteries.unpack_rgb(tonumber(hex, 16))
	return { r, g, b, a }
end

function ColorMeta.addColors(colors)
	for k, v in pairs(colors) do
		for i, n in ipairs(v) do
			v[i] = n / 255
		end

		v[4] = v[4] or 1

		v.to255 = ColorMeta.to255
		v.toHex = ColorMeta.toHex

		palette[k] = setmetatable(v, PaletteColorMeta)
	end
end

ColorMeta.addColors(palette)

return setmetatable({
	to255 = ColorMeta.to255,
	from255 = ColorMeta.from255,
	toHex = ColorMeta.toHex,
	fromHex = ColorMeta.fromHex,
	addColors = ColorMeta.addColors
}, ColorMeta)
