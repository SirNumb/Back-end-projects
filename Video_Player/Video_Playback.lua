--// God i'd recommend using something else as this is just a quick implementation on roblox and it isnt necesarily the quickest. "sir_numb"

local Video_Container = require(game.ReplicatedStorage.Video_Container)
--local TestVideo = require(script.Parent.Parent.Test_Video)
local Hex_Baked_Dictionary = require(game.ReplicatedStorage.Hex_Bake_Dictionary)
local Hex_Dictionary = require(game.ReplicatedStorage.Hex_Dictionary)
local Play_Video_Event = game.ReplicatedStorage.PlayLoadedVid
--local VideoScreen = script.Parent.VideoScreen.Video_Frame
local VideoScreen = game.Workspace.Canvas
local Screen_Pixels = {}

local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local Accumulated = 0

local Loaded_Vid = {}

local Test_Vid = {}

--// Video Resolution
local x_res = 128
local y_res = 74
local pixel_size = 1
local chunk_size = 60

local white_color = Color3.fromRGB(255, 255, 255)
local black_color = Color3.fromRGB(0, 0, 0)

game.ReplicatedStorage.LoadClientVideo.OnClientEvent:Connect(function(data)
	if data == nil then
		Loaded_Vid = {}
	else
		table.insert(Loaded_Vid,data)
	end	
end)
game.ReplicatedStorage.SetChunks.OnClientEvent:Connect(function(chunks)
	chunk_size = tonumber(chunks)
end)

-- white and black
--Play_Video_Event.Event:Connect(function()
--	print("playing video soon")
--	wait(1)
--	game.Workspace.Sound:Play()
--	local frames = 0
--	local chunks = 0
--	for _,v in pairs(Loaded_Vid) do
--		chunks += 1
--		local chunk = tostring(chunks)
--		local pixel = 0
--		for f = 1 , chunk_size do
--			frames += 1
--			local collums = 0
--			local frame = tostring(frames)
--			local current_frame = v[chunk][frame]
--			for i = 1 , x_res do
--				collums += 1
--				local collum = tostring(collums) -- number to string
--				for c in string.gmatch(current_frame[collum], "(%w)") do -- 'w' represents the individual letter returned
--					pixel += 1
--					if pixel == 6913 then
--						pixel = 1
--					end
--					if c == "0" then
--						VideoScreen[collum][pixel].Color = black_color
--					else
--						VideoScreen[collum][pixel].Color = white_color
--					end
--				end
--			end
--			RunService.Heartbeat:Wait()
--			RunService.Heartbeat:Wait()
--			RunService.Heartbeat:Wait()
--			RunService.Heartbeat:Wait()
--		end
--	end
--end)


Play_Video_Event.OnClientEvent:Connect(function()
	print("playing video soon")
	wait(1)
	game.Workspace.Sound:Play()
	local frames = 0
	local chunks = 0
	for _,v in pairs(Loaded_Vid) do
		chunks += 1
		local chunk = tostring(chunks)
		for f = 1 , chunk_size do
			frames += 1
			local pixel = 0
			local collums = 0
			local frame = tostring(frames)
			local current_frame = v[chunk][frame]
			for i = 1 , x_res do
				collums += 1
				local collum = tostring(collums) -- number to string
				local r = 0
				local g = 0
				local b = 0
				local instrunction = false
				local current = 0
				if current_frame[collum] ~= nil then
					for c in string.gmatch(current_frame[collum], ".") do -- 'w' represents the individual letter returned
						current += 1
						if instrunction == true then
							if current == 1 then
								-- do nothing as it started the instruction
							elseif current == 2 then
								g = Hex_Dictionary[c]
								current = 0
								instrunction = false
								pixel += g
							end
						elseif c == "x" then
							current = 0
							pixel += 1
						elseif c == "*" then
							instrunction = true	
						else
							if current == 1 then
								r = Hex_Baked_Dictionary[c]
								-- checks if the frame must be skipped
							elseif current == 2 then
								g = Hex_Baked_Dictionary[c]
							else
								b = Hex_Baked_Dictionary[c]
								current = 0
								pixel += 1
								local color = Color3.fromRGB(r,g,b)
								VideoScreen[collum][pixel].Color = color
							end
						end
					end
				end
				--RunService.Heartbeat:Wait()
			end
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()
		end
	end
end)


--if c ~= "x" then
--	if current == 1 then
--		r = Hex_Baked_Dictionary[c]
--		-- checks if the frame must be skipped
--	elseif current == 2 then
--		g = Hex_Baked_Dictionary[c]
--	elseif current == 3 then
--		b = Hex_Baked_Dictionary[c]
--		current = 0
--		pixel += 1
--		local color = Color3.fromRGB(r,g,b)
--		VideoScreen[collum][pixel].Color = color
--	end
--elseif c == "*" then
--	-- sequence skip started
--	-- keeps the current but r will be 0
--	-- current 2 will have the skips
--	-- current 3 will be noticed and if it is x it will skip
--else
--	if current == 1 then
--		current = 0
--		pixel += 1
--	elseif current == 3 then
--		if r == 0 then
--			print("skipping pixel")
--			current = 0
--			pixel = pixel + g
--		end
--	end
--end
