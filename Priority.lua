local _, core = ...
core.Config.Priority = core.Config.Priority or {} -- Ensure it's initialized
local Priority = core.Config.Priority

local function checkPriority()
    local priorities = {}
    for prio = 1, core.DB.maxPriority do
        priorities[prio] = ""
    end

    for itemID, priority in pairs(core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]].priority) do
        local itemLink = nil
        print("Checking itemID:", itemID) -- Debugging output
        
        if tonumber(itemID) then
            _, itemLink = C_Item.GetItemInfo(tonumber(itemID))
            print("ItemLink from GetItemInfo:", itemLink) -- Debugging output
        end
        if not itemLink then
            itemLink = core.Config:findTypeOfAssignment(itemID) or "Unknown Item"
            print("Fallback ItemLink:", itemLink) -- Debugging output
        end

        if not priorities[priority] then
            print("Warning: Priority index", priority, "does not exist!") -- Safety check
            priorities[priority] = "" -- Initialize if missing
        end

        priorities[priority] = priorities[priority] .. itemLink .. "\n"
        print("Updated priorities[priority]:", priorities[priority]) -- Debugging output
    end
    return priorities
end

function Priority:createPriorityUI()
	for prio = 1, core.DB.maxPriority do
		core.Config.assignUI.priority["p" .. prio] = CreateFrame("Frame", nil, core.Config.assignUI.priority)
		if prio == 1 then
			core.Config.assignUI.priority["p" .. prio]:SetPoint("TOP", core.Config.assignUI.priority, "TOP", 0, 0)
		else
			core.Config.assignUI.priority["p" .. prio]:SetPoint("TOP", core.Config.assignUI.priority["p" .. prio-1], "BOTTOM", 0, -20)
		end

		core.Config.assignUI.priority["p" .. prio]:SetSize(CONFIG_FRAME_WIDTH - 42, 100)

		core.Config.assignUI.priority["p" .. prio].title = core.Config.assignUI.priority["p" .. prio]:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		core.Config.assignUI.priority["p" .. prio].title:SetPoint("TOP", core.Config.assignUI.priority["p" .. prio], "TOP", 0, -3)
		core.Config.assignUI.priority["p" .. prio].title:SetText("Priority " .. prio)

		core.Config.assignUI.priority["p" .. prio].texture = core.Config.assignUI.priority["p" .. prio]:CreateTexture(nil, "BACKGROUND", nil, -7)
		core.Config.assignUI.priority["p" .. prio].texture:SetAllPoints(core.Config.assignUI.priority["p" .. prio])
		core.Config.assignUI.priority["p" .. prio].texture:SetColorTexture(0, 0, 0, 0.5)
	end
	Priority.updatePriorityUI()
end

--- Adds the priority to the database
---@param item integer|string
---@param priority integer
local function addPriorityFound(item, priority)
	core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]].priority[item] = priority
	core:Print("Priority added succesfully")
	Priority.updatePriorities()
	if core.Config.assignUI then
		Priority.updatePriorityUI()
	end
end

--- Removes the priority from the database
---@param item integer|string
local function removePriorityFound(item)
	if core.Config.assignUI then
		Priority.hidePriorityUI()
	end
	core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]].priority[item] = nil
	core:Print("Priority removed succesfully")
	Priority.updatePriorities()
	if core.Config.assignUI then
		Priority.updatePriorityUI()
	end
end

function Priority:addPriority(priority, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if not arg1 then
		core:Print(core.Config.Constants.itemNotFound)
		return
	end

	local priorityNumber = tonumber(priority)
	if priorityNumber < 1 or priorityNumber > core.DB.maxPriority then
		core:Print("Priority number " .. priorityNumber .. " not found")
		core:Print("Allowed priority numbers: 1-" .. core.DB.maxPriority)
		return
	end

	if expansionTable[strlower(arg1)] then
		addPriorityFound(strlower(arg1), priorityNumber)
		return
	end

	local qualityName = core.Config:qualityFound(arg1)
	if qualityName then
		addPriorityFound(qualityName, priorityNumber)
		return
	end

	local itemType = core.Config:itemTypeFound(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if itemType then
		addPriorityFound(itemType, priorityNumber)
		return
	end

	local _, itemLink = C_Item.GetItemInfo(arg1)
	if not itemLink then
		core:Print(core.Config.Constants.itemNotFound)
		return
	end
	if not core:IsLinkType(itemLink, "item") then
		print("no way")
		core:Print(core.Config.Constants.itemNotFound)
		return
	end
	local itemID = core:getItemID(itemLink)

	addPriorityFound(itemID, priorityNumber)
end

function Priority:removePriority(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if not arg1 then
		core:Print(core.Config.Constants.itemNotFound)
		return
	end

	if expansionTable[strlower(arg1)] and core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]].priority[strlower(arg1)] then
		removePriorityFound(strlower(arg1))
		return
	end

	local qualityName = core.Config:qualityFound(arg1)
	if qualityName then
		removePriorityFound(qualityName)
		return
	end

	local itemType = core.Config:itemTypeFound(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	if itemType then
		removePriorityFound(itemType)
		return
	end

	local _, itemLink = C_Item.GetItemInfo(arg1)
	if not itemLink then
		core:Print(core.Config.Constants.itemNotFound)
		return
	end
	if not core:IsLinkType(itemLink, "item") then
		core:Print(core.Config.Constants.itemNotFound)
		return
	end
	local itemID = core:getItemID(itemLink)
	
	if not core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]].priority[itemID] then
		core:Print("Priority for " .. itemLink .. " does not exist")
		return
	end

	removePriorityFound(itemID)
