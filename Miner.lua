os.loadAPI("ComputerCraftTurtles/Position.lua")
os.loadAPI("ComputerCraftTurtles/json.lua")
os.loadAPI("ComputerCraftTurtles/util.lua")



Miner = {
	origin = Position,
	position = Position,
	founds = {},
	path = {},
	unsafe = {},
	minimum_fuel = 100,
	mining_level = 12,
	size = 64
}

function new(file, ...)
	local self = {}

	local origin, position, founds, path, unsafe, minimum_fuel, mining_level

	if type(...) == 'table' then
		local t = ...
		origin = t.origin
		if getmetatable(origin) ~= Position.Position then
			origin = Position.new(origin)
		end
		position = t.position or t.origin
		if getmetatable(position) ~= Position.Position then
			position = Position.new(position)
		end
		founds = t.founds
		path = t.path
		unsafe = t.unsafe
		minimum_fuel = t.minimum_fuel
		mining_level = t.mining_level
		size = t.size
	else
		origin, founds, path, unsafe, minimum_fuel, mining_level, position = ...
	end

	setmetatable (self, {__index=Miner})
	self.file = file or "data.json"
	self.origin = origin or Position.new()
	self.position = position or util.copy(self.origin)
	self.founds = founds or {}
	self.path = path or {}
	self.unsafe = unsafe or {}
	self.minimum_fuel = minimum_fuel or 100
	self.mining_level = mining_level or 12
	self.size = size or 64
	return self
end

function Miner:down()
	local moved, extra
	moved, extra = turtle.down()
	if(moved) then
		self.position:down()
	end
	json.encodeToFile(self, self.file)
end

function Miner:up()
	local moved, extra
	moved, extra = turtle.up()
	if(moved) then
		self.position:up()
	end
	json.encodeToFile(self, self.file)
end

function Miner:forward()
	local moved, extra
	moved, extra = turtle.forward()
	if(moved) then
		self.position:forward()
	end
	json.encodeToFile(self, self.file)
end

function Miner:back()
	local moved, extra
	moved, extra = turtle.back()
	if(moved) then
		self.position:back()
	end
	json.encodeToFile(self, self.file)
end

function Miner:turnRight()
	turtle.turnRight()
	self.position:turnRight()
	json.encodeToFile(self, self.file)
end

function Miner:turnLeft()
	turtle.turnLeft()
	self.position:turnLeft()
	json.encodeToFile(self, self.file)
end

function Miner:fuelToContinue()
	local fuel
	fuel = turtle.getFuelLevel() - self.minimum_fuel
	print(fuel)
	if fuel <= self.origin:distance(self.position) then
		return false
	end
	return true
end

function Miner:invetoryFull()
	turtle.select(14)
	if (turtle.getItemCount() > 0) then
		return true
	end
	turtle.select(1)
	return false
end

function Miner:isOre(inspect)
	for k,v in pairs(inspect.tags) do
		if string.find(k, "forge:ores") then return true end
	end

	return false
end

function Miner:isSafe(inspect)
	for i, entry in ipairs(self.unsafe) do 
		if string.find(inspect.name, entry) then return false end
	end

	return true
end

function Miner:goToLevel(depth)
	local direction, origin

	origin = self.position.y

	local inspect, dig

	if depth < origin then
		direction = -1
		inspect = turtle.inspectDown
		dig = turtle.digDown
	else
		direction = 1
		inspect = turtle.inspectUp
		dig = turtle.digUp
	end

	assert(turtle.getFuelLevel() + (depth - origin)*direction > self.minimum_fuel + (depth - origin)*direction, "Not enough fuel")

	for i=origin+direction, depth, direction
	do
		local bob, block
		bob, block = inspect()

		if bob then
			if self:isSafe(block) then
				dig()
			else
				local pos = util.copy(self.position)
				if direction == -1 then
					pos:down()
				else
					pos:up()
				end
				self.founds[string.format("%d,%d,%d", pos.x, pos.y, pos.z)] = block.name
				return false
			end
		end
		if direction == -1 then
			self:down()
		else
			self:up()
		end
	end
	return true
end

function Miner:returnToLevel()
	local origin, depth, direction
	origin = self.origin.y
	depth = self.position.y

	if depth < origin then
		direction = 1
	else
		direction = -1
	end

	while self.origin.y ~= self.position.y do
		if depth < origin then
			self:up()
		else
			self:down()
		end
		
	end
end

