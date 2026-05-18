	repeat task.wait() until game:IsLoaded()

	-- Load MacLib
	local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/biggaboy212/Public-Resources/main/MacLib/maclib.lua"))()
	MacLib.Folder = "AutoFarm"

	-- Services
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local VIM = game:GetService("VirtualInputManager")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")

	-- QTE modules
	local v3 = game:GetService("ReplicatedStorage")
	local u5 = require(v3.Modules.Communication.Network)
	local u4 = require(game.Players.LocalPlayer.PlayerScripts.Client.CoreMechanics.QTE)


	-- State
	local DEV_MODE = true
	local mainLocked = not DEV_MODE
	local sellEnabled = false
	local sellRunning = false
	local merchantOpen = false
	local autoFavEnabled = false
	local autoFavRarityEnabled = false
	local selectedUnfavRarities = {}
	local legitDigEnabled = false
	local fastLegitDigEnabled = false
	local mythicDigEnabled = false
	local mythicDigMoving = false
	local mythicPrevLineRot = nil
	local mythicDigClickConn = nil
	local mythicDigLoopConn = nil
	local autoDebrisEnabled = false
	local debrisReturnPos = nil
	local debrisActive = false
	local completedDebris = {}
	local autoRerollEnabled = false
	local selectedRerollTool = nil
	local selectedShells = {}
	local selectedRarities = {}
	local selectedUnfavShells = {}
	local selectedUnfavRarities = {}
	local selectedMerchantItems = {}
	local autoBuyEnabled = false
	local guiVisible = true
	local autoClaimEnabled = false
	local autoUpgradeLuck = false
	local autoUpgradeSpeed = false
	local autoUpgradeSpace = false
	local autoUpgradeWeight = false
	local sellWhenFullEnabled = false
	local sellWhenFullRunning = false
	local CONFIG_FILE = "sobatkerang_config.json"
	local autoGiftEnabled = false
	local autoGiftNonFavEnabled = false
	local autoGiftRunning = false
	local autoGiftNonFavRunning = false
	local selectedGiftRarities = {}


	-- Sell NPC position
	local sellNpcPos = Vector3.new(84.78, 42.05, 15.16)

	-- Legit dig internal state
	local qteLineMoving = false
	local prevLineRot = nil
	local qteAutoClickConn = nil

	local allShells = {
	"Aether Harp", "Aurora Carrier", "Babylon", "Barnacle Cluster", "Bay Scallop",
	"Clam", "Cloud Nerite", "Common cockle", "Conch", "Conus Glaucus", "Cowrie",
	"Crystal Helmet", "Divine Volute", "Dubious Volute", "Eclipse Turritella", "Imperialis Delphinus",
	"Lightning Whelk", "Marlin Spike", "Measled Cowrie", "Mitra Mitra",
	"Mitra Stictica", "Moonshale Murex", "Murex Pecten",
	"Mussel", "Nautilus Shell", "Nobilis Volute", "Noble Scallop", "Obelisk Triton",
	"Paua Abalone", "Sand Dollar", "Sea Glass", "Skyspire Turbinidae", "Starfish",
	"Stellar Limpet", "Sun Shard", "Sundial", "Trumpet Shell",
	"Turbo Trocus", "Tusk Shell", "Volva Volva","Vortex Whorl",
	"Wentletrap Snail", "White Abalone", "Worm Snail", "Zephyr Auger",
	}

	local shellRarities = {

		-- Common
		["Bay Scallop"] = "Common",
		["Common cockle"] = "Common",
		["Barnacle Cluster"] = "Common",

		-- Uncommon
		["Noble Scallop"] = "Uncommon",
		["Sea Glass"] = "Uncommon",
		["Cowrie"] = "Uncommon",
		["Dubious Volute"] = "Uncommon",
		["Sundial"] = "Uncommon",
		["Clam"] = "Uncommon",
		["Babylon"] = "Uncommon",
		["Volva Volva"] = "Uncommon",
		["Sand Dollar"] = "Uncommon",

		-- Rare
		["Conch"] = "Rare",
		["Nautilus Shell"] = "Rare",
		["Mitra Mitra"] = "Rare",
		["Mitra Stictica"] = "Rare",
		["Measled Cowrie"] = "Rare",
		["Conus Glaucus"] = "Rare",
		["Tusk Shell"] = "Rare",
		["Marlin Spike"] = "Rare",
		["Starfish"] = "Rare",
		["Trumpet Shell"] = "Rare",
		["Moonshale Murex"] = "Rare",
		["Zephyr Auger"] = "Rare",

		-- Epic
		["Cloud Nerite"] = "Epic",
		["Stellar Limpet"] = "Epic",
		["Aether Harp"] = "Epic",

		-- Legendary
		["Mussel"] = "Legendary",
		["Nobilis Volute"] = "Legendary",
		["Wentletrap Snail"] = "Legendary",
		["Obelisk Triton"] = "Legendary",
		["Skyspire Turbinidae"] = "Legendary",
		["Aurora Carrier"] = "Legendary",
		["Lightning Whelk"] = "Legendary",

		-- Mythic
		["Worm Snail"] = "Mythic",
		["Turbo Trocus"] = "Mythic",
		["Crystal Helmet"] = "Mythic",
		["Vortex Whorl"] = "Mythic",
		["Eclipse Turritella"] = "Mythic",
		["Divine Volute"] = "Mythic",
		["Murex Pecten"] = "Mythic",

		-- Exotic
		["Sun Shard"] = "Exotic",
		["Imperialis Delphinus"] = "Exotic",
	}

	local rarityList = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Exotic",
		"New Shells"
	}

	local allRerollTools = {
		"Driftwood Stick",
		"Starter Sifter",
		"Rusted Sifter",
		"Steel Sifter",
		"Bronze Sifter",
		"Silver Sifter",
		"Gold Sifter",
		"Rapid Sifter",
		"Blitz Sifter",
		"Simple Tideclaw",
		"Coral Tideclaw",
		"RGB Tideclaw",
		"Frosted Tideclaw",
		"Crystal Tideclaw",
		"Energy Tideclaw",
		"Aurora Tideclaw",
		"Haunted Tideclaw",
		"Blood Tideclaw",
		"Solar Tideclaw",
		"Abyssal Tideclaw",
		"Brineblossom",
		"Sanctum Tideclaw",
		"Sunveil Tideclaw",
		"Helios Sunspace",
		"Aether Tideclaw",
		"Selendris Sceptre",
		"Divine Tideclaw",
		"Lunar Tideclaw",
		"Galactic Tideclaw",
		"Dev Tideclaw",
	}

	local islands = {
		["Solmere"]           = Vector3.new(-1570, 28.9, -1733.25),
		["Caldera Cay"]       = Vector3.new(1650, 25, -1428),
		["Sea Stacks Island"] = Vector3.new(971, 26, 1398),
		["Crescent Shore"]    = Vector3.new(-1406, 35, 1570),
		["Spawn Island"]      = Vector3.new(71, 41, 42),
		["Sacred Mountain"] = Vector3.new(3076, 259, 668),
		["Sky Island"] = Vector3.new(119, 3083, 1265),
	}

	local npcs = {
		["Lost NPC"]       = Vector3.new(1798, 62, -1619),
		["Crab Bossfight"] = Vector3.new(-1365, 25, -1562),
		["Tinkerer"]       = Vector3.new(107, 46, 56),
		["Sarah"]          = Vector3.new(83, 35, 102),
		["Boat NPC"]       = Vector3.new(26, 22, 192),
		["Merchant"]       = Vector3.new(84, 42, 9),
		["Backpack NPC"]   = Vector3.new(0, 52, -2),
		["Old Fisherman"]  = Vector3.new(55, 24, 260),
		["Ghost"]          = Vector3.new(156, 124, -73),
		["Shady NPC"]      = Vector3.new(222, 330, -58),
		["Georgie"]        = Vector3.new(906, 28, 1452),
		["Maxwell"]        = Vector3.new(884, 26, 1358),
		["Hermulese"]      = Vector3.new(-1358, 25, -1569),
		["Biologist"]      = Vector3.new(-1453, 38, 1582),
		["Oro"]            = Vector3.new(-1413, 35, 1549),
		["Psychic"]        = Vector3.new(-1483, 38, 1512),
		["Keeper Nyros"] = Vector3.new(67, 3093, 1420),
		["Ardyn"] = Vector3.new(-56, 3136, 1322),
		["Keeper Solen"] = Vector3.new(2780, 64, 454),
		["Elder Kaelen"] = Vector3.new(2705, 36, 398),
	}

	local merchantItems = {
		["Abyssal Charm"]   = "#\r\000Abyssal Charm",
		["Colossus Charm"]  = "#\014\000Colossus Charm",
		["Coral Charm"]     = "#\v\000Coral Charm",
		["Crystal Charm"]   = "#\r\000Crystal Charm",
		["Driftwood Charm"] = "#\015\000Driftwood Charm",
		["Eclipse Charm"]   = "#\r\000Eclipse Charm",
		["Leviathan Charm"] = "#\015\000Leviathan Charm",
		["Moonstone Charm"] = "#\015\000Moonstone Charm",
		["Pebble Charm"]    = "#\f\000Pebble Charm",
		["Prism Charm"]     = "#\v\000Prism Charm",
		["Sea Glass Charm"] = "#\015\000Sea Glass Charm",
		["Starfish Charm"]  = "#\014\000Starfish Charm",
		["Tidal Charm"]     = "#\v\000Tidal Charm",
		["Tide Charm"]      = "#\n\000Tide Charm",
		["Void Charm"]      = "#\n\000Void Charm",
	}

	local islandNames = {}
	for name in pairs(islands) do table.insert(islandNames, name) end

	local npcNames = {}
	for name in pairs(npcs) do table.insert(npcNames, name) end

	local merchantItemNames = {}
	for name in pairs(merchantItems) do table.insert(merchantItemNames, name) end
	table.sort(merchantItemNames)

	local selectedIsland = islandNames[1]
	local selectedNpc = npcNames[1]
	local function saveConfig()

		if not writefile then
			return
		end

		local merchantList = {}

		for itemName, enabled in pairs(selectedMerchantItems) do
			if enabled then
				table.insert(merchantList, itemName)
			end
		end

		local data = {
			autoBuyEnabled = autoBuyEnabled,
			autoClaimEnabled = autoClaimEnabled,
			selectedMerchantItems = merchantList,
		}

		local success, encoded = pcall(function()
			return HttpService:JSONEncode(data)
		end)

		if success then
			writefile(CONFIG_FILE, encoded)
		else
			Window:Notify({
				Title = "Config Error",
				Description = "Failed to encode config!",
				Lifetime = 5
			})
		end
	end

	local function loadConfig()

		if not readfile
		or not isfile
		or not isfile(CONFIG_FILE) then
			return
		end

		local success, data = pcall(function()
			return HttpService:JSONDecode(
				readfile(CONFIG_FILE)
			)
		end)

		if success and data then

			autoBuyEnabled =
				data.autoBuyEnabled or false

			autoClaimEnabled =
				data.autoClaimEnabled or false

			selectedMerchantItems = {}

	for _, itemName in ipairs(data.selectedMerchantItems or {}) do
		selectedMerchantItems[itemName] = true
	end
		end
	end

	-- Create Window
	local Window = MacLib:Window({
		Title = "🌸 Sobat Kerang 🌸",
		Subtitle = "Puja Kerang Ajaib!",
		Size = UDim2.fromOffset(868, 650),
		DragStyle = 2,
		AcrylicBlur = true,
		Keybind = Enum.KeyCode.LeftControl,
	})


	-- ============================================================
	-- MOBILE TOGGLE BUTTON
	-- ============================================================
	local mobileGui = Instance.new("ScreenGui")
	mobileGui.Name = "FluentMobileToggle"
	mobileGui.ResetOnSpawn = false
	mobileGui.DisplayOrder = 999
	mobileGui.IgnoreGuiInset = true
	mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	pcall(function()
		mobileGui.Parent = game:GetService("CoreGui")
	end)
	if not mobileGui.Parent or mobileGui.Parent ~= game:GetService("CoreGui") then
		mobileGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local function getViewport()
		local cam = workspace.CurrentCamera

		if cam then
			return cam.ViewportSize
		end

		return Vector2.new(1920, 1080)
	end
	local btnSize = 60
	local startX = 20
	local viewport = getViewport()

	local startY = math.floor(viewport.Y / 2) - 30
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleBtn"
	toggleBtn.Size = UDim2.fromOffset(btnSize, btnSize)
	toggleBtn.Position = UDim2.new(0, startX, 0, startY)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.Text = "🌸"
	toggleBtn.TextSize = 26
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.BorderSizePixel = 0
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 10
	toggleBtn.Parent = mobileGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = toggleBtn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 120, 220)
	stroke.Thickness = 2
	stroke.Parent = toggleBtn

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 50)),
	})
	grad.Rotation = 135
	grad.Parent = toggleBtn

	local function findMacLibGui()
		local coreGui = game:GetService("CoreGui")
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		for _, name in ipairs({"AutoFarm", "MacLib", "Fluent"}) do
			local g = coreGui:FindFirstChild(name) or playerGui:FindFirstChild(name)
			if g then return g end
		end
		for _, g in ipairs(coreGui:GetChildren()) do
			if g:IsA("ScreenGui")
			and (
				g.Name:find("MacLib")
				or g.Name:find("Fluent")
				or g:FindFirstChild("Main", true)
			) then
				return g
		end
	end
		for _, g in ipairs(playerGui:GetChildren()) do
			if g:IsA("ScreenGui")
			and (
				g.Name:find("MacLib")
				or g.Name:find("Fluent")
				or g:FindFirstChild("Main", true)
			) then
				return g
		end
	end
		return nil
	end

	local function setGuiVisible(visible)
		guiVisible = visible

		stroke.Color = visible
			and Color3.fromRGB(180, 120, 220)
			or Color3.fromRGB(100, 100, 120)

		local g = findMacLibGui()

		if g then
			pcall(function()
				g.Enabled = visible
			end)

			pcall(function()
				g.Visible = visible
			end)
		end
	end

	local dragging = false
	local dragInput = nil
	local dragStartPos = nil
	local btnStartOffset = nil
	local tapStartPos = nil
	local TAP_THRESHOLD = 10

	local function updateDrag(input)
		local delta = input.Position - dragStartPos
		local vp = getViewport()

		local newX = math.clamp(
			btnStartOffset.X + delta.X,
			0,
			vp.X - btnSize
		)

		local newY = math.clamp(
			btnStartOffset.Y + delta.Y,
			0,
			vp.Y - btnSize
		)

		toggleBtn.Position = UDim2.new(0, newX, 0, newY)
	end

	toggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStartPos = input.Position
		tapStartPos = input.Position
		btnStartOffset = Vector2.new(toggleBtn.Position.X.Offset, toggleBtn.Position.Y.Offset)

		local changedConn

		changedConn = input.Changed:Connect(function()

			if input.UserInputState == Enum.UserInputState.End then
				dragging = false

				if changedConn then
					changedConn:Disconnect()
					changedConn = nil
				end
			end
		end)
	end
	end)

	toggleBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and dragInput and input == dragInput then updateDrag(input) end
	end)

	toggleBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if tapStartPos then
				local moved = (input.Position - tapStartPos).Magnitude
				if moved < TAP_THRESHOLD then
					setGuiVisible(not guiVisible)
					local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					local originalPos = toggleBtn.Position

	local targetSize = guiVisible
		and UDim2.fromOffset(60, 60)
		or UDim2.fromOffset(52, 52)

	TweenService:Create(toggleBtn, tweenInfo, {
		Size = targetSize,
		Position = originalPos
	}):Play()
				end
			end
			tapStartPos = nil
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftControl and not gameProcessed then
			task.delay(0.05, function()
				local g = findMacLibGui()
				if g then
					guiVisible = g.Enabled
					stroke.Color = guiVisible and Color3.fromRGB(180, 120, 220) or Color3.fromRGB(100, 100, 120)
				end
			end)
		end
	end)
	-- ============================================================

	-- Tab Groups & Tabs
	local TabGroup = Window:TabGroup()

	local Tabs = {
		Profile  = TabGroup:Tab({ Name = "Profile" }),
		Main     = TabGroup:Tab({ Name = "Main" }),
		Favorites = TabGroup:Tab({ Name = "Favorites" }),
		Gift = TabGroup:Tab({ Name = "Auto Gift" }),
		Teleport = TabGroup:Tab({ Name = "Teleport" }),
		Merchant = TabGroup:Tab({ Name = "Travelling Merchant" }),
	}

	-- ============================================================
	-- FUNCTIONS
	-- ============================================================

	local function tpTo(pos)
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if hrp then
			hrp.CFrame = CFrame.new(pos)
		end
	end

	local function safeVIMClick()

		pcall(function()

			local cam = workspace.CurrentCamera
			if not cam then
				return
			end

			local cvp = cam.ViewportSize

			local x = cvp.X * 0.8
			local y = cvp.Y * 0.8

			VIM:SendMouseButtonEvent(
				x,
				y,
				0,
				true,
				game,
				0
			)

			task.wait(0.05)

			VIM:SendMouseButtonEvent(
				x,
				y,
				0,
				false,
				game,
				0
			)

		end)
	end	

	-- AUTO GIFT
	local function findGiftPrompt()

    local localPlayer =
        Players.LocalPlayer

    local char =
        localPlayer.Character

    local hrp =
        char
        and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil, nil
    end

    local closestPrompt = nil
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, targetPlayer in ipairs(Players:GetPlayers()) do

        if targetPlayer ~= localPlayer then

            local targetChar =
                targetPlayer.Character

            local targetHRP =
                targetChar
                and targetChar:FindFirstChild("HumanoidRootPart")

            if targetHRP then

                local dist =
                    (hrp.Position - targetHRP.Position).Magnitude

                if dist < 15 then

                    for _, obj in ipairs(targetChar:GetDescendants()) do

					if obj:IsA("ProximityPrompt")
					and tostring(obj.ActionText):find("Interact") then

                            if dist < closestDistance then

                                closestDistance = dist
                                closestPrompt = obj
                                closestPlayer = targetPlayer

                            end
                        end
                    end
                end
            end
        end
    end

    return closestPrompt, closestPlayer
