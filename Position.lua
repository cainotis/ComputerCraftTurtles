Position = {
	x = 0,
	y = 0,
	z = 0,
	orientation = 0,
}

function new(...)
	local self = {}
	local x, y, z, orientation
	if type(...) == 'table' then
		local t = ...
		x = t.x
		y = t.y
		z = t.z
		orientation = t.orientation
	else
		x, y, z, orientation = ...

	end
	setmetatable (self, {__index=Position})
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
	self.orientation = orientation or 0
	return self
end

function Position:forward()
	if self.orientation == 0 then
		self.x = self.x + 1
	elseif self.orientation == 1 then
		self.z = self.z + 1
	elseif self.orientation == 2 then
		self.x = self.x - 1
	else
		self.z = self.z - 1
	end
end

function Position:back()
	if self.orientation == 0 then
		self.x = self.x - 1
	elseif self.orientation == 1 then
		self.z = self.z - 1
	elseif self.orientation == 2 then
		self.x = self.x + 1
	else
		self.z = self.z + 1
	end
end

function Position:up()
	self.y = self.y + 1
end

function Position:down()
	self.y = self.y - 1
end

function Position:turnRight()
	self.orientation = (self.orientation + 1)%4
end

function Position:turnLeft()
	self.orientation = (self.orientation - 1)%4
end

function Position:distance(a)
	return math.abs(a.x - self.x) + math.abs(a.y - self.y) + math.abs(a.z - self.z)
end