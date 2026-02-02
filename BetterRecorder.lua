



local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")


local StateFolder = ReplicatedStorage:WaitForChild("State")
local StateReplicators = ReplicatedStorage:WaitForChild("StateReplicators")

local StateModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("GameState"))

local TowerIndex = 0

StateFolder:WaitForChild("Map")
StateFolder:WaitForChild("Difficulty")
StateFolder:WaitForChild("Mode")
StateFolder:WaitForChild("Timer")

local function SaveText(...)
	local Name = getgenv().StratName and getgenv().StratName or LocalPlayer.Name.."'s Strat"

	local TextParts = {...}
	for i, v in ipairs(TextParts) do
		if type(v) ~= "string" then
			TextParts[i] = tostring(v)
		end
	end
	local Text = table.concat(TextParts, " ") .. "\n"

	local Path = `{Name}.txt`

	if isfile(Path) then
		appendfile(Path, Text)
	else
		writefile(Path, Text)
	end

	warn(Text)
end

local FunctionTranslators = {
	["Pl\208\176ce"] = function(Args, RemoteCheck)
		if typeof(RemoteCheck) ~= "Instance" then return end

		local Position = Args[3].Position

		local PositionString = `{Position.X}, {Position.Y}, {Position.Z}`

		SaveText(`TDS:Place("{Args[4]}", {PositionString})`)

		TowerIndex = TowerIndex + 1
		RemoteCheck:SetAttribute("Index", TowerIndex)
	end,

	["Upgrade"] = function(Args, RemoteCheck)
		local TowerIndex = Args[4].Troop:GetAttribute("Index");
		local PathTarget = Args[4].Path
		if not RemoteCheck then
			return
		end
		SaveText(`TDS:Upgrade({TowerIndex}{PathTarget == 1 and "" or ", "..PathTarget})`)
	end,

	["Sell"] = function(Args, RemoteCheck)
		local TowerIndex = Args[3].Troop:GetAttribute("Index");
		if not RemoteCheck then
			return
		end
		SaveText(`TDS:Sell({TowerIndex})`)
	end,

	["Target"] = function(Args, RemoteCheck)
		local TowerIndex = Args[4].Troop:GetAttribute("Index")
		local Target = Args[4].Target
		if not RemoteCheck then
			return
		end
		SaveText(`TDS:SetTarget({TowerIndex}, "{Target}")`)
	end,

	["Skip"] = function(Args, RemoteCheck, Timer)
		if StateModule.Wave == 0 then
			return
		end
		SaveText(`TDS:PreciseSkip({StateModule.Wave}, {Timer})`)
	end,
	
	["Abilities"] = function(Args, RemoteCheck)
		local TowerIndex = Args[4].Troop:GetAttribute("Index")
		local AbilityName = Args[4].Name
		local Data = Args[4].Data

		if RemoteCheck ~= true then
			return
		end
		
		if AbilityName == "Hologram Tower" then
			local TowerToClone = Data.towerToClone:GetAttribute("Index")
			local TowerPosition = Data.towerPosition
			
			Data = string.format("{towerToClone = %s, towerPosition = {Vector3.new(%s)}}",
				TowerToClone,
				tostring(TowerPosition)
			)
		else
			local FormattedData = "{"
			for Index, Value in next, Data do
				if typeof(Value) == "CFrame" then
					Value = `CFrame.new({tostring(Value)})`
				elseif typeof(Value) == "Vector3" then
					Value = `Vector3.new({tostring(Value)})`
				else
					Value = tostring(Value)
				end
				FormattedData = FormattedData .. string.format('["%s"] = %s, ', tostring(Index), Value)
			end
			Data = FormattedData:gsub(", $", "") .. "}"
		end
		
		SaveText(`TDS:Ability({TowerIndex}, "{AbilityName}", {Data})`)
	end,

	["Option"] = function(Args, RemoteCheck)
		local TowerIndex = Args[4].Troop:GetAttribute("Index")
		local OptionName = Args[4].Name
		local Value = Args[4].Value

		if RemoteCheck ~= true then
			return
		end

		SaveText(`TDS:SetOption({TowerIndex}, "{OptionName}", "{Value}")`)
	end,
	
	["Equip"] = function(Args, RemoteCheck)
		local IsTower = Args[3] == "tower"

		if IsTower then
			local Tower = Args[4]
			SaveText(`TDS:Equip("{Tower}")`)
		end
	end,
	
	["Unequip"] = function(Args, RemoteCheck)
		local IsTower = Args[3] == "tower"

		if IsTower then
			local Tower = Args[4]
			SaveText(`TDS:Unequip("{Tower}")`)
		end
	end,
	
	["TowerServerEvent"] = function(Args, RemoteCheck)
		local Type = Args[3]
		
		if RemoteCheck ~= true then
			return
		end
		
		if Type == "ToggleSelectedTower" then
			local Medic = Args[4]:GetAttribute("Index")
			local SelectedTower = Args[5]:GetAttribute("Index")
			
			if Medic and SelectedTower then
				SaveText(`TDS:MedicSelect({Medic}, {SelectedTower})`)
			end
		end
	end,
}



