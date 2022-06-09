local module = {}

local ReplicatedStorage = game.ReplicatedStorage

local RunService = game:GetService("RunService")

local NPCSystem = require(script.Parent) -- all NPC utilites
local PropStorage = require(ReplicatedStorage.Data.Props) -- Storage of all props for their data
local FoodStorage = require(ReplicatedStorage.Data.Foods) -- Storage of all foods for their data
local PropSystem = require(game.ServerScriptService.Modules.Prop_System)
local Database = require(game.ServerScriptService.Database.DatabaseUtilites) -- Player database
local Restaurant_Data = require(game.ServerScriptService.Modules.Restaurant_Data)
local PlayerSettings = require(game.ReplicatedFirst.Player_Settings) -- Player settings with all the requirements
local ServerSettings = require(game.ServerScriptService.Server_Settings) -- Game settings
local PathFinder = require(game.ServerScriptService.Modules.Pathfinder) -- Path Finder
local GridManager = require(game.ServerScriptService.Modules.Grid_Manager) -- Grid Manager for AI
local IdService = require(game.ReplicatedStorage.Modules.IdService)

local CustomerGroup = "Customers"

local Customer_Bubble = ReplicatedStorage.Data.Captured_Human.Bubble

local customers = {
	-- each restaurant with it's customers inside
}

local prefix = "rbxassetid://"
local bubble_icons = {
	Looking_For_Table = "7454518392",
	Looking_For_Pizza = "7557862265",
	Looking_To_Order = "7454518573",
}

--[[
	// local functions;
--]]

-- shuffles a table to have random data
local function shuffle(tbl)
	local size = #tbl
	for i = size, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end


--[[
	// AI functions
	functions that are helping the customer complete the objectives
--]]
local function claim_cashier(plr,customer)
	local props = Restaurant_Data:GetRestaurantData(plr,"props")
	local cashiers = props.cashiers
	local current_id = 0
	
	for ID,v in pairs(props.cashiers) do
		if v.waiting == 0 then
			current_id = ID
			v.waiting = customer.id
			break
		end
	end

	return cashiers[current_id],current_id
end

