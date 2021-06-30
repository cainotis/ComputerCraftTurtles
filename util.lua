
function copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
	return res
end

function removeKey(table, key)
	local element = table[key]
	table[key] = nil
	return element
end

function isBedrock(inspect)
	if string.find(inspect.name, entry) then return true end

	return false
end
