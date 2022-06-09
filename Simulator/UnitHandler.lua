local module = {}

local Players = game:GetService("Players")
local Database = require(game.ServerScriptService.Database.DatabaseUtilites)
local IdService = require(game.ReplicatedStorage.Modules.IdService)

local Storage = game.ReplicatedStorage.Storage
local UnitStorage = require(Storage.Units)
local ItemStorage = require(Storage.Weapons)

-- // Local Functions ;

local function SortSlots(UserData)
	local currentdata = {
		
	}
end

-- optimizes the humanoid to work much faster!
local function optimize_humanoid(humanoid)
	local State = Enum.HumanoidStateType
	humanoid:SetStateEnabled(State.FallingDown, false)
	humanoid:SetStateEnabled(State.Running, false)
	--humanoid:SetStateEnabled(State.RunningNoPhysics, false) -- deprecated
	humanoid:SetStateEnabled(State.Climbing, false)
	humanoid:SetStateEnabled(State.StrafingNoPhysics, false)
	humanoid:SetStateEnabled(State.Ragdoll, false)
	humanoid:SetStateEnabled(State.GettingUp, false)
	humanoid:SetStateEnabled(State.Jumping, false)
	humanoid:SetStateEnabled(State.Landed, false)
	humanoid:SetStateEnabled(State.Flying, false)
	humanoid:SetStateEnabled(State.Freefall, false)
	humanoid:SetStateEnabled(State.Seated, false) -- enabled to support sitting
	humanoid:SetStateEnabled(State.PlatformStanding, false)
	humanoid:SetStateEnabled(State.Dead, false)
	humanoid:SetStateEnabled(State.Swimming, false)
	humanoid:SetStateEnabled(State.Physics, false)
end

local function weld(part1,part2,parent)
	local newWeld = Instance.new("WeldConstraint")
	newWeld.Part0 = part1
	newWeld.Part1 = part2
	newWeld.Parent = parent
end


--[[
		// Management Functions ;
--]]

function module:EquipUnit(User,UnitId,SelectedSlot)
	local UserId = User.UserId
	local UserStats = User.Stats
	local UserData = Database:GetCachedData(UserId)
	
	local Slot
	
	if SelectedSlot == nil then
		for i,v in pairs(UserData["Equipped"]) do
			if v.ID == 0 then
				Slot = i
			end
		end
	else
		Slot = SelectedSlot
	end
	
	if Slot == nil then
		return false -- there is no free space
	end
	
	if UserData["Equipped"][Slot].ID ~= 0 then
		return false -- the slot given was occupied already
	else
		UserData["Equipped"][Slot].ID = UnitId
		UserData["Units"][UnitId].Slot = Slot
		UserStats["Target"].Value = workspace
		Database:CacheData(UserId,UserData)
		return true
	end
end

function module:GearUnit(User,SlotId,GearId)
	local UserId = User.UserId
	local UserStats = User.Stats
	local UserData = Database:GetCachedData(UserId)
	
	local Slot = UserData["Equipped"][SlotId]
	local Tool = UserData["Items"][GearId]
	
	if Tool.Slot ~= 0 then
		local oldslot = UserData["Equipped"][Tool.Slot]
		oldslot.Tool = 0
	end
	
	if Slot.Tool ~= 0 then
		-- unit already got assigned a tool
		local oldtool = UserData["Items"][Slot.Tool]
		oldtool.Slot = 0 -- unequips the tool
		
		Slot.Tool = GearId
		
		if Tool ~= nil then
			Tool.Slot = SlotId
		end
		
	else
		-- unit is disarmed
		Tool.Slot = SlotId
		
		if Tool ~= nil then
			Slot.Tool = GearId
		end
		
		Slot.Tool = GearId
	end
	
	Database:CacheData(UserId,UserData)
end

function module:RemoveUnit(User,UnitId)
	local UserId = User.UserId
	local UserStats = User.Stats
	local UserData = Database:GetCachedData(UserId)
	
	local success = false
	
	for i,v in pairs(UserData["Equipped"]) do
		if v.ID == UnitId then
			v.ID = 0
			UserData["Units"][UnitId].Slot = 0
			success = true
		end
	end
	
	if success == true then
		UserStats["Target"].Value = workspace
		Database:CacheData(UserId,UserData)
		return true
	else
		return false -- unit is not equipped
	end
