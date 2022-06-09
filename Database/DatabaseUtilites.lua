local module = {}

local HttpService 	= game:GetService("HttpService")
local RunService 	= game:GetService("RunService")
local RealmSettings = require(game.ServerScriptService.Server_Settings)
local Data_Template = require(script.Player_Data_Template)

local Data_Limit_Event = game.ServerScriptService.Events.DataLimited

--// events
local Remotes 		= game.ReplicatedStorage.Remotes
local Data_Remote 	= Remotes.Data
local Notify 		= Remotes.Notify

--// connection
local DB_IP 	= RealmSettings.database_ip
local DB_PORT 	= RealmSettings.database_port
local DB_USER 	= RealmSettings.database_user
local DB_PASS 	= RealmSettings.database_pass

--// databases
local Account_DB = RealmSettings.database_accountDB

--// stats
local DB_attempts = RealmSettings.POST_or_GET_attempts
local DB_cooldown = RealmSettings.POST_or_GET_attempts_Cooldown

local HTTP_soft_limit = RealmSettings.http_soft_limit -- the soft limit of the requests , they will go in queue
local HTTP_hard_limit = RealmSettings.http_hard_limit -- the hard limit of the requests , they will stop til there are enough requests to continue
local HTTP_requests = 0 -- how many http requests had been sent this number resets every 1 min
local started_tracking = false -- value for runtime, starts a while loop and resets each N min

--[[
	// Special Data Storage;
--]]
local Retrieved_Player_Data = {
	-- the original Database data for "delta saving"
}
local Player_Data = {
	-- local Player Data do be stored here man
}
local Queue = {
	-- queue with the soft capped keys
}
local Autosave_History = {
	-- history of autosaves with dates when the user last saved
}

--[[
	// URL Library;
--]]
--local DATABASE_URL = "http://"..DB_USER..":"..DB_PASS.."@"..DB_IP..":"..DB_PORT -- VPS DB URL
local DATABASE_URL = "http://"..DB_IP..":"..DB_PORT -- VPS DB URL

--[[
	// Local Functions
--]]

local function Check_Limit()
	if HTTP_requests > HTTP_hard_limit then
		Data_Limit_Event:Fire(true)
		return nil
	elseif HTTP_requests > HTTP_soft_limit then
		Data_Limit_Event:Fire()
		return true
	else
		return false
	end
end

-- Based on the UserID it will return the partition it is located
local function KeyToPartition(Key)
	local StringID = tostring(Key)
	local Partition = tonumber(string.sub(StringID, -3))

	if Partition == 0 then
		Partition = 1000
	end

	return Partition
end

-- logs the changes of a data event(to generate a queue for the autosaves)
local function log_change(key)
	if Autosave_History[key] ~= nil then
		table.remove(Autosave_History,key)
	end
	if Queue[key] ~= nil then
		table.remove(Queue,key)
	end
	local current_time = tick()
	table.insert(Autosave_History,key)
end

