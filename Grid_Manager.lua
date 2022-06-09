local module = {}

local RunService = game:GetService("RunService")
local PropStorage = require(game.ReplicatedStorage.Data.Props)
local ServerSettings = require(game.ServerScriptService.Server_Settings)

local grids = {
	-- all generated grids
}

local grid_data = { -- the default data a grid gets
	size_x = 0,
	size_y = 0,
	startpoint = Vector3,
	diameter = 0,
}


--// !DEBUGGING! functions

local RandomClass = Random.new(420);
local function randomize_grid(grid_name)
	local grid = grids[grid_name].grid
	for x_nr,x in pairs(grid) do
		for y_nr,y in pairs(x) do
			if RandomClass:NextNumber() <= .3 then
				y.Walkable = false
			end
		end
	end
end

local function preview_grid(grid_name)
	local grid = grids[grid_name].grid
	local gizmo = script.Gizmo

	--randomize_grid(grid_name)

	local walkable_color = Color3.new(1, 1, 1)
	local blocked_color = Color3.new(1, 0, 0)

	local debug_folder = game.Workspace.Debug
	debug_folder:ClearAllChildren()

	for key_x,x in pairs(grid) do
		for key_y,y in pairs(x) do
			local part = gizmo:Clone()
			part.Position = y.WorldPoint
			if y.Walkable ~= false then
				part.Color = walkable_color
			else
				part.Color = blocked_color
			end
			--part.SurfaceGui.TextLabel.Text = key_y..","..key_x -- for coordinates
			part.Parent = debug_folder
		end
	end
end


--[[
	// Local functions
--]]

local function Reverse(Table)
	local size = #Table
	for i = 1, math.floor(size/2) do
		local j: number = size - i + 1
		Table[i], Table[j] = Table[j], Table[i]
	end	
	return Table
end

--[[
	// Module functions
--]]

-- generates a grid with a name
-- overwrites the old grid if it is re-generated
function module:GenerateGrid(name,size_x,size_y,startpoint,diameter)
	grids[name] = {} -- indexes the grid
	grids[name].data = grid_data -- adds some info about the grid
	grids[name].grid = {} -- the actual grid is inside

	-- saves the information about the grid
	grids[name].data.size_x = size_x
	grids[name].data.size_y = size_y
	grids[name].data.startpoint = startpoint
	grids[name].data.diameter = diameter

	local nodes = 0

	for x = 1 , size_x do
		grids[name].grid[x] = {}
		for y = 1 , size_y do
			nodes += 1

			local node_position = module:NodeToWorld(name,Vector2.new(x,y))

			local node_data  = {
				WorldPoint = node_position, -- World Position
				ID = nodes, -- unique id of the node
				Walkable = true, -- If it can be passed or not
				X = x, -- GridX position
				Y = y, -- GridY position
				g = 0, -- gCost of the Node
				h = 0, -- hCost of the Node
				f = 0, -- fCost of the Node
				Parent = {} -- The Grid Parent
			}

			grids[name].grid[x][y] = node_data	
		end
	end
	--preview_grid(name)
end


-- generates a grid name from the restaurant name and floor 
function module:GetGridName(restaurant:number,floor:number)
	local restaurant_name:string = tostring(restaurant)
	local floor_id:string = tostring(floor)
	local grid_name:string = "_Plot"..restaurant_name.."_Floor"..floor_id

	return grid_name
end

-- Returns the Object World position in the Grid Space
function module:WorldToNode(grid_name,worldposition)
	local grid = grids[grid_name] -- grids[tostring(grid_name)]
	local grid_data = grid.data
	local grid_origin = grid_data.startpoint
	local grid_diameter = grid_data.diameter

	local y = math.ceil((worldposition.X - grid_origin.X) / grid_diameter)
	local x = math.ceil((worldposition.Z - grid_origin.Z) / grid_diameter)

	local node_position = Vector2.new(x,y)
	return node_position
end

-- Returns the world position of a node
function module:NodeToWorld(grid_name,nodeposition)
	local grid = grids[grid_name] -- grids[tostring(grid_name)]
	local grid_data = grid.data
	local grid_origin = grid_data.startpoint
	local grid_diameter = grid_data.diameter

	--print(nodeposition)
	--print(grid_origin)

	local x = math.ceil(((nodeposition.Y * grid_diameter ) + grid_origin.X) - grid_diameter/2)
	local y = math.ceil(((nodeposition.X * grid_diameter ) + grid_origin.z) - grid_diameter/2)

	local node_position = Vector3.new(x,0,y)
	--print(node_position)
	return node_position
end

-- Retraces the node to the beginning point, to be used after the path had been found
local retrace_limit: number = ServerSettings.path_retrace_limit -- retrace limit
function module:Retrace(startNode,endNode)
	local path = table.create(retrace_limit) -- where the points are
	local final_path: boolean = false
	local points: number = 0
	local currentnode = endNode
	local targetnode = startNode

	for i = 1, retrace_limit do
		points += 1
		path[points] = Vector2.new(currentnode.X,currentnode.Y)
		currentnode = currentnode.Parent
		local currentpath = path[points]
		if currentpath.X == targetnode.X and currentpath.Y == targetnode.Y then 
			final_path = true
			break
		end	
	end

	if final_path == false then
		warn("[Pathfinder]: PATH too long to retrace, exceeding the limit of "..retrace_limit.." searches!!")
	else
		--print(path)
		return Reverse(path) -- reverses the path to start from the beginning
	end
end

--## direct implementation of the restaurant prop system inside the path finder
--## rewrite might be needed for another use cases
function module:CalculateObstacles(name,obstacle_list)
	local grid = grids[name].grid -- indexes the grid

	for _,x in ipairs(grid) do
		for _,y in ipairs(x) do
			y.Walkable = true
		end
	end

	for name,items in pairs(obstacle_list) do
		for i,v in pairs(items) do
			if PropStorage[v.ID].CanCollide == true then
				grid[v.X][v.Y].Walkable = false
			end
		end
	end
	--preview_grid(name)
end

-- destroys the grid as it isnt needed anymore
function module:DestroyGrid(name)
	grids[name] = nil
end

-- returns the grid
function module:GetGrid(name)
	return grids[name]
end

return module