local Towers = RemoteFunction:InvokeServer("Session", "Search", "Equipped.Troops")

for i=1, 5 do
	local Tower = Towers[i]
	if not Tower then
		Towers[i] = "None"
	end
end


local ModifierReplicator = StateReplicators:FindFirstChild("ModifierReplicator")
local Modifiers = ""

if ModifierReplicator then
	local Votes = ModifierReplicator:GetAttribute("Votes")
	if type(Votes) == "string" then
		local CleanedJSON = Votes:match("{.*}") 

		local Success, ModifierVotes = pcall(function()
			return HttpService:JSONDecode(CleanedJSON)
		end)

		if Success and type(ModifierVotes) == "table" then
			local StringModifiers = {}
			for Modifier, _ in pairs(ModifierVotes) do
				warn(Modifier)
				table.insert(StringModifiers, Modifier .. " = true")
			end
			Modifiers = table.concat(StringModifiers, ", ")
		end
	end
end

warn(Modifiers)


SaveText(string.format([[
local TDS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Library.lua"))()

TDS:Loadout("%s", "%s", "%s", "%s", "%s")
TDS:Mode("%s")
TDS:GameInfo("%s", {%s})




-- SUPER TERRIBLE CUSTOM FUNCTIONS BELOW! --

local Logger = getupvalues(TDS.Upgrade)[2] -- holy shit

--DUXI IF YOURE READING THIS 
--PLEASE ADD TDS.Logger TO THE
--API SO WE CAN DO STUFF LIKE:

--TDS.Logger:Log("wow i make custom log")





local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("GameState"))

local StateReplicators = ReplicatedStorage:WaitForChild("StateReplicators")
local StateFolder = ReplicatedStorage:WaitForChild("State")
local Timer = StateFolder:WaitForChild("Timer"):WaitForChild("Time")

local Player = game:GetService("Players").LocalPlayer


local function GetTowerByIndex(Index)
	return TDS.placed_towers[Index]
end

function TDS:PreciseSkip(WaveToSkip, Time)
	task.spawn(function()
		local CurrentWave = StateModule.Wave

		local CurrentTime = Timer.Value

		local SkipDone = false
		while not SkipDone do
			CurrentTime = Timer.Value

			if StateModule.Wave == WaveToSkip and CurrentTime <= Time then
				while true do
					local Success = pcall(function()
						ReplicatedStorage.RemoteFunction:InvokeServer("Voting", "Skip")
					end)
					if Success then break end
					task.wait(0.2)
				end
				SkipDone = true
				Logger:Log(`Voted to skip Wave {WaveToSkip} at {CurrentTime} seconds`)
			else
				if StateModule.Wave > WaveToSkip then
					Logger:Log(`Cancel skipping vote for Wave {WaveToSkip}`)
					break 
				end
				task.wait(0.5)
			end
		end
	end)
end

function TDS:Unequip(Tower)
	local Result = false
	while not Result do 
		Result = ReplicatedStorage.RemoteFunction:InvokeServer(
			"Inventory",
			"Unequip",
			"tower",
			Tower
		)
		task.wait()
	end
end

function TDS:MedicSelect(MedicIndex, SelectedTowerIndex)
	local Medic = GetTowerByIndex(MedicIndex)
	local SelectedTower = GetTowerByIndex(SelectedTowerIndex)
	
	while not Medic and not SelectedTower do
		Medic = GetTowerByIndex(MedicIndex)
		SelectedTower = GetTowerByIndex(SelectedTowerIndex)
	end
	
	local Result = false
	
	while not Result do
		Result = ReplicatedStorage.RemoteFunction:InvokeServer(
			"Troops",
			"TowerServerEvent",
			"ToggleSelectedTower",
			Medic,
			SelectedTower
		)
	end
end

-- END OF CUSTOM FUNCTION SHIT! --



]], Towers[1], Towers[2], Towers[3], Towers[4], Towers[5], StateFolder.Difficulty.Value, StateFolder.Map.Value, Modifiers))


local OldNamecall
OldNamecall = hookmetamethod(game, '__namecall', function(...)
	local Self, Args = (...), ({select(2, ...)})
	local Method = getnamecallmethod()
	if Method == "InvokeServer" and Self.name == "RemoteFunction" then
		local Thread = coroutine.running()
		coroutine.wrap(function(Args)
			local Timer = StateFolder.Timer.Time.Value
			local RemoteFired = Self.InvokeServer(Self, unpack(Args))
			if FunctionTranslators[Args[2]] then
				FunctionTranslators[Args[2]](Args, RemoteFired, Timer)
			end
			coroutine.resume(Thread, RemoteFired)
		end)(Args)
		return coroutine.yield()
	elseif Method == "FireServer" and FunctionTranslators[Self.name] then
		local Function = FunctionTranslators[Self.name] or FunctionTranslators[Args[1]] or FunctionTranslators[Args[2]]
		if Function then
			Function(Args)
		end
	end
	return OldNamecall(..., unpack(Args))
end)