end

	local function triggerGiftPrompt()

		local prompt, targetPlayer =
			findGiftPrompt()

		if prompt then

			pcall(function()

				fireproximityprompt(prompt)

			end)

			return true, targetPlayer
		end

		return false, nil
	end

	local function getShellRarity(shellName)

		for knownShell, rarity in pairs(shellRarities) do

			if shellName:find(knownShell) then
				return rarity
			end
		end

		return "New Shells"
	end

	local function findGiftableShell()

		local backpack =
			Players.LocalPlayer:FindFirstChild("Backpack")

		if not backpack then
			return nil
		end

		for _, item in ipairs(backpack:GetChildren()) do

			if item:IsA("Tool") then

				local rarity =
					getShellRarity(item.Name)

				if selectedGiftRarities[rarity] then
					return item
				end
			end
		end

		return nil
	end

	local function findNonFavoriteShell()

	local backpack =
		Players.LocalPlayer:FindFirstChild("Backpack")

	if not backpack then
		return nil
	end

	for _, item in ipairs(backpack:GetChildren()) do

		if item:IsA("Tool") then

			local fav =
				item:GetAttribute("Favourite")

			if not fav then
				return item
			end
		end
	end

	return nil
	end

local function sendGiftToTarget(playerName)

	pcall(function()

		local lenByte =
			string.char(#playerName)

		local args = {
			buffer.fromstring(
				"\002"
				.. lenByte
				.. "\000"
				.. playerName
			)
		}

		game:GetService("ReplicatedStorage")
			:WaitForChild("ByteNetReliable")
			:FireServer(unpack(args))

	end)
end
		
	local function equipGiftShell(shell)
		
		if not shell then
			return false
		end

		local char =
			Players.LocalPlayer.Character

		local humanoid =
			char
			and char:FindFirstChildOfClass("Humanoid")

		if not humanoid then
			return false
		end

		pcall(function()

			shell.Parent = char

		end)

		task.wait(1)


		return true
	end

	local function startAutoGift()
		if autoGiftRunning then
			return
		end

		autoGiftRunning = true

		task.spawn(function()

			while autoGiftEnabled do

				local shell =
					findGiftableShell()

				if shell then

					local equipped =
						equipGiftShell(shell)

					if equipped then

						task.wait(0.25)

						local triggered, targetPlayer =
						triggerGiftPrompt()

						if triggered then

							task.wait(1)
							if targetPlayer then

							sendGiftToTarget(targetPlayer.Name)

							end

							Window:Notify({
								Title = "Auto Gift",
								Description =
									"Gifted "
									.. shell.Name,
							Lifetime = 3
							})

						end
					end
				end

				task.wait(0.15)

			end
			autoGiftRunning = false
		end)
	end

	-- auto gift non favorite
	local function startAutoGiftNonFavorite()
	if autoGiftNonFavRunning then
	return
	end

	autoGiftNonFavRunning = true

	task.spawn(function()

		while autoGiftNonFavEnabled do

			local shell =
				findNonFavoriteShell()

			if shell then

				local equipped =
					equipGiftShell(shell)

				if equipped then

					task.wait(0.25)

					local triggered, targetPlayer =
						triggerGiftPrompt()

					if triggered then

						task.wait(0.12)

						if targetPlayer then

							sendGiftToTarget(
								targetPlayer.Name
							)

						end

						Window:Notify({
							Title = "Auto Gift",
							Description =
								"Gifted non-favorite: "
								.. shell.Name,

							Lifetime = 2
						})
					end
				end
			end

			task.wait(0.15)

		end
		autoGiftNonFavRunning = false 
	end)
end
	
	local function hasDigTool()
		local char = Players.LocalPlayer.Character

		if not char then
			return false
		end

		for _, obj in ipairs(char:GetChildren()) do
			if obj:IsA("Tool") then
				return true
			end
		end

		return false
	end

	local function normalizeAngle(a) return a % 360 end
	local function angleDiff(a, b)
		local d = math.abs(normalizeAngle(a) - normalizeAngle(b))
		return d > 180 and 360 - d or d
	end

	-- AUTO SELL
	local function startSell()
		if sellRunning then
			return
		end

		sellRunning = true

		task.spawn(function()
			while sellEnabled do
				pcall(function()
					local char = Players.LocalPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")

					local returnPos = hrp and hrp.Position

					tpTo(sellNpcPos)
					task.wait(2.5)

					local args = { buffer.fromstring("9") }

					game:GetService("ReplicatedStorage")
						:WaitForChild("ByteNetReliable")
						:FireServer(unpack(args))

					task.wait(3)

					if returnPos then
						tpTo(returnPos)
					end
				end)

				task.wait(300)

			end

			sellRunning = false
		end)
	end

	-- auto sell when it full
	local function startSellWhenFull()

		if sellWhenFullRunning then
			return
		end

		sellWhenFullRunning = true

		task.spawn(function()

			while sellWhenFullEnabled do

				local inventoryFull = false

				pcall(function()

					for _, gui in pairs(game.Players.LocalPlayer.PlayerGui:GetDescendants()) do

						if gui:IsA("TextLabel")
						and tostring(gui.Text):match("^%d+/%d+$") then

							local current, max =
								gui.Text:match("(%d+)/(%d+)")

							current = tonumber(current)
							max = tonumber(max)

							if current
							and max
							and current >= max then

								inventoryFull = true
								break
							end
						end
					end
				end)

				if inventoryFull then

					pcall(function()

						local char = Players.LocalPlayer.Character
						local hrp =
							char
							and char:FindFirstChild("HumanoidRootPart")

						local returnPos =
							hrp and hrp.Position

						tpTo(sellNpcPos)

						task.wait(2.5)

						local args = {
							buffer.fromstring("9")
						}

						game:GetService("ReplicatedStorage")
							:WaitForChild("ByteNetReliable")
							:FireServer(unpack(args))
					Window:Notify({
					Title = "Auto Sell",
					Description = "Sell packet fired!",
					Lifetime = 3
						})	
						task.wait(3)

						if returnPos then
							tpTo(returnPos)
						end

						Window:Notify({
							Title = "Sell When Full",
							Description = "Inventory full, sold automatically!",
							Lifetime = 4
						})

					end)
				end

				task.wait(2)
			end

			sellWhenFullRunning = false
		end)
	end

	-- AUTO FAVOURITE
	local function favoriteShell(item)
		pcall(function()
			local args = { buffer.fromstring("\003\001\001"), { item } }
			game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
		end)
	end

	local function startAutoFav()
		task.spawn(function()
			while autoFavEnabled do
				local backpack = game.Players.LocalPlayer.Backpack
				for _, item in ipairs(backpack:GetChildren()) do
					if not autoFavEnabled then break end
					for shellName in pairs(selectedShells) do
						if item.Name:find(shellName) then
							favoriteShell(item)
							task.wait(0.05)
						end
					end
				end
				task.wait(1)
			end
		end)
	end

	local function startAutoFavRarity()

		task.spawn(function()

			while autoFavRarityEnabled do

				local backpack =
					game.Players.LocalPlayer.Backpack

				for _, item in ipairs(backpack:GetChildren()) do

					if not autoFavRarityEnabled then
						break
					end

					local matched = false
					local known = false

					for shellName, rarity in pairs(shellRarities) do

						if item.Name:find(shellName) then

							known = true

							if selectedRarities[rarity] then
								matched = true
							end

							break
						end
					end

					-- detect new shells
					if not known
					and selectedRarities["New Shells"] then

						matched = true
					end

					if matched then

						favoriteShell(item)

						task.wait(0.05)
					end
				end

				task.wait(1)
			end
		end)
	end

-- AUTO UNFAVOURITE
	local function unfavoriteShell(item)

	pcall(function()

		local args = {
			buffer.fromstring("\003\001\000"),
			{ item }
		}

		game:GetService("ReplicatedStorage")
			:WaitForChild("ByteNetReliable")
			:FireServer(unpack(args))

	end)
end

local function startAutoUnfavRarity()

	task.spawn(function()

		local unfavCount = 0

		local backpack =
			game.Players.LocalPlayer.Backpack

		for _, item in ipairs(backpack:GetChildren()) do

			local matched = false
			local known = false

			for shellName, rarity in pairs(shellRarities) do

				if item.Name:find(shellName) then

					known = true

					if selectedUnfavRarities[rarity] then
						matched = true
					end

					break
				end
			end

			if not known
			and selectedUnfavRarities["New Shells"] then

				matched = true
			end

			if matched then

				unfavoriteShell(item)

				unfavCount += 1

				task.wait(0.05)
			end
		end

		Window:Notify({
			Title = "Unfavorite Complete",
			Description =
				"Unfavorited "
				.. unfavCount
				.. " shells!",
			Lifetime = 4
		})

	end)
end
	-- LEGIT DIG
	local function startLegitDig()
		local pgui = Players.LocalPlayer.PlayerGui
		local prevDiff = 999
		local clicked = false
		prevLineRot = nil
		qteLineMoving = false

		if qteAutoClickConn then
			qteAutoClickConn:Disconnect()
			qteAutoClickConn = nil
		end
		qteAutoClickConn = RunService.RenderStepped:Connect(function()
			if not legitDigEnabled then
				prevDiff = 999
				clicked = false
				return
			end
			pcall(function()
				local qte = pgui:FindFirstChild("QTE")
				if not qte then prevDiff = 999; clicked = false; qteLineMoving = false; return end
				local main = qte:FindFirstChild("Main")
				if not main then qteLineMoving = false; return end
				local line = main:FindFirstChild("Line")
				local bars = main:FindFirstChild("Bars")
				if not line or not bars then qteLineMoving = false; return end

				local lineRot = line.Rotation
				if prevLineRot ~= nil then
					qteLineMoving = math.abs(lineRot - prevLineRot) > 0.1
				end
				prevLineRot = lineRot

				local targetBar
				for _, bar in pairs(bars:GetChildren()) do
					if bar:IsA("ImageLabel") and bar.Visible then
						targetBar = bar
						break
					end
				end
				if not targetBar then prevDiff = 999; clicked = false; return end

				local diff = angleDiff(lineRot, targetBar.Rotation)
				local barSize = tonumber(targetBar.Name:match("%d+")) or 15

				if not clicked and diff <= barSize / 2 then
					if diff > prevDiff then
						safeVIMClick()
						clicked = true
					end
				end

				if diff > barSize then clicked = false end
				prevDiff = diff
			end)
		end)

		task.spawn(function()
			while legitDigEnabled do
				if not qteLineMoving then
					safeVIMClick()
				end
				task.wait(0.5)
			end
		end)
	end
	local cachedBars = nil

	local fastDigLastClick = 0
	local function startFastLegitDig()
		local pgui = Players.LocalPlayer.PlayerGui

		if qteAutoClickConn then
			qteAutoClickConn:Disconnect()
			qteAutoClickConn = nil
		end

		qteAutoClickConn = RunService.RenderStepped:Connect(function()
			if not fastLegitDigEnabled then
				return
			end

			pcall(function()
				local qte = pgui:FindFirstChild("QTE")
				if not qte then
					cachedBars = nil
					return
				end
				 
				local main = qte:FindFirstChild("Main")
				if not main then
					return
				end

				local line = main:FindFirstChild("Line")
				local bars = main:FindFirstChild("Bars")

				if not line or not bars then
					return
				end
				if cachedBars
				and #cachedBars ~= #bars:GetChildren() then
					cachedBars = nil
				end
				if not cachedBars then
					cachedBars = {}

					for _, obj in ipairs(bars:GetChildren()) do
						if obj:IsA("ImageLabel") then
							table.insert(cachedBars, obj)
						end
					end
				end

				local targetBar

				for i = 1, #cachedBars do
					local bar = cachedBars[i]

					if bar.Visible then
						targetBar = bar
						break
					end
				end

				if not targetBar then
					return
				end

				local diff = angleDiff(
					line.Rotation,
					targetBar.Rotation
				)

				local barSize =
					tonumber(targetBar.Name:match("%d+"))
					or 15

				if diff <= (barSize / 2.5) then
		local now = tick()

		if now - fastDigLastClick > 0.08 then
			fastDigLastClick = now
			safeVIMClick()
		end
	end

			end)
		end)
	task.spawn(function()
		while fastLegitDigEnabled do
	if not hasDigTool() then
		task.wait(0.5)
		continue
	end
			local qte = pgui:FindFirstChild("QTE")

			if qte then
				local main = qte:FindFirstChild("Main")
				local line = main and main:FindFirstChild("Line")

				if line then
					local currentRot = line.Rotation

					if prevLineRot ~= nil then
						qteLineMoving =
							math.abs(currentRot - prevLineRot) > 0.1
					end

					prevLineRot = currentRot

					if not qteLineMoving then
						safeVIMClick()
					end
				else
					safeVIMClick()
				end
			else
				safeVIMClick()
			end

			task.wait(0.5)
		end
	end)
	end
	
	local function cancelDig()

	pcall(function()

		local args = {
			buffer.fromstring("/")
		}

		game:GetService("ReplicatedStorage")
			:WaitForChild("ByteNetReliable")
			:FireServer(unpack(args))

		end)
	end

local function startDig()

	pcall(function()

		local args = {
			buffer.fromstring("\016"),
			[3] = 16
		}

		game:GetService("ReplicatedStorage")
			:WaitForChild("ByteNetQuery")
			:InvokeServer(unpack(args))

	end)
end

	local function stopLegitDig()
		legitDigEnabled = false
		fastLegitDigEnabled = false
		mythicDigEnabled = false

		if qteAutoClickConn then
			qteAutoClickConn:Disconnect()
			qteAutoClickConn = nil
		end

		qteLineMoving = false
		prevLineRot = nil
	end

-- MYTHIC ONLY DIG
local function startMythicDig()

	if mythicDigClickConn then
		mythicDigClickConn:Disconnect()
		mythicDigClickConn = nil
	end

	local pgui = Players.LocalPlayer.PlayerGui
    mythicDigMoving = false
    mythicPrevLineRot = nil
end

local function startMythicDig()
    local pgui = Players.LocalPlayer.PlayerGui
    local prevDiff = 999
    local clicked = false
    local cancelCooldown = false
    mythicPrevLineRot = nil
    mythicDigMoving = false

    mythicDigClickConn = RunService.RenderStepped:Connect(function()
        if not mythicDigEnabled then
            prevDiff = 999
            clicked = false
            return
        end
        pcall(function()
            local qte = pgui:FindFirstChild("QTE")
            if not qte then prevDiff = 999; clicked = false; mythicDigMoving = false; return end
            local main = qte:FindFirstChild("Main")
            if not main then mythicDigMoving = false; prevDiff = 999; clicked = false; return end
            local line = main:FindFirstChild("Line")
            local bars = main:FindFirstChild("Bars")
            if not line or not bars then mythicDigMoving = false; return end

            local lineRot = line.Rotation
            if mythicPrevLineRot ~= nil then
                mythicDigMoving = math.abs(lineRot - mythicPrevLineRot) > 0.1
            end
            mythicPrevLineRot = lineRot

            -- Wait a short time after QTE appears before checking surge
            -- to give the surge frame time to become visible
            if not mythicDigMoving then return end

            -- Check Surge frame visibility to detect mythic
            local surgeFrame = qte:FindFirstChild("Surge")
            local surgeVisible = surgeFrame and surgeFrame.Visible

            -- Always compute diff first so prevDiff is accurate every frame
            local targetBar
            for _, bar in pairs(bars:GetChildren()) do
                if bar:IsA("ImageLabel") and bar.Visible then
                    targetBar = bar
                    break
                end
            end
            if not targetBar then prevDiff = 999; clicked = false; return end

            local diff = angleDiff(lineRot, targetBar.Rotation)
            local barSize = tonumber(targetBar.Name:match("%d+")) or 15

            if not surgeVisible then
                -- Not a mythic — fire cancel remote then cooldown so dig loop waits
                if not cancelCooldown then
                    cancelCooldown = true
                    pcall(function()
                        local args = { buffer.fromstring("/") }
                        game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
                    end)
                    task.delay(2, function()
                        cancelCooldown = false
                        safeVIMClick()
                    end)
                end
                prevDiff = diff
                clicked = false
                mythicDigMoving = false
                return
            end

            -- Surge is visible = mythic! Complete the QTE normally
            -- Click earlier to compensate for ping (~200ms offset)
            local pingOffset = barSize * 0.35
            if not clicked and diff <= (barSize / 2) + pingOffset then
                safeVIMClick()
                clicked = true
                cancelCooldown = false
            end

            if diff > barSize then clicked = false end
            prevDiff = diff
        end)
    end)

    task.spawn(function()
        while mythicDigEnabled do
            if not mythicDigMoving and not cancelCooldown then
                safeVIMClick()
            end
            task.wait(0.2)
        end
    end)
end


	-- AUTO IMPACT DEBRIS
	local function startAutoDebris()

		task.spawn(function()

			while autoDebrisEnabled do

				local debrisList = {}

				for _, v in ipairs(workspace:GetChildren()) do

					if v.Name == "ImpactDebris"
	and not completedDebris[v] then

		table.insert(debrisList, v)
	end
				end

				if #debrisList > 0 then
					if not debrisActive then

					  local char =
					  Players.LocalPlayer.Character

					  local hrp =
					  char
					  and char:FindFirstChild("HumanoidRootPart")

					  if hrp then
					  debrisReturnPos = hrp.Position
					  debrisActive = true
					 end
				end

					local randomDebris =
						debrisList[math.random(1, #debrisList)]

					local char =
						Players.LocalPlayer.Character

					local hrp =
						char
						and char:FindFirstChild("HumanoidRootPart")

					if hrp then

						local cf

						if randomDebris:IsA("BasePart") then

							cf = randomDebris.CFrame

						elseif randomDebris:IsA("Model")
						and randomDebris.PrimaryPart then

							cf = randomDebris.PrimaryPart.CFrame

						else

							local part =
								randomDebris:FindFirstChildWhichIsA("BasePart")

							if part then
								cf = part.CFrame
							end
						end

						if cf then

		hrp.CFrame = cf

		Window:Notify({
			Title = "Auto Debris",
			Description = "Digging debris...",
			Lifetime = 2
		})

		-- wait digging
		task.wait(3)

		-- wait chest spawn
		task.wait(1)

		-- search prompt
local foundPrompt = false
local startTick = tick()

repeat

for _, obj in ipairs(workspace:GetDescendants()) do

	if obj:IsA("ProximityPrompt") then

		local objectText =
			tostring(obj.ObjectText)

		local actionText =
			tostring(obj.ActionText)

		if objectText:find("Moon Gift")
		and actionText:find("Open") then

			foundPrompt = true

			Window:Notify({
				Title = "Auto Debris",
				Description = "Opening reward!",
				Lifetime = 2
			})

			pcall(function()
				fireproximityprompt(obj)
			end)

			task.wait(2)

			completedDebris[randomDebris] = true

if debrisReturnPos then
    tpTo(debrisReturnPos)
end

task.wait(2)

			break
		end
	end
end

    task.wait(0.2)

until foundPrompt
or tick() - startTick > 60

if not foundPrompt then

    Window:Notify({
        Title = "Auto Debris",
        Description = "Moon Gift timeout! Returning...",
        Lifetime = 3
    })

    completedDebris[randomDebris] = true

    if debrisReturnPos then
        tpTo(debrisReturnPos)
    end

    task.wait(2)
end
					end
				end
				end
	if debrisReturnPos then

    local stillExists = false

    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name == "ImpactDebris"
        and not completedDebris[v] then
            stillExists = true
            break
        end
    end

    if not stillExists and debrisActive then

        tpTo(debrisReturnPos)

        Window:Notify({
            Title = "Auto Debris",
            Description = "Returning to previous position!",
            Lifetime = 3
        })

        debrisReturnPos = nil
        debrisActive = false
        completedDebris = {}
    end
end
				task.wait(5)
			end
		end)
	end

	-- HERMIT CRAB
	local function startAutoClaim()
		task.spawn(function()
			while autoClaimEnabled do
				pcall(function()
					local args = { buffer.fromstring("\005"), [3] = 5 }
					game:GetService("ReplicatedStorage"):WaitForChild("ByteNetQuery"):InvokeServer(unpack(args))
				end)
				task.wait(1)
			end
		end)
	end

	local function startAutoUpgrade(getEnabled, bufferStr)
		task.spawn(function()
			while getEnabled() do
				pcall(function()
					local args = { buffer.fromstring(bufferStr), [3] = 9 }
					game:GetService("ReplicatedStorage"):WaitForChild("ByteNetQuery"):InvokeServer(unpack(args))
				end)
				task.wait(1)
			end
		end)
	end

	local function toggleTravellingMerchant()
		local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("TravellingMerchant")
		if not gui then
			Window:Notify({ Title = "Merchant", Description = "Travelling Merchant is not spawned!", Lifetime = 3 })
			return
		end
		local main = gui:WaitForChild("Main")
		local uiScale = main:FindFirstChild("UIScale")
		local ok, guiController = pcall(require, Players.LocalPlayer.PlayerScripts.Client.GuiController)
		if not ok then
			Window:Notify({ Title = "Merchant", Description = "Failed to load GuiController!", Lifetime = 3 })
			return
		end
		if not merchantOpen then
			guiController.OpenGui:Fire("TravellingMerchant")
			main.Visible = true
			if uiScale then guiController.PopIn(uiScale) end
			merchantOpen = true
			Window:Notify({ Title = "Merchant", Description = "Travelling Merchant opened!", Lifetime = 2 })
		else
			guiController.CloseGui:Fire()
			if uiScale then
				guiController.PopOut(uiScale, function() main.Visible = false end)
			else
				main.Visible = false
			end
			merchantOpen = false
			Window:Notify({ Title = "Merchant", Description = "Travelling Merchant closed!", Lifetime = 2 })
		end
	end

	local function purchaseItem(itemName)
		pcall(function()
			local args = { buffer.fromstring(merchantItems[itemName]), [3] = 35 }
			game:GetService("ReplicatedStorage"):WaitForChild("ByteNetQuery"):InvokeServer(unpack(args))
		end)
	end

	local function startAutoBuy()
		task.spawn(function()
			while autoBuyEnabled do
				for itemName in pairs(selectedMerchantItems) do
					if not autoBuyEnabled then break end
					purchaseItem(itemName)
					task.wait(0.5)
				end
				task.wait(1)
			end
		end)
	end

	local function unlockMain()
		mainLocked = false

		loadConfig()
		task.wait(0.2)

		pcall(function()

		autoClaimToggle:Set(autoClaimEnabled)

		autoBuyToggle:Set(autoBuyEnabled)

		merchantDropdown:Set(selectedMerchantItems)

	end)

		if autoClaimEnabled then
			startAutoClaim()
		end

		if autoBuyEnabled then
			startAutoBuy()
		end

		Tabs.Main:Select()
	end

	-- AUTO REROLL TRAIT
	local function startAutoReroll()

		task.spawn(function()

			local pgui =
				Players.LocalPlayer.PlayerGui

			local label

			pcall(function()

				label =
					pgui.Equipment.Main.LeftBar
					.TraitsFrame.PityBar.TrackerLabel

			end)

			local function getPityValue()

				if not label then
					return 0
				end

				local ok, text =
					pcall(function()
						return label.Text
					end)

				if not ok then
					return 0
				end

				local current =
					text:match("(%d+) /")

				return tonumber(current) or 0
			end

			local prevPity = getPityValue()

			while autoRerollEnabled do

				local currentPity =
					getPityValue()

				if currentPity < 1
				and prevPity > 1 then

					autoRerollEnabled = false

					Window:Notify({
						Title = "Auto Reroll",
						Description = "Good trait found! Stopping!",
						Lifetime = 4
					})

					break
				end

				prevPity = currentPity

				pcall(function()

					local toolName =
						selectedRerollTool

					local lenByte =
						string.char(#toolName)

					local args = {
						buffer.fromstring(
							"\030"
							.. lenByte
							.. "\000"
							.. toolName
						),

						[3] = 30
					}

					game:GetService("ReplicatedStorage")
						:WaitForChild("ByteNetQuery")
						:InvokeServer(unpack(args))

				end)

				task.wait(1)

			end
		end)
	end

	-- ============================================================
	-- MAIN TAB
	-- ============================================================
	local MainSection = Tabs.Main:Section({ Side = "Left" })
	local CrabSection = Tabs.Main:Section({ Side = "Right" })

	MainSection:Toggle({
		Name = "Legit Dig",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				legitDigEnabled = false
				return
			end
			legitDigEnabled = value
			if legitDigEnabled then
				startLegitDig()
				Window:Notify({ Title = "Legit Dig", Description = "Legit Dig enabled! Stand on sand with tool equipped.", Lifetime = 3 })
			else
				stopLegitDig()
				Window:Notify({ Title = "Legit Dig", Description = "Legit Dig disabled!", Lifetime = 2 })
			end
		end
	})

	MainSection:Toggle({
		Name = "Fast Legit Dig",
		Default = false,

		Callback = function(value)
			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				fastLegitDigEnabled = false
				return
			end

			fastLegitDigEnabled = value

			if value then
		stopLegitDig()

		fastLegitDigEnabled = true
		legitDigEnabled = false

		startFastLegitDig()

				Window:Notify({
					Title = "Fast Legit Dig",
					Description = "Fast Legit Dig enabled!",
					Lifetime = 3
				})
			else
				stopLegitDig()

				Window:Notify({
					Title = "Fast Legit Dig",
					Description = "Fast Legit Dig disabled!",
					Lifetime = 2
				})
			end
		end
	})

MainSection:Toggle({
    Name = "Mythic Only Dig 🌟",
    Default = false,
    Callback = function(value)
        if mainLocked then
            Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
            mythicDigEnabled = false
            return
        end
        mythicDigEnabled = value
        if mythicDigEnabled then
            startMythicDig()
            Window:Notify({ Title = "Mythic Only Dig", Description = "Skipping non-mythics! Will only complete QTE when Surge appears.", Lifetime = 4 })
        else
            stopMythicDig()
            Window:Notify({ Title = "Mythic Only Dig", Description = "Mythic Only Dig disabled!", Lifetime = 2 })
        end
    end
})

MainSection:Paragraph({
    Header = "ℹ️ Mythic Only Dig Info",
    Body = "Gali sampai ketemu mythics/legendarys."
})

	MainSection:Toggle({
		Name = "Sell When Full",
		Default = false,

		Callback = function(value)

			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				sellWhenFullEnabled = false
				return
			end

			sellWhenFullEnabled = value

			if value then

				startSellWhenFull()

				Window:Notify({
					Title = "Sell When Full",
					Description = "Will auto sell when inventory is full!",
					Lifetime = 4
				})

			else

				Window:Notify({
					Title = "Sell When Full",
					Description = "Disabled!",
					Lifetime = 2
				})
			end
		end
	})

	MainSection:Toggle({
		Name = "Auto Sell",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				sellEnabled = false
				return
			end
			sellEnabled = value
			if sellEnabled then
				startSell()
				Window:Notify({ Title = "Auto Sell", Description = "Will TP to sell NPC and sell every 300 seconds.", Lifetime = 4 })
			else
				Window:Notify({ Title = "Auto Sell", Description = "Auto Sell disabled!", Lifetime = 2 })
			end
		end
	})

	MainSection:Toggle({
		Name = "Auto Impact Debris",
		Default = false,

		Callback = function(value)

			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				autoDebrisEnabled = false
				return
			end

			autoDebrisEnabled = value

			if autoDebrisEnabled then

				startAutoDebris()

				Window:Notify({
					Title = "Auto Debris",
					Description = "Teleporting to Impact Debris every 5 seconds!",
					Lifetime = 3
				})

			else

				Window:Notify({
					Title = "Auto Debris",
					Description = "Disabled!",
					Lifetime = 2
				})
			end
		end
	})

	MainSection:Dropdown({
		Name = "Select Tool to Reroll",
		Multi = false,
		Required = false,
		Options = allRerollTools,
		Default = 1,

		Callback = function(value)

			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				return
			end

			selectedRerollTool = value

		end
	})

	MainSection:Toggle({

		Name = "Auto Reroll Trait",
		Default = false,

		Callback = function(value)

			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				autoRerollEnabled = false
				return
			end

			if value and not selectedRerollTool then

				Window:Notify({
					Title = "No Tool Selected",
					Description = "Select a tool to reroll first!",
					Lifetime = 3
				})

				autoRerollEnabled = false
				return
			end

			autoRerollEnabled = value

			if autoRerollEnabled then

				startAutoReroll()

				Window:Notify({
					Title = "Auto Reroll",
					Description =
						"Auto rerolling "
						.. selectedRerollTool
						.. " trait!",

					Lifetime = 2
				})

			else

				Window:Notify({
					Title = "Auto Reroll",
					Description = "Auto reroll stopped!",
					Lifetime = 2
				})
			end
		end
	})

	MainSection:Paragraph({
		Header = "ℹ️ Auto Sell Info",
		Body = "Otomatis Menjual Kerang tiap 5 menit Sekali"
	})

	MainSection:Paragraph({
		Header = "ℹ️ Auto Sell When Full",
		Body = "Otomatis Menjual Semua isi Tas tiap kali Penuh. WARNING! KLO INVENTORYMU BANYAK BAKAL LAG!"

	})
	MainSection:Paragraph({
		Header = "ℹ️ Auto Debris",
		Body = "Otomatis Gali Debris Ketika Spawn, Posisikan Char pada lokasi Farm baru Aktifkan. Karena ketika Debris selesai digali akan kembali ke tempat Farm Sebelumnya"

	})

	-- RIGHT SIDE — HERMIT CRAB
	CrabSection:Paragraph({
		Header = "🦀 Hermit Crab",
		Body = "Auto claim shells from your crab and auto upgrade its stats on repeat."
	})

	local autoClaimToggle = CrabSection:Toggle({
		Name = "Auto Claim Shells",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoClaimEnabled = false
				return
			end
			autoClaimEnabled = value
			saveConfig()
			if autoClaimEnabled then
				startAutoClaim()
				Window:Notify({ Title = "Auto Claim", Description = "Auto claiming crab shells!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Claim", Description = "Auto claim stopped!", Lifetime = 2 })
			end
		end
	})

	CrabSection:Toggle({
		Name = "Auto Upgrade Luck",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoUpgradeLuck = false
				return
			end
			autoUpgradeLuck = value
			if autoUpgradeLuck then
				startAutoUpgrade(function() return autoUpgradeLuck end, "\t\004\000Luck")
				Window:Notify({ Title = "Auto Upgrade", Description = "Auto upgrading Luck!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Upgrade", Description = "Luck upgrade stopped!", Lifetime = 2 })
			end
		end
	})

	CrabSection:Toggle({
		Name = "Auto Upgrade Speed",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoUpgradeSpeed = false
				return
			end
			autoUpgradeSpeed = value
			if autoUpgradeSpeed then
				startAutoUpgrade(function() return autoUpgradeSpeed end, "\t\005\000Speed")
				Window:Notify({ Title = "Auto Upgrade", Description = "Auto upgrading Speed!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Upgrade", Description = "Speed upgrade stopped!", Lifetime = 2 })
			end
		end
	})

	CrabSection:Toggle({
		Name = "Auto Upgrade Space",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoUpgradeSpace = false
				return
			end
			autoUpgradeSpace = value
			if autoUpgradeSpace then
				startAutoUpgrade(function() return autoUpgradeSpace end, "\t\005\000Space")
				Window:Notify({ Title = "Auto Upgrade", Description = "Auto upgrading Space!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Upgrade", Description = "Space upgrade stopped!", Lifetime = 2 })
			end
		end
	})

	CrabSection:Toggle({
		Name = "Auto Upgrade Weight Cap",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoUpgradeWeight = false
				return
			end
			autoUpgradeWeight = value
			if autoUpgradeWeight then
				startAutoUpgrade(function() return autoUpgradeWeight end, "\t\t\000WeightCap")
				Window:Notify({ Title = "Auto Upgrade", Description = "Auto upgrading Weight Cap!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Upgrade", Description = "Weight Cap upgrade stopped!", Lifetime = 2 })
			end
		end
	})

	-- ============================================================
	-- FAVORITES TAB
	-- ============================================================
	local FavSection = Tabs.Favorites:Section({ Side = "Left" })
	local UnfavSection = Tabs.Favorites:Section({ Side = "Right" })

	FavSection:Paragraph({
		Header = "Auto Favorite",
		Body = "Select which shells to auto favorite from your backpack, then toggle Auto Favorite on."
	})

	FavSection:Dropdown({
		Name = "Select Shells to Favorite",
		Multi = true,
		Required = false,
		Options = allShells,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			selectedShells = value
		end
	})

	FavSection:Toggle({
		Name = "Auto Favorite",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoFavEnabled = false
				return
			end
			autoFavEnabled = value
			if autoFavEnabled then
				if next(selectedShells) == nil then
					Window:Notify({ Title = "No Shells Selected", Description = "Please select shells from the dropdown first!", Lifetime = 3 })
					autoFavEnabled = false
					return
				end
				startAutoFav()
				Window:Notify({ Title = "Auto Favorite", Description = "Auto Favorite enabled!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Favorite", Description = "Auto Favorite disabled!", Lifetime = 2 })
			end
		end
	})

	FavSection:Dropdown({
		Name = "Select Rarities",
		Multi = true,
		Required = false,
		Options = rarityList,

		Callback = function(value)

			if mainLocked then
				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})
				return
			end

			selectedRarities = value
		end
	})

	FavSection:Toggle({
		Name = "Auto Favorite Rarity",
		Default = false,

		Callback = function(value)

			if mainLocked then

				Window:Notify({
					Title = "Locked",
					Description = "Enter your key first!",
					Lifetime = 3
				})

				autoFavRarityEnabled = false
				return
			end

			autoFavRarityEnabled = value

			if autoFavRarityEnabled then

				if next(selectedRarities) == nil then

					Window:Notify({
						Title = "No Rarity Selected",
						Description = "Select rarity first!",
						Lifetime = 3
					})

					autoFavRarityEnabled = false
					return
				end

				startAutoFavRarity()

				Window:Notify({
					Title = "Auto Favorite Rarity",
					Description = "Enabled!",
					Lifetime = 2
				})

			else

				Window:Notify({
					Title = "Auto Favorite Rarity",
					Description = "Disabled!",
					Lifetime = 2
				})
			end
		end
	})

	UnfavSection:Paragraph({
	Header = "Unfavorite",
	Body = "Select shells or rarities to remove favorite status."
})

UnfavSection:Dropdown({
	Name = "Select Shells",
	Multi = true,
	Required = false,
	Options = allShells,

	Callback = function(value)

		selectedUnfavShells = value

	end
})

UnfavSection:Button({

	Name = "Unfavorite Selected Shells",

	Callback = function()
	if next(selectedUnfavShells) == nil then

	Window:Notify({
		Title = "No Shell Selected",
		Description = "Select shell first!",
		Lifetime = 3
	})

	return
	end
		local backpack =
			game.Players.LocalPlayer.Backpack

		local unfavCount = 0

		for _, item in ipairs(backpack:GetChildren()) do

			for shellName in pairs(selectedUnfavShells) do

				if item.Name:find(shellName) then

					unfavoriteShell(item)

					unfavCount += 1

					task.wait(0.05)
				end
			end
		end

		Window:Notify({
			Title = "Unfavorite Complete",
			Description =
				"Unfavorited "
				.. unfavCount
				.. " shells!",
			Lifetime = 4
		})
	end
})

UnfavSection:Dropdown({
	Name = "Select Rarities",
	Multi = true,
	Required = false,
	Options = rarityList,

	Callback = function(value)

		selectedUnfavRarities = value

	end
})

UnfavSection:Button({

	Name = "Unfavorite Selected Rarities",

	Callback = function()

	if next(selectedUnfavRarities) == nil then

		Window:Notify({
			Title = "No Rarity Selected",
			Description = "Select rarity first!",
			Lifetime = 3
		})

		return
	end

	startAutoUnfavRarity()

end
})
	-- ============================================================
	-- AUTO GIFT TAB
	-- ============================================================
	local GiftSection = Tabs.Gift:Section({ Side = "Left" })

	GiftSection:Paragraph({
		Header = "Auto Gift",
		Body = "Automatically gift shells to nearby players."
	})
	GiftSection:Dropdown({
		Name = "Select Gift Rarities",
		Multi = true,
		Required = false,
		Options = rarityList,

		Callback = function(value)

			selectedGiftRarities = value

		end
	})

	GiftSection:Toggle({

		Name = "Auto Gift",
		Default = false,

		Callback = function(value)

			autoGiftEnabled = value

			if value then

				startAutoGift()

				Window:Notify({
					Title = "Auto Gift",
					Description = "Auto Gift enabled!",
					Lifetime = 2
				})

			else

				Window:Notify({
					Title = "Auto Gift",
					Description = "Auto Gift disabled!",
					Lifetime = 2
				})
			end
		end
	})

	GiftSection:Toggle({

	Name = "Auto Gift Non-Favorite",
	Default = false,

	Callback = function(value)

		autoGiftNonFavEnabled = value

		if value then

			startAutoGiftNonFavorite()

			Window:Notify({
				Title = "Auto Gift",
				Description =
					"Gifting all non-favorite shells!",

				Lifetime = 3
			})

		else

			Window:Notify({
				Title = "Auto Gift",
				Description =
					"Non-favorite gifting disabled!",

				Lifetime = 2
			})
		end
	end
})


	-- ============================================================
	-- TELEPORT TAB
	-- ============================================================
	local TpSectionIslands = Tabs.Teleport:Section({ Side = "Left" })
	local TpSectionNpcs    = Tabs.Teleport:Section({ Side = "Right" })

	TpSectionIslands:Dropdown({
		Name = "Islands",
		Multi = false,
		Required = false,
		Options = islandNames,
		Default = 1,
		Callback = function(value) selectedIsland = value end
	})

	TpSectionIslands:Button({
		Name = "Teleport to Island",
		Callback = function()
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			if selectedIsland and islands[selectedIsland] then
				tpTo(islands[selectedIsland])
				Window:Notify({ Title = "Teleporting", Description = "Teleporting to " .. selectedIsland, Lifetime = 2 })
			end
		end
	})

	TpSectionNpcs:Dropdown({
		Name = "NPCs",
		Multi = false,
		Required = false,
		Options = npcNames,
		Default = 1,
		Callback = function(value) selectedNpc = value end
	})

	TpSectionNpcs:Button({
		Name = "Teleport to NPC",
		Callback = function()
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			if selectedNpc and npcs[selectedNpc] then
				tpTo(npcs[selectedNpc])
				Window:Notify({ Title = "Teleporting", Description = "Teleporting to " .. selectedNpc, Lifetime = 2 })
			end
		end
	})

	-- ============================================================
	-- TRAVELLING MERCHANT TAB
	-- ============================================================
	local MerchantLeft  = Tabs.Merchant:Section({ Side = "Left" })
	local MerchantRight = Tabs.Merchant:Section({ Side = "Right" })

	MerchantLeft:Button({
		Name = "Open/Close Travelling Merchant",
		Callback = function()
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			toggleTravellingMerchant()
		end
	})

	local merchantDropdown = MerchantLeft:Dropdown({
		Name = "Select Charms",
		Multi = true,
		Required = false,
		Options = merchantItemNames,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			selectedMerchantItems = value
			saveConfig()
		end
	})

	MerchantLeft:Button({
		Name = "Buy Selected Once",
		Callback = function()
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				return
			end
			if next(selectedMerchantItems) == nil then
				Window:Notify({ Title = "None Selected", Description = "Select charms first!", Lifetime = 3 })
				return
			end
			for itemName in pairs(selectedMerchantItems) do
				purchaseItem(itemName)
				task.wait(0.5)
			end
			Window:Notify({ Title = "Done", Description = "Purchased all selected charms!", Lifetime = 2 })
		end
	})

	local autoBuyToggle = MerchantLeft:Toggle({
		Name = "Auto Buy (Repeat)",
		Default = false,
		Callback = function(value)
			if mainLocked then
				Window:Notify({ Title = "Locked", Description = "Enter your key first!", Lifetime = 3 })
				autoBuyEnabled = false
				return
			end
			autoBuyEnabled = value
			saveConfig()
			if autoBuyEnabled then
				if next(selectedMerchantItems) == nil then
					Window:Notify({ Title = "None Selected", Description = "Select charms first!", Lifetime = 3 })
					autoBuyEnabled = false
					return
				end
				startAutoBuy()
				Window:Notify({ Title = "Auto Buy", Description = "Auto buying charms on repeat!", Lifetime = 2 })
			else
				Window:Notify({ Title = "Auto Buy", Description = "Auto buy stopped!", Lifetime = 2 })
			end
		end
	})

	MerchantRight:Paragraph({
		Header = "Available Charms",
		Body = "Abyssal Charm\nColossus Charm\nCoral Charm\nCrystal Charm\nDriftwood Charm\nEclipse Charm\nLeviathan Charm\nMoonstone Charm\nPebble Charm\nPrism Charm\nSea Glass Charm\nStarfish Charm\nTidal Charm\nTide Charm\nVoid Charm"
	})

	-- ============================================================
	-- PROFILE TAB
	-- ============================================================
	local SettingsSection  = Tabs.Profile:Section({ Side = "Left" })
	local SettingsSection2 = Tabs.Profile:Section({ Side = "Right" })

	local executorName = "Unknown"
	if identifyexecutor then
		local ok, result = pcall(identifyexecutor)
		if ok and result then executorName = result end
	elseif getexecutorname then
		local ok, result = pcall(getexecutorname)
		if ok and result then executorName = result end
	elseif syn then
		executorName = "Synapse X"
	elseif KRNL_LOADED then
		executorName = "KRNL"
	elseif pebc_execute then
		executorName = "Electron"
	elseif fluxus then
		executorName = "Fluxus"
	elseif is_sirhurt_closure then
		executorName = "Sir Hurt"
	elseif ExecutorName then
		executorName = tostring(ExecutorName)
	end

	local player = game.Players.LocalPlayer

	SettingsSection:Header({ Name = "Hello, " .. player.DisplayName .. "!" })
	SettingsSection:Label({ Text = "@" .. player.Name })
	SettingsSection:Divider()
	SettingsSection:Label({ Text = "Executor: " .. executorName })
	SettingsSection:Label({ Text = executorName .. " supports this script!" })

	SettingsSection2:Header({ Name = "Discord" })
	SettingsSection2:Label({ Text = "Join our Discord to get a key and stay updated!" })
	SettingsSection2:Button({
		Name = "Copy Discord Link",
		Callback = function()
			setclipboard("https://discord.gg/CqqJ8Qtm8N")
			Window:Notify({ Title = "Discord", Description = "Discord link copied to clipboard!", Lifetime = 3 })
		end
	})

	Tabs.Main:Select()

	-- Anti-AFK (always on)
	local VirtualUser = game:GetService("VirtualUser")
	game.Players.LocalPlayer.Idled:Connect(function()
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(0.3)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)

	if DEV_MODE then
		task.spawn(function()
			task.wait(2)
			unlockMain()
		end)
	end
