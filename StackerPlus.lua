--[[ unload if its already loaded... sigh. ]]
if getgenv().StackerUnloadMe then
	getgenv().StackerUnloadMe()
end


--[[ SERVICES (wow theres so many) ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--[[ AUTISM ]]
local function RequireClient(ModuleName)
	local Module = ReplicatedStorage.Client:FindFirstChild(ModuleName, true)
	assert(Module, "fuck you nigga")

	if Module then
		return require(Module)
	end
end

local function RequireShared(ModuleName)
	local Module = ReplicatedStorage.Shared:FindFirstChild(ModuleName, true)
	assert(Module, "fuck you nigga")

	if Module then
		return require(Module)
	end
end

local Settings = RequireClient("Stores").SettingsStore.store:getState().Game -- too long, in the future redo.
local PlacementController = RequireClient("NewPlacementController")
local Hotkey = RequireClient("HotKey")


--[[ FUCKASS INIT ]]
Settings.Stack = "Tab"
Settings.Max = "LeftControl"

PlacementController.Stack = false
PlacementController.Max = false


--[[ HOOKING AND STUFF ]]
local SharedGameFunctions = RequireShared("SharedGameFunctions")
local OriginalCheckTowerCollisions = SharedGameFunctions.CheckTowerCollisions

local Network = debug.getupvalue(PlacementController.Start, 24) -- sigh.
local OldInvokeServer = Network.InvokeServer


SharedGameFunctions.CheckTowerCollisions = function(...)
	local Args = {...}
	local MousePos = Args[2]

	local Result, Info = OriginalCheckTowerCollisions(...)

	if PlacementController.Stack == true then
		if Info then
			return true, {
				Position = MousePos + Vector3.new(0, 7, 0)
			}
		end
	end

	return Result, Info
end


Network.InvokeServer = function(self, ...)
	local Args = {...}
	if Args[1] == "Pl\208\176ce" then
		local Tower = OldInvokeServer(self, unpack(Args))
		if Tower and PlacementController.Max == true then
			if PlacementController.QuickPlacing == false then
				PlacementController.Max = false
			end
			for i=1, 6 do
				task.spawn(function()
					local Event = game:GetService("ReplicatedStorage").RemoteFunction
					Event:InvokeServer(
						"Troops",
						"Upgrade",
						"Set",
						{
							Troop = Tower,
							Path = 1
						}
					)
				end)
			end
		end

		return Tower
	end

	return OldInvokeServer(self, ...)
end


local Index = #debug.getupvalues(PlacementController.Start) - 1
local Actions = debug.getupvalue(PlacementController.Start, Index)

local ExpandedActions = table.clone(Actions)
ExpandedActions["Stack"] = {
	["Key"] = Enum.KeyCode.Tab,
	["ActionText"] = "Stack",
	["Layout"] = 5,
	["ScaleMultiplier"] = 0.4
}
ExpandedActions["Max"] = {
	["Key"] = Enum.KeyCode.LeftControl,
	["ActionText"] = "Max",
	["Layout"] = 6,
	["ScaleMultiplier"] = 0.4
}

debug.setupvalue(PlacementController.Start, Index, ExpandedActions)



local OriginalStart = PlacementController.Start
local Maid = debug.getupvalue(OriginalStart, 7) -- Module

PlacementController.Start = function(...)
	local Stacking = Hotkey.new("Stack")

	Stacking.Pressed:Connect(function(Holding)
		PlacementController.Stack = Holding
	end)

	local Maxing = Hotkey.new("Max")

	Maxing.Pressed:Connect(function(Holding)
		PlacementController.Max = Holding
	end)

	OriginalStart(...)

	Maid:Mark(function()
		Stacking:Destroy()
		PlacementController.Stack = false
		Maxing:Destroy()
	end)
end


getgenv().StackerUnloadMe = function()
	PlacementController.Start = OriginalStart
	
	Settings.Stack = nil
	Settings.Max = nil

	PlacementController.Stack = nil
	PlacementController.Max = nil
	
	Network.InvokeServer = OldInvokeServer
	SharedGameFunctions.CheckTowerCollisions = OriginalCheckTowerCollisions
	
	debug.setupvalue(PlacementController.Start, Index, Actions)
	
	getgenv().StackerUnloadMe = nil
end
