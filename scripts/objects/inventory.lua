-- INVENTORY OBJECT --

-- Create the Inventory base object --
INV = {
	name = "",
	usedCapacity = 0,
	maxCapacity = _mfBaseMaxItems,
	dataStoragesCount = 0,
	inventory = nil, -- [name]{count}
	CCInventory = nil,
	isII = false
}

-- Constructor --
function INV:new(name)
	if name == nil then return end
	local t = {}
	local mt = {}
	setmetatable(t, mt)
	mt.__index = INV
	t.name = name
	t.inventory = {}
	t.CCInventory = {}
	return t
end

-- Reconstructor --
function INV:rebuild(object)
	if object == nil then return end
	local mt = {}
	mt.__index = INV
	setmetatable(object, mt)
end

-- Rescan Inventory --
function INV:rescan()
	
	local totalItem = 0
	-- Itinerate the Invernal Inventory --
	for item, count in pairs(self.inventory) do
		totalItem = totalItem + count
	end
	
	-- Save the used Capacity --
	self.usedCapacity = totalItem
	
	-- Create the CC Inventory Table --
	self.CCInventory = {}
	for k, silo in pairs(global.oreSilotTable) do
		-- Check the Ore Silo --
		if silo ~= nil and silo.valid == true then
			-- Get the Ore Silo Inventory --
			local inv = silo.get_inventory(defines.inventory.chest)
			-- Check the Inventory --
			if inv ~= nil then
				-- Add Items to the CCInventory --
				for item, count in pairs(inv.get_contents()) do
					if self.CCInventory[item] ~= nil then
						self.CCInventory[item] = self.CCInventory[item] + count
					else
						self.CCInventory[item] = count
					end
				end
			end
		end
	end
	
	
end

-- Return remaining capacity --
function INV:remCap()
	-- Rescan the Inventory --
	self:rescan()
	return self.maxCapacity - self.usedCapacity
end

-- Return the number of requested Item --
function INV:hasItem(item)
	
	-- Rescan the Inventory --
	self:rescan()
	
	-- Test if the item exist and return the amount --
	local amount = 0
	if self.inventory[item] ~= nil then
		amount = amount + self.inventory[item]
	end
	if self.CCInventory[item] ~= nil then
		amount = amount + self.CCInventory[item]
	end
	
	return amount
end

-- Request to add an Item and return the amount added --
function INV:addItem(item, amount)

	-- Rescan the Inventory --
	self:rescan()

	-- Calcule the amount of items that can be inserted --
	local capableAmount = math.min(amount, self:remCap())
	
	-- Check if the amount is > 0 --
	if capableAmount > 0 then
		-- Insert the Item --
		if self.inventory[item] ~= nil then
			self.inventory[item] = self.inventory[item] + capableAmount
		else
			self.inventory[item] = capableAmount
		end
	end
	
	-- Return the amount inserted --
	return capableAmount	
	
end

-- Request to remove an Item and return the amount removed --
function INV:getItem(item, amount)
	
	-- Rescan the Inventory --
	self:rescan()
	
	-- Create the Item total Variable --
	totalAmount = 0

	-- Check if the Item is inside the Inventory --
	if self.inventory[item] ~= nil then
	
		-- Calcule the amount removed --
		local itemAmount = math.min(amount, self.inventory[item])
		
		-- Remove the Item amount --
		self.inventory[item] = self.inventory[item] - itemAmount
		
		-- Remove the Item if it doesn't exist anymore inside the Inventory --
		if self.inventory[item] <= 0 then
			self.inventory[item] = nil
		end
		
		-- Return the amount removed --
		totalAmount = totalAmount + itemAmount
	end
	
	-- Check if the Item is inside the CCInventory --
	if self.CCInventory[item] ~= nil then
	
		-- Calcule the amount that can be removed --
		local itemAmount = math.min(amount, self.CCInventory[item])
		local toRemove = itemAmount
		-- Remove Items from Ore Silos --
		for k, silo in pairs(global.oreSilotTable) do
			-- Stop if there are no more Item to remove --
			if toRemove <= 0 then break end
			-- Check the Silo --
			if silo ~= nil then
				-- Get the Inventory --
				local inv = silo.get_inventory(defines.inventory.chest)
				-- Check the Inventory --
				if inv ~= nil then
					-- Remove the maximum amount --
					local removedCount = inv.remove({name=item, count=toRemove})
					-- Decrease the total amount --
					toRemove = toRemove - removedCount
				end
			end
		end
		
		-- Return the amount removed --
		totalAmount = totalAmount + itemAmount
	end
	
	return totalAmount
end

-- Return the Best Quatron Charge --
function INV:getBestQuatron()
	-- Create the Level variable --
	local level = 0
	-- Look for Quatron Charge in the Internal Inventory --
	for i = 100, 0, -1 do
		-- Look for the best Charge --
		local amount = self:hasItem("Quatron" .. i)
		if amount > 0 then
			level = i
			-- Remove the Charge from the Internal Inventory --
			self:getItem("Quatron" .. i, 1)
			return level
		end
	end
	return 0
end

-- Return the Inventory Frame --
function INV:getFrame(guiElement)

	-- Rescan the Inventory --
	self:rescan()

	-- Create the Title Label --
	local title = guiElement.add{type="label"}
	title.style.font = "TitleFont"
	title.caption = (self.name)
	
	-- Create the Amount label --
	local amount = guiElement.add{type="label"}
	amount.style.font = "LabelFont"
	amount.caption = {"", {"gui-description.InventoryAmount"}, ": ", self.usedCapacity, "/", self.maxCapacity}
	amount.style.font_color = {108, 114, 229}
	
	-- Create the Data Storage Label --
	local dataStorage = guiElement.add{type="label"}
	dataStorage.style.font = "LabelFont"
	dataStorage.caption = {"", {"gui-description.dataStorage"}, ": ", self.dataStoragesCount}
	dataStorage.style.font_color = {108, 114, 229}
	dataStorage.style.bottom_margin = 7
	
	-- Create the Inventory List Flow --
	local invList = guiElement.add{type="flow", direction="vertical"}
	-- invList.style.width = 205
	-- Create the list --
	for item, count in pairs(self.inventory) do
		INV:itemToFrame(item, count, invList)
	end
	
	-- Create the Ore Silo Label --
	local oreSilo = guiElement.add{type="label"}
	oreSilo.style.font = "LabelFont"
	oreSilo.caption = {"", {"gui-description.OreSilo"}}
	oreSilo.style.font_color = {108, 114, 229}
	oreSilo.style.bottom_margin = 7
	
	-- Create the CCInventory List Flow --
	local invList = guiElement.add{type="flow", direction="vertical"}
	-- invList.style.width = 205
	-- Create the list --
	for item, count in pairs(self.CCInventory) do
		INV:itemToFrame(item, count, invList)
	end
	
end

-- Create a frame from an Item --
function INV:itemToFrame(item, amount, guiElement)

	-- Create the Frame --
	local frame = guiElement.add{type="frame", direction="horizontal"}
	frame.style.minimal_width = 100
	frame.style.margin = 0
	frame.style.padding = 0
	
	-- Add the Icon and the Tooltip to the frame --
	local sprite = frame.add{type="sprite", tooltip=game.item_prototypes[item].localised_name, sprite="item/" .. item}
	sprite.style.padding = 0
	sprite.style.margin = 0
	
	-- Add the amount label --
	local label = frame.add{type="label", caption=tonumber(amount)}
	label.style.padding = 0
	label.style.margin = 0
	
end