function Miner:clearVein()
	local bob, block 
	bob, block = turtle.inspectDown()
	if bob then
		if self:isSafe(block) then
			if self:isOre(block) then
				turtle.digDown()
				self.path[#self.path + 1] = util.copy(self.position)
				self:down()
				self:clearVein()
				util.removeKey(self.path, #self.path)
				self:up()
			end
		else
			local pos = util.copy(self.position)
			pos:up()
			self.founds[string.format("%d,%d,%d", pos.x, pos.y, pos.z)] = block.name
		end
	end

	bob, block = turtle.inspectUp()
	if bob then
		if self:isSafe(block) then
			if self:isOre(block) then
				turtle.digUp()
				self.path[#self.path + 1] = util.copy(self.position)
				self:up()
				self:clearVein(path)
				util.removeKey(self.path, #self.path)
				self:down()
			end
		else
			local pos = util.copy(self.position)
			pos:down()
			self.founds[string.format("%d,%d,%d", pos.x, pos.y, pos.z)] = block.name
		end
	end

	for i = 0, 3, 1
	do
		bob, block = turtle.inspect()
		if bob then
			if self:isSafe(block) then
				if self:isOre(block) then
					turtle.dig()
					self.path[#self.path + 1] = util.copy(self.position)
					self:forward()
					self:clearVein(path)
					util.removeKey(self.path, #self.path)
					self:back()
				end
			else
				local pos = util.copy(self.position)
				pos:forward()
				self.founds[string.format("%d,%d,%d", pos.x, pos.y, pos.z)] = block.name
			end
		end
		self:turnRight()
	end
end

function Miner:advance()
	bob, block = turtle.inspect()
	if bob then
		if self:isSafe(block) then
			turtle.dig()
		else
			local pos = util.copy(self.position)
			pos:forward()
			self.founds[string.format("%d,%d,%d", pos.x, pos.y, pos.z)] = block.name
			return false
		end
	end
	self:forward()
	return true
end

function Miner:walk(num)
	for i=0, num-1, 1 do
		if self:advance() then
			local bob, block
			bob, block = turtle.inspectUp()
			if bob and self:isOre(block) then
				self.path = {util.copy(position)}
				self:clearVein()
			end
			bob, block = turtle.inspectDown()
			if bob and self:isOre(block) then
				self.path = {util.copy(position)}
				self:clearVein()
			end

			self:turnRight()
			bob, block = turtle.inspect()
			if bob and self:isOre(block) then
				self.path = {util.copy(position)}
				self:clearVein()
			end

			self:turnLeft()
			self:turnLeft()
			bob, block = turtle.inspect()
			if bob and self:isOre(block) then
				self.path = {util.copy(position)}
				self:clearVein()
			end
			self:turnRight()
			if self:fuelToContinue() == false or self:invetoryFull() then
				self:goBack()
			end
		else
			return i
		end	
	end
	return num
end

function Miner:mineRing()
	self:turnLeft()
	self:move(self.size/2)
	self:turnRight()
	self:move(2)
	self:clearVein()
	self:turnRight()
	self:move(self.size)
	self:turnRight()
	self:move(2)
	self:clearVein()
	self:turnRight()
	self:move(self.size/2)
	self:turnRight()
end

function Miner:mineHalf()
	local dist = 0
	while dist < self.size/2 do
		self:mineRing()
		self:move(4)
		dist = dist + 4
	end
	self:turnRight()
	self:turnRight()
	self:move(dist)
end

function Miner:mine()
	self:goToLevel(self.mining_level)
	if self.position.y/2%2 == 1 then
		self:move(1)
	end
	self:mineHalf()
	self:move(2)
	self:mineHalf()
	self:goTo2D(self.origin)
	self:returnToLevel()
	self:unload()
	self:refuel()
end

function Miner:move(num)
	moved = self:walk(num)
	if moved < num then
		self:turnRight()
		self:move(1)
		self:turnLeft()
		self:move(num-moved)
	end
end

function Miner:goBack()
	self.path[0] = util.copy(self.position)
	self:goTo2D(self.origin)
	self:returnToLevel()
	self:unload()
	self:refuel()
	self:goTo3D(self.path[0])
end

function Miner:unload()
	while self.position.orientation ~= 1 do
		self:turnRight()
	end
	while (self:forward() == false) do end
	self:turnLeft()
	for i=1, 16, 1 do
		turtle.select(i)
		turtle.drop()
	end
	turtle.select(1)
end

function Miner:refuel()
	self:turnRight()
	self:turnRight()
	while (self:forward() == false) do end
	turtle.select(1)
	turtle.suck()
	turtle.refuel()
	turtle.drop()
	turtle.select(1)
	self:turnRight()
	while (self:forward() == false) do end
	while (self:forward() == false) do end
	self:turnRight()
	while (self:forward() == false) do end
end

function Miner:goTo2D(pos)
	local x = pos.x - self.position.x
	
	local z = (pos.z + 1) - self.position.z
	if z < 0 then
		target_orientation = 3
	else
		target_orientation = 1
	end
	while self.position.orientation ~= target_orientation do
		self:turnRight()
	end
	self:move(math.abs(z))

	local target_orientation
	if x < 0 then
		target_orientation = 2
	else
		target_orientation = 0
	end
	while self.position.orientation ~= target_orientation do
		self:turnRight()
	end
	self:move(math.abs(x))

end

function Miner:goTo3D(pos)
	self:goToLevel(pos.y)
	local target_orientation
	
	local x = pos.x - self.position.x
	if x < 0 then
		target_orientation = 2
	else
		target_orientation = 0
	end
	while self.position.orientation ~= target_orientation do
		self:turnRight()
	end
	self:move(math.abs(x))

	local z = (pos.z + 1) - self.position.z
	if z < 0 then
		target_orientation = 3
	else
		target_orientation = 1
	end
	while self.position.orientation ~= target_orientation do
		self:turnRight()
	end
	self:move(math.abs(z))
end


function Miner:createShaft()
	assert(self.origin:distance(self.position) == 0, "You need to be in the origin")
	if self:goToLevel(10) == false then
		self:returnToLevel()
		print("Unsafe block found when digging shaft")
		return
	end
	self:turnRight()
	if self:move(1) == 0 then
		self:turnLeft()
		self:returnToLevel()
		print("Unsafe block found on the shaft's base")
		return
	end
	if self:goToLevel(self.origin.y) == false then
		self:back()
		self:turnLeft()
		self:returnToLevel()
		print("Unsafe block found when digging back shaft")
		return
	end
	self:back()
	self:turnLeft()
end
