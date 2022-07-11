
os.loadAPI("ComputerCraftTurtles/Miner.lua")
os.loadAPI("ComputerCraftTurtles/json.lua")

local t
miner = Miner.new("ComputerCraftTurtles/data.json", t)

local miner
miner = Miner.new(t)

miner:mine()