end

function Priority:updatePriorities()
	local priorities = checkPriority()
	for prio = 1, core.DB.maxPriority do
		core.Config.panel.priority["body" .. prio]:SetText(priorities[prio])
	end
end

function Priority:updatePriorityUI()
	local profile = core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]]
	local prioCount = {}

	for i = 1, core.DB.maxPriority do
		prioCount[i] = 1
	end

	for itemID, priority in pairs(profile.priority) do
		local itemName, r, g, b = core.Config:getNameAndColor(itemID)

		priorityLocation[itemID] = {xOffset = 15, yOffset = -22 * prioCount[priority], itemID = itemID}
		if core.Config.assignUI.priority[itemID] then
			core.Config.assignUI.priority[itemID]:Show()
			core.Config.assignUI.priority[itemID]:SetParent(core.Config.assignUI.priority["p" .. priority])
			core.Config.assignUI.priority[itemID]:SetPoint("TOPLEFT", core.Config.assignUI.priority["p" .. priority], "TOPLEFT", priorityLocation[itemID].xOffset, priorityLocation[itemID].yOffset)
		else
			core.Config.assignUI.priority[itemID] = CreateFrame("Frame", nil, core.Config.assignUI.priority["p" .. priority])
			core.Config.assignUI.priority[itemID]:SetPoint("TOPLEFT", core.Config.assignUI.priority["p" .. priority], "TOPLEFT", priorityLocation[itemID].xOffset, priorityLocation[itemID].yOffset)
			core.Config.assignUI.priority[itemID]:SetSize(CONFIG_FRAME_WIDTH - 70, 20)
			core.Config.assignUI.priority[itemID]:SetMovable(true)
			core.Config.assignUI.priority[itemID]:EnableMouse(true)
			core.Config.assignUI.priority[itemID]:RegisterForDrag("LeftButton")
			core.Config.assignUI.priority[itemID]:SetFrameStrata("FULLSCREEN")
			core.Config.assignUI.priority[itemID].text = core.Config.assignUI.priority[itemID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			core.Config.assignUI.priority[itemID].text:SetPoint("LEFT", core.Config.assignUI.priority[itemID], "LEFT", 5, 0)
			core.Config.assignUI.priority[itemID].text:SetText(itemName)
			core.Config.assignUI.priority[itemID].texture = core.Config.assignUI.priority[itemID]:CreateTexture(nil, "OVERLAY", nil, -6)
			core.Config.assignUI.priority[itemID].texture:SetAllPoints(core.Config.assignUI.priority[itemID])
			core.Config.assignUI.priority[itemID].texture:SetColorTexture(r, g, b, 0.5)
			
			core.Config.assignUI.priority[itemID]:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" and not self.isMoving then
					self:StartMoving()
					self.isMoving = true
					self:SetParent(core.Config.assignUI)
				end
			end)

			core.Config.assignUI.priority[itemID]:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and self.isMoving then
					self:StopMovingOrSizing()
					self.isMoving = false
					self:ClearAllPoints()
					for i = 1, core.DB.maxPriority do
						if core.Config:MouseIsOver(core.Config.assignUI.priority["p" .. i]) then
							if priorityLocation[itemID].itemID then
								Priority:addPriority(i, unpack({strsplit(" ", priorityLocation[itemID].itemID)}))
							else
								Priority:addPriority(i, unpack({strsplit(" ", itemID)}))
							end
							return
						end
					end
					self:Hide()
					if priorityLocation[itemID].itemID then
						Priority:removePriority(unpack({strsplit(" ", priorityLocation[itemID].itemID)}))
					else
						Priority:removePriority(unpack({strsplit(" ", itemID)}))
					end
				end
			end)

			core.Config.assignUI.priority[itemID]:SetScript("OnHide", function(self)
				if self.isMoving then
					self:StopMovingOrSizing()
					self.isMoving = false
					self:ClearAllPoints()
					self:SetParent(core.Config.assignUI.priority["p" .. priority])
					self:SetPoint("TOPLEFT", core.Config.assignUI.priority["p" .. priority], "TOPLEFT", priorityLocation[itemID].xOffset, priorityLocation[itemID].yOffset)
				end
			end)
		end
		prioCount[priority] = prioCount[priority] + 1
		
	end
	
	for prio = 1, core.DB.maxPriority do
	core.Config.assignUI.priority["p" .. prio]:SetHeight(22 * prioCount[prio] + 20)
	end
end

function Priority:hidePriorityUI()
	local profile = core.DB.profiles[core.DB.currentProfile[core:getPlayerName()]]
	for itemID, _ in pairs(profile.priority) do
		if core.Config.assignUI.priority[itemID] then
			core.Config.assignUI.priority[itemID]:Hide()
		end
	end
end
