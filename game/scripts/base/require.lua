local old_require = require

return function(name, path, back)
	if not path then
		return old_require(name)
	end

	if path:find("init") then
		name = (path):gsub('%.init$', '') .. "." .. name
		return old_require()
	end

	for i = 1, 1 + (back or 0) do
		path = path:gsub('%.[^%.]+$', '')
	end

	name = path .. "." .. name
	return old_require(name)
end