-- reverses the table values
local function reverse_table(Table)
	local new_table = Table
	if new_table ~= nil then
		for i = 1, math.floor(#new_table/2) do
			local j = #new_table - i + 1
			new_table[i], new_table[j] = new_table[j], new_table[i]
		end
		return new_table
	else
		return nil -- the table is empty
	end
end

--[[
	// Data Functions
--]]


---- --(!)//used if save only changes is on NOT WORKING
--local function prepare_export_data(OriginalData,CurrentData)
--	local prepared_data = CurrentData

--	local function doStuff(index, value)
--		if OriginalData[index] == CurrentData[index] then
--			print("removing "..tostring(CurrentData[index]))
--			table.remove(prepared_data,prepared_data[value])
--		end
--	end

--	local function recurseTable(tbl, func)
--		for index, value in pairs(tbl) do
--			if type(value) == 'table' then
--				recurseTable(value, func)
--			else
--				func(index, value)
--			end
--		end
--	end

--	recurseTable(prepared_data,doStuff)

--	return prepared_data

--end
---- testing purposes
--function module:prepare()
--	local key = 10
--	local data = prepare_export_data(Retrieved_Player_Data[key],Player_Data[key])
--	return data
--end


--[[
	// User Library;
	(V.1)
	Functions made for a Player modification
--]]


-- --(1)//Retrieves the Cached Player Data
function module:GetCachedData(plr, ...)
	--if Player_Data[plr] ~= nil then
	--	if key ~= nil then
	--		--print(Player_Data[plr]) --Debuggins purposes! can cause conflicts if kept
	--		return Player_Data[plr][key]
	--	else
	--		return Player_Data[plr]
	--	end
	--else
	--	-- we guess that the script needs the entire table
	--	return Player_Data
	--end
	local arguments = {...} -- arguments for searching
	local directory = Player_Data[plr] -- directory that will be returned

	if arguments == nil then
		return directory
	else
		for i,v in pairs(arguments) do
			if directory[v] ~= nil then
				directory = directory[v]
			else
				-- script gave an invalid path
				warn("[Database]: Invalid path given, aborting...")
				return nil
			end
		end
		-- after the directory is found in the nested loop and no invalid path was given it will return it back
		return directory
	end
end


-- --(3)//Caches The Player Data Use it only when Retrieving the Data!
function module:CacheData(plr,data, key)
	if data ~= nil and plr ~= nil then
		local Player = game:GetService("Players"):GetPlayerByUserId(plr)

		if RealmSettings.save_only_changes == true then -- doesn't work
			Retrieved_Player_Data[plr] = data
		end

		if key ~= nil then
			Player_Data[plr][key] = data
			--Data_Remote:FireClient(Player,data,key)
		else
			Player_Data[plr] = data
			--Data_Remote:FireClient(Player,data)
		end
		Data_Remote:FireClient(Player,Player_Data[plr])
		--print("[server]: data incoming")

		return true -- returns true to show that it succeed
	else
		return nil -- returns false to show that it failed
	end
	--local arguments = {...} -- arguments for searching
	--local directory = Player_Data[plr] -- directory that will be saved

	--if data ~= nil then
	--	if arguments == nil then
	--		Player_Data[plr] = data
	--	else

	--	end
	--else
	--	warn("[Database]: Did you miss the player or forgot the data? caching failed, aborting...")
	--end
end


-- --(4)//RECOMMENDED!! Uncaches the data after the player left
function module:UnCacheData(key)
	if key ~= nil then

		if Retrieved_Player_Data[key] ~= nil then Retrieved_Player_Data[key] = nil end
		if Player_Data[key] ~= nil then Player_Data[key] = nil end
		if Queue[key] ~= nil then Queue[key] = nil	end
		if Autosave_History[key] ~= nil then Autosave_History[key] = nil end

		return true -- returns true to show that it succeed
	else
		return nil -- returns false to show that it failed
	end
end


-- --(5)//Gets the Data of a User
function module:GetUserData(key)
	HTTP_requests += 1

	local current_key = key
	local current_partition = KeyToPartition(key)

	--// URL Request
	local Player_URL = DATABASE_URL.."/"..Account_DB.."/"..current_key
	--// ~~~~~~~~~~~

	local tick_1 = tick()

	if started_tracking ~= true then -- tracker to keep track of HTTP requests
		spawn(function()
			while wait(60) do
				HTTP_requests = 0
			end
		end)
	end

	for i = 1, DB_attempts do -- loops as many times it needs to get the data
		local Data
		local Key_Data

		--pcall wrapped
		local success, errorMessage = pcall(function()
			--http request
			Data = HttpService:RequestAsync(
				{
					Url = Player_URL,  -- Database URL
					Method = "GET",
					Headers = { 
						["Content-Type"] = "application/json" ,
					}, -- JSON type of data dont modify!
				}
			)
			Key_Data = HttpService:JSONDecode(Data.Body)
		end)

		if success then
			--checks if the response was a success
			if Data.Success then
				--request was a success
				local tick_2 = tick()
				print("[Database]: retrieved data for key: "..current_key.." in: "..math.floor((tick_2 - tick_1)*1000).." ms")
				log_change(current_key)
				return Key_Data
			elseif Data.StatusCode == 404 then
				--request was a success but no data had been found
				print("[Database]: key:"..current_key.." doesn't have a database, consider making one")
				return nil
			else
				--request was a success but one unknown error appeared
				warn("[Database]: getting data for key:"..current_key.." failed ("..i..")")
				warn(Data)
			end
		else
			--request was not followed by a respone an unknown error
			warn(errorMessage)
		end
	end

	-- //went trough the loop and still didn't found any data
	warn("[Database]: failed fetching data for key:"..current_key)
	return nil
end


-- --(6)//Creates a new data using the template given
function module:CreateUserData(key)
	--HTTP_requests += 1
	local current_key = key
	local data = Data_Template
	--print(prepared_data)
	--print(Player_URL)

	if Retrieved_Player_Data[current_key] == nil then
		Player_Data[current_key] = data
		log_change(current_key)
	end

	--// in case it fails
	print("[Database]: created data")
	return false
end


-- --(7)//Updates the Data of a User with the current one
function module:SaveUserData(key)
	HTTP_requests += 1
	local current_key = key
	local current_partition = KeyToPartition(key)
	local data = module:GetCachedData(current_key)
	local prepared_data = HttpService:JSONEncode(data)

	--// URL Request
	local Player_URL = DATABASE_URL.."/"..Account_DB.."/"..current_key
	--// ~~~~~~~~~~~

	local tick_1 = tick()

	for i = 1, DB_attempts do -- loops as many times it needs to get the data
		local response
		local Key_Data
		
		--pcall wrapped
		local success, errorMessage = pcall(function()
			--http request
			response = HttpService:RequestAsync(
				{
					Url = Player_URL,  -- Database URL
					Method = "PUT",
					Headers = { 
						["Content-Type"] = "application/json",
					}, -- JSON type of data dont modify!
					Body = prepared_data
				}
			)
		end)

		if success then
			--checks if the response was a success
			if response.Success then
				--request was a success
				local tick_2 = tick()
				print("[Database]: saved data for key: "..current_key.." in: "..math.floor((tick_2 - tick_1)*1000).." ms")
				data["_rev"] = string.gsub(response["Headers"]["etag"], '"', "") 
				log_change(current_key)
				return true
			else
				--request was a success but one unknown error appeared
				warn("[Database]: saving data for key:"..current_key.." failed ("..i..")")
				print(response)
			end
		else
			--request was not followed by a respone an unknown error
			warn(errorMessage)
		end
	end

	-- //went trough the loop and still didn't save the data
	warn("[Database]: failed saving data for key:"..current_key)
	return nil
end

-- --(8)//Bundles all the keys into one http request
function module:SaveBundleUserData(keys_array)
	HTTP_requests += 1
	local tick_1 = tick()
	local Database_URL = DATABASE_URL.."/"..Account_DB.."/_bulk_docs"
	local keys = 0 -- keep count of the amount of keys

	--print(keys_array)
	-- sends back to each client that their data is being saved
	for i,v in pairs(keys_array) do
		local player = game.Players:GetPlayerByUserId(v)
		if player ~= nil then
			Notify:FireClient(player,"Saving")
		end
	end

	local data_body = { -- Data Template
		["docs"] = {} ,
		["new_edits"] = false ,
	}	

	for i,v in pairs(keys_array) do -- adds the data into the *body* that will be used afterwards
		if Player_Data[v] ~= nil then
			local data = Player_Data[v]
			table.insert(data_body.docs,data)
			keys += 1
		else
			warn("[Database]: one of the requested keys in bundle does not exist, player must've left or data not loaded (key: "..v..")")
		end
	end

	local prepared_body = HttpService:JSONEncode(data_body)
	
	--print(data_body)
	
	for i = 1, DB_attempts do
		local response = HttpService:RequestAsync(
			{
				Url = Database_URL,  -- Database URL
				Method = "POST",
				Headers = { 
					["Content-Type"] = "application/json",
				}, -- JSON type of data dont modify!
				Body = prepared_body
			}
		)

		if response.Success then
			local tick_2 = tick()
			print("[Database]: saved data for "..keys.." key/s in: "..math.floor((tick_2 - tick_1)*1000).." ms")
			print(response)
			
			-- sends back to each client that their data got saved
			for i,v in pairs(keys_array) do
				local player = game.Players:GetPlayerByUserId(v)
				if player ~= nil then
					Notify:FireClient(player,"Saved")
				end
			end
			
			return true
		else
			warn("[Database]: failed saving data for "..keys.." key/s ("..i..")")
			warn(response)
			wait(DB_cooldown)
		end
	end
end

-- --(9)//Returns the list with all players that should have their data saved but prioritizes the ones in the queue
function module:GetQueue()
	local new_list = {} -- the new list that will contain all the players that must have their data bundled and saved
	local current_Queue = Queue
	local current_History = Autosave_History

	local keys = 0 -- the amount of keys, it will also return this

	for i,h_key in pairs(current_History) do -- removes everyone that is queued from the list to not have dublicates
		local exist = false
		for _,q_key in pairs(current_Queue) do
			if h_key == q_key then
				exist = true
			end
		end
		if exist == true then
			table.remove(current_History,i)
		end
	end

	reverse_table(current_Queue) -- reverses the table to get the oldest players first for the autosave

	for i,v in pairs(current_Queue) do
		table.insert(new_list,v)
		keys += 1
	end
	for i,v in pairs(current_History) do
		table.insert(new_list,v)
		keys += 1
	end

	return new_list,keys -- returns the new list with player keys that must be saved
end

--[[
	// Ucall Wraps;
	Error troubleshooting and fixing
--]]

--local Usr_Dat_success, Usr_Dat_message = pcall(module:GetUserData)
--if not Usr_Dat_success then
--	print("Http Request failed:", Usr_Dat_message)
--end

return module