end

function module:DeleteUnit(User,UnitId)
	local UserId = User.UserId
	local UserData = Database:GetCachedData(UserId)

	module:RemoveUnit(User,UnitId) -- unequips it first
	
	IdService:DelId(UserData["Units"],UnitId) -- deletes the unit
	
	Database:CacheData(UserId,UserData)
end

function module:StoreUnit(User,Unit)
	-- // Soon to be added
end

--[[
		// Action Functions ;
--]]

function module:LoadGear(User,SlotId)
	local UserId = User.UserId
	local UserData = Database:GetCachedData(UserId)
	
	local SlotData = UserData["Equipped"][SlotId]
	
	if SlotData.Tool == 0 then return nil end

	local UnitInstance = workspace.Units[User.Name][SlotId]
	local RightGrip = UnitInstance.RightHand["RightGripAttachment"]
	
	local Toolid = SlotData.Tool
	local ToolData = ItemStorage[UserData["Items"][Toolid].ID]
	local ToolModel = ToolData.Model:Clone()
	--local ToolGrip = ToolModel.Handle["HandleAttachement"]
	
	weld(ToolModel.Handle,UnitInstance.RightHand,ToolModel.Handle)
	ToolModel:PivotTo(UnitInstance.RightHand.CFrame)
	ToolModel.Parent = UnitInstance.RightHand
end

function module:LoadUnits(User)
	local UserId = User.UserId
	local UserData = Database:GetCachedData(UserId)
	
	local Folder 
	-- searches for the folder
	if game.Workspace.Units:FindFirstChild(User.Name) == nil then
		local newFolder = Instance.new("Folder")
		newFolder.Name = User.Name
		newFolder.Parent = game.Workspace.Units
		Folder = newFolder
	else
		Folder = game.Workspace.Units:FindFirstChild(User.Name)
		Folder:ClearAllChildren() -- units will be re added in afterwards
	end
	
	local unitsToLoad = {} -- units that will be loaded
	
	-- indexes all units that can be loaded
	for i,v in pairs(UserData["Equipped"]) do
		if UserData["Units"][v.ID] ~= nil then
			table.insert(unitsToLoad,UserData["Units"][v.ID])
		end
	end
	
	for i,v in pairs(unitsToLoad) do
		local unit = UnitStorage[v.ID].Model:Clone()
		
		optimize_humanoid(unit.Humanoid)
		
		unit.Data:SetAttribute("Pos_ID",v.Slot)
		unit.Name = v.Slot
		unit.Parent = Folder
		if UserData["Equipped"][v.Slot].Tool ~= 0 then
			module:LoadGear(User,v.Slot)
		end
		
		local humanoidBrain = game.ReplicatedStorage.Storage.HumanoidBrain:Clone()
		humanoidBrain.Parent = unit
		humanoidBrain.Disabled = false
	end
end

function module:AttackUnit(User,Unit)
	local UserStats = User.Stats
	local UserTarget = UserStats.Target
	
	local Character = User.Character
	local Target = UserTarget.Value
	
	-- checks if the character lost the target
	UserTarget:GetPropertyChangedSignal("Value"):Connect(function()
		if UserTarget.Value == workspace or UserTarget.Value == nil then
			return true
			-- stops because the target had been lost
		end
	end)
	-- checks if the character is close to the target
	task.spawn(function()
		while true do
			task.wait(0.33)
			
			local characterRoot = Character:FindFirstChild("HumanoidRootPart")
			local targetRoot = Target:FindFirstChild("HumanoidRootPart")
			local targetHum = Target:FindFirstChild("Humanoid")
			
			if characterRoot == nil or targetRoot == nil then
				UserTarget.Value = workspace -- target is invalid or the player is invalid
				return true
			end
			
			if targetHum:GetAttribute("Health") <= 0 then
				UserTarget.Value = workspace -- target died
				return true
			end
			
			if math.abs((characterRoot.Position - targetRoot.Position).Magnitude) > 50 then
				UserTarget.Value = workspace -- target is too far away
				return true
			end
		end
	end)
end

return module