local function claim_chair(plr,customer)
	local props = Restaurant_Data:GetRestaurantData(plr,"props")
	local chairs = props.chairs
	
	local chair_nr = #chairs
	local random_nr = table.create(#chairs)
	for i = 1, chair_nr do
		random_nr[i] = i
	end
	shuffle(random_nr)
	
	local current_id = 0
	
	for i = 1, chair_nr do
		local random_chair = random_nr[i]
		if chairs[random_chair].occupiedby == 0 then
			--print("chair: "..random_chair.." is being occupied which is occupied by "..chairs[random_chair].occupiedby)
			current_id = random_chair
			chairs[random_chair].occupiedby = customer.id
			break
		end
	end
	
	if current_id ~= 0 then
		return chairs[current_id],current_id
	else
		return nil
	end
end

local function unclaim_chair(plr,customer)
	local props = Restaurant_Data:GetRestaurantData(plr,"props")
	local chairs = props.chairs
	
	print(chairs)
	for i,v in pairs(chairs) do
		--print(customer.id.."/"..v.occupiedby)
		if v.occupiedby == customer.id then
			print("found chair")
			--found last chair
			v.occupiedby = 0
			print(chairs)
			return true
		end
	end
	
	return false
end

--local function get_food(plr,customer)
--	local foods = require(ReplicatedStorage.Data.Food)
--end

-- gets the side positions for an object
local function get_sides(asset)
	local asset_rotation: number = asset.R
	local asset_X: number = asset.X
	local asset_Y: number = asset.Y
	local sides = {
		front = Vector2.new(asset_X,asset_Y),
		back = Vector2.new(asset_X,asset_Y),
		left = Vector2.new(asset_X,asset_Y),
		right = Vector2.new(asset_X,asset_Y),
	}
	if asset_rotation == 0 then
		sides.front = sides.front - Vector2.new(0,1)
		sides.back = sides.back - Vector2.new(0,-1)
		sides.left = sides.left - Vector2.new(-1,0)
		sides.right = sides.right - Vector2.new(1,0)
	elseif asset_rotation == 90 then
		sides.front = sides.front - Vector2.new(-1,0)
		sides.back = sides.back - Vector2.new(1,0)
		sides.left = sides.left - Vector2.new(0,-1)
		sides.right = sides.right - Vector2.new(0,1)
	elseif asset_rotation == 180 then
		sides.front = sides.front - Vector2.new(0,-1)
		sides.back = sides.back - Vector2.new(0,1)
		sides.left = sides.left - Vector2.new(1,0)
		sides.right = sides.right - Vector2.new(-1,0)
	elseif asset_rotation == 270 then
		sides.front = sides.front - Vector2.new(1,0)
		sides.back = sides.back - Vector2.new(-1,0)
		sides.left = sides.left - Vector2.new(0,1)
		sides.right = sides.right - Vector2.new(0,-1)
	end
	return sides
end


--[[
	--Customer AI
	customers got 2 objectives:
		1).spend all their money;
		2).command the least amount of meals;
	I    customers will start by waiting in front of the booth to have a place claimed;
	II   once one is claimed they will go at the table and think of what they will order;
	III  when they are ready they will wait someone to take their order;
	IV   after getting the order they will start eating the meal (takes n-amount of the food);
	V    if their money isn't done yet they will ask for another meal of the price (will try to find the optimal food to not go bankrupt);
	VI   everytime when they wait their hapinness will decrease, hapinness is the percentage of they money that they will give when leaving;
--]]
local function spawn_ai(customer,plr,model)
	local restaurant_owner = plr
	local restaurant = model.parent.parent -- janky but it works TODO_to_be_changed
	local restaurant_name = restaurant.Name -- as janky as before
	
	local root_part = model.HumanoidRootPart -- part used to animate
	local animations = game.ReplicatedStorage.Data.Animations.Character
	local humanoid = model.Humanoid
	local head = model.Head
	
	local customer_stats = model.Stats
	local trigger_event = customer_stats.EventTrigger
	local trigger_remote = customer_stats.RemoteTrigger
	
	local current_floor = 1
	local current_grid = GridManager:GetGridName(restaurant_name,current_floor)
	
	local start_node = GridManager:WorldToNode(current_grid,root_part.Position)
	local path_point -- this is later converted into start_node
	
	--// Function that will wait a bot or player to interact with the customer
	local function wait_interaction()
		local triggered_event = false -- this tells the client that the event had been triggered by either of them
		local triggered_entity
		
		local function ent_trigger_event(entity)
			triggered_event = true
			triggered_entity = entity
		end
		
		local employee_connection = trigger_event.Event:Connect(function(entity)
			ent_trigger_event(entity)
		end)
		local player_connection = trigger_remote.OnServerEvent:Connect(function(plr)
			ent_trigger_event(plr)
		end)

		-- yields until baka interacts with me!! (>_<)
		repeat wait() until triggered_event == true
		employee_connection:Disconnect()
		player_connection:Disconnect()
		
		return triggered_entity
	end
	
	--// Leaves the plate with the N amount of money
	--// Unclaims the chair when taken 
	local function pay(chair,amount)
		local chair_model = restaurant.Assets[current_floor][chair.id]
		local table_top = chair_model.Base.ItemPosition
		local table_top_position = table_top.WorldPosition
		
		
		
	end
	
	--// Function that will force the customer to leave the restaurant, used in case of errors too
	local function leave(unclaim) -- used to leave the restaurant in case of any errors
		local leaving_point = ServerSettings.path_interior_coordinate
		
		if customer.sitting == true then
			local Seat = customer.SeatPart
			
			if unclaim == true then
				unclaim_chair(plr,customer)
			end
			
			--Seat.Occupant = nil
			customer.sitting = false
			humanoid.Sit = false
			RunService.Heartbeat:Wait()
			root_part.Anchored = true
			root_part.Position = path_point + Vector3.new(0,3,0) 				
		end
		
		local path,timetook = PathFinder:FindPath(current_grid,start_node,leaving_point)
		path_point = NPCSystem:walk_path(model,path,GridManager:NodeToWorld(current_grid,leaving_point) + Vector3.new(0,3,0) ,0.3) -- walks the path and assings the last point as the start one for next time
		start_node = GridManager:WorldToNode(current_grid,path_point)
		
		module:ClearCustomer(plr,customer)
	end
	
	-- // Main brain operation
	spawn(function()
		-- // ~~ objective#1 find the cashier and get a table ~~ \\
		local data = Database:GetCachedData(plr.UserId,"Restaurant")
		local best_cashier,cashier_id = claim_cashier(restaurant_owner,customer)
		local cashier = data[best_cashier.floor][PropStorage[cashier_id].Sort][best_cashier.id]
		local cashier_world_position = GridManager:NodeToWorld(current_grid,Vector2.new(cashier.X,cashier.Y))
		local cashier_sides = get_sides(cashier)
		
		-- pathfinder
		local path,timetook = PathFinder:FindPath(current_grid,start_node,cashier_sides.front)
		path_point = NPCSystem:walk_path(model,path,cashier_world_position,0.3) -- walks the path and assings the last point as the start one for next time
		start_node = GridManager:WorldToNode(current_grid,path_point)
		
		-- actions after reaching the cashier
		local WaveTrack = humanoid:LoadAnimation(animations.Wave)
		local Bubble = Customer_Bubble:Clone()
		local BubbleImage = Bubble.Bubble.Icon
		BubbleImage.Image = prefix..bubble_icons.Looking_For_Table
		Bubble.Parent = plr.PlayerGui.Bubbles
		Bubble.Name = customer.id
		Bubble.Adornee = head
		Bubble.Target.Value = trigger_remote
		Bubble.Bubble_Handler.Disabled = false
		WaveTrack:Play()
		head.hi:Play()
		
		-- listens to the player/employee til they trigger the event to go at a table
		wait_interaction()
		
		Bubble.Enabled = false
		--// unclaims the cashier
		local props = Restaurant_Data:GetRestaurantData(plr,"props")
		local cashiers = props.cashiers
		
		for i,v in pairs(cashiers) do
			if i == cashier_id then
				v.waiting = 0
				break
			end
		end

		-- // ~~ objective#2 find a chair and order something ~~ \\
		local best_chair = claim_chair(restaurant_owner,customer)
		local chair = data[best_chair.floor][PropStorage[cashier_id].Sort][best_chair.id]
		local chair_world_position = GridManager:NodeToWorld(current_grid,Vector2.new(chair.X,chair.Y))
		local chair_sides = get_sides(chair)
		local chair_model = restaurant.Assets[current_floor]["floor_object"][best_chair.id]
		--print(chair_sides)
		
		-- pathfinder
		path,timetook = PathFinder:FindPath(current_grid,start_node,chair_sides.left)
		path_point = NPCSystem:walk_path(model,path,chair_world_position,0.3) -- walks the path and assings the last point as the start one for next time
		start_node = GridManager:WorldToNode(current_grid,path_point)

		if NPCSystem:seat(model,chair_model) == true then
			RunService.Heartbeat:Wait()
			customer.sitting = true
		else
			warn("[Customer_System]: Customer seat is already occupied! something went wrong..")
			leave(true)
		end
		RunService.Heartbeat:Wait()
		
		--actions after sitting down
		local OrderingTime = (ServerSettings.default_client_ordering_time) + math.random(- ServerSettings.ordering_varitaion, ServerSettings.ordering_varitaion)
		local OrderingTrack = humanoid:LoadAnimation(animations.Ordering)
		local Menu = model.RightHand.Menu
		Menu.Transparency = 0
		OrderingTrack:Play()
		wait(OrderingTime)
		OrderingTrack:Stop()
		Menu.Transparency = 1
		BubbleImage.Image = prefix..bubble_icons.Looking_To_Order
		Bubble.Enabled = true
		
		-- listens to the player/employee til they trigger the event to take the order
		wait_interaction()
		
		local orders = Restaurant_Data:GetRestaurantData(plr,"orders")
		if orders.customer_orders[customer.id] == nil then
			-- the customer did not place any orders
			local Wanted_Food = math.random(1,#FoodStorage)
			local Got_Wanted_food = false
			
			orders.customer_orders[customer.id] = {
				ID = Wanted_Food,
				Status = "Idle",
				Time = os.clock(),
			}
			
			BubbleImage.Image = FoodStorage[Wanted_Food].Logo
			Bubble.Enabled = true
			
			while Got_Wanted_food == false do
				local employee = wait_interaction()
				local item = PropSystem:GetItem(employee)
				if tonumber(item) == Wanted_Food then
					table.remove(orders.customer_orders,customer.id)
					
					Got_Wanted_food = true
					Bubble.Enabled = false
					PropSystem:RemoveItem(employee)
				end
			end
			
			unclaim_chair(restaurant_owner,customer)
			NPCSystem:unseat(model,chair_model)
			leave() -- bye
			
		else
			warn("[Customer_System]: Customer already placed an order, something went wrong!")
			-- not supposed to happen, customer already placed an order
		end
	end)
end

--[[
	// module functions;
--]]

--restaurant (instance)
--vip (booleam)
function module:SpawnCustomer(restaurant,plr,vip)
	-- adds a customer table if table if it doesnt exist
	if customers[plr.UserId] == nil then
		customers[plr.UserId] = {}
	end

	if Restaurant_Data:indexcustomerenter(plr) ~= false then
		local current_customers = customers[plr.UserId]
		local customer_dir:Folder = restaurant.Customers
		local spawnpoint:Part = restaurant["Customer_Spawn_"..math.random(1,1)] -- we consider that a restaurant got only 2 spawn points and they are necessary
		local customer_name:number = IdService:AddId(current_customers,true)
		--print(customer_name)
		
		--// Spawning the customer
		local customer_parent = game.ReplicatedStorage.Data.Captured_Human
		local customer
		if math.random(1,2) == 1 then
			customer = customer_parent.Male:Clone()
			NPCSystem:dress_npc(customer,"Male")
		else
			customer = customer_parent.Female:Clone()
			NPCSystem:dress_npc(customer,"Female")
		end
		customer.Name = tostring(customer_name)
		customer:PivotTo(spawnpoint:GetPivot())
		NPCSystem:setColisionGroup(customer,CustomerGroup)
		NPCSystem:optimize_humanoid(customer.Humanoid) -- Optimizes the humanoid for x15 performance
		customer.Parent = customer_dir
		
		--// Getting the customer ready
		current_customers[customer_name] = {
			id = customer_name,
			model = customer,
			money = 100, -- to be removed;
			meals = 1, -- to be removed;
			hapinness = 100, -- TODO Value based on happiness;
			orders_wanted = 1, -- to be removed;
			orders_got = 0, -- to be removed;
			currently_at = 0,
			current_pos = Vector2.new(0,0), -- the current position
			sitting = false,
		}
		
		--print(current_customers)
		spawn_ai(current_customers[customer_name],plr,customer)
	end
end

function module:ClearCustomer(plr,customer)
	local restaurant_customers = customers[plr.UserId]
	local restaurant = customer.model.Parent.Parent
	local events = restaurant.Events
	
	customer.model:Destroy()
	plr.PlayerGui.Bubbles[customer.id]:Destroy()
	
	events.CustomerLeave:Fire(customer)
	
	local restaurant_stats = Restaurant_Data:GetRestaurantData(plr,"data")
	restaurant_stats.current_clients -= 1
	
	IdService:DelId(restaurant_customers,customer.id)
end

-- clears all customers
function module:ClearCustomers(restaurant)
	customers[restaurant] = {}

	--local customers = Restaurants[restaurant].Customers
	customers:ClearAllChildren()
end

return module






