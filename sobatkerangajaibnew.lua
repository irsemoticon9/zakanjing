--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local workspace = game:GetService("workspace")

local LocalPlayer = Players.LocalPlayer

local ShellData = require(
    ReplicatedStorage.Modules.GameModules.Info.Shells
)

--========================================================
-- SETTINGS
--========================================================

local Settings = {

    Main = {
        LegitDig = false,
        FastLegitDig = false,
        MythicOnly = false,
        LunarCrater = false,
        AutoDebris = false,

        AutoSell = false,
        SellWhenFull = false,
    },

    Favorites = {
        SelectedShells = {},
        SelectedRarities = {},

        AutoFavorite = false,
        AutoFavoriteRarity = false,
    },

    Gift = {
        SelectedRarities = {},

        AutoGift = false,
        AutoGiftNonFavorite = false,
    },

    Crab = {
        AutoClaim = false,

        AutoLuck = false,
        AutoSpeed = false,
        AutoSpace = false,
        AutoWeight = false,
    },

    Trait = {
        SelectedTool = nil,

        AutoReroll = false,
    },

    Merchant = {
        SelectedItems = {},

        AutoBuy = false,
    },

    Teleport = {
        SelectedIsland = nil,
        SelectedNpc = nil,
    }
}

--========================================================
-- RUNTIME
--========================================================

local Runtime = {

    StartTime = tick(),

    QteAutoClickConn = nil,

    PrevLineRot = nil,

    QteLineMoving = false,

    CachedBars = nil,

    MythicDigConn = nil,
	MythicPrevLineRot = nil,
	MythicDigMoving = false,

	CompletedDebris = {},
	DebrisReturnPos = nil,
	DebrisActive = false,
	
	SellRunning = false,
	SellWhenFullRunning = false,

	GiftRunning = false,
}

--========================================================
-- FUNCTIONS
--========================================================

local VIM = game:GetService("VirtualInputManager")

local FastDigLastClick = 0

local function safeVIMClick()

    pcall(function()

        VIM:SendMouseButtonEvent(
            0,
            0,
            0,
            true,
            game,
            0
        )

        VIM:SendMouseButtonEvent(
            0,
            0,
            0,
            false,
            game,
            0
        )

    end)
end

local function angleDiff(a, b)

    local diff = math.abs(a - b)

    return math.min(
        diff,
        360 - diff
    )
end

-- ===== AREA HELPER ====
-- Helper Teleport 

local function tpTo(position)

    local char = LocalPlayer.Character

    if not char then
        return
    end

    local hrp =
        char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return
    end

    hrp.CFrame = CFrame.new(position)
	
end

-- helper debris

local function findMoonGiftPrompt()

    for _, obj in ipairs(workspace:GetDescendants()) do

        if obj:IsA("ProximityPrompt") then

            local objectText =
                tostring(obj.ObjectText)

            local actionText =
                tostring(obj.ActionText)

            if objectText:find("Moon Gift")
            and actionText:find("Open") then

                return obj

            end
        end
    end

    return nil

end

-- helper get shell list

local function getShellList()

    local shells = {}

    for _, shell in ipairs(
        ShellData.Items
    ) do

        table.insert(
            shells,
            shell.Name
        )

    end

    table.sort(shells, function(a, b)

        return string.lower(a)
            < string.lower(b)

    end)

    return shells

end

-- helper get rarity

local function getRarityList()

    local order = {
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Mythic",
        "Exotic",
        "Abyssal"
    }

    return order

end

local ShellRarities = {}

for _, shell in ipairs(ShellData.Items) do

    ShellRarities[shell.Name] =
        shell.Rarity

end

-- Helper auto gift
local function confirmGift()

    local confirmGui =
        LocalPlayer.PlayerGui:FindFirstChild("Confirm")

    if not confirmGui then
        return false
    end

    local yesButton =
        confirmGui.Main.Buttons.Yes

    if not yesButton then
        return false
    end

    for _, connection in pairs(
        getconnections(yesButton.Activated)
    ) do

        pcall(function()
            connection:Fire()
        end)

    end

    return true

end

-- Helper find shell rarity
local function getShellRarity(shellName)

    for knownShell, rarity in pairs(ShellRarities) do

        if shellName:find(knownShell) then
            return rarity
        end

    end

    return nil

end

-- ===== AREA FUNCTION UTAMA
-- LegitDig 
local function startLegitDig()

    local pgui = LocalPlayer.PlayerGui

    local prevDiff = 999
    local clicked = false

    Runtime.PrevLineRot = nil
    Runtime.QteLineMoving = false

    if Runtime.QteAutoClickConn then

        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil

    end

    Runtime.QteAutoClickConn = RunService.RenderStepped:Connect(function()

        if not Settings.Main.LegitDig then

            prevDiff = 999
            clicked = false

            return

        end

        pcall(function()

            local qte = pgui:FindFirstChild("QTE")

            if not qte then

                prevDiff = 999
                clicked = false
                Runtime.QteLineMoving = false

                return

            end

            local main = qte:FindFirstChild("Main")

            if not main then

                Runtime.QteLineMoving = false

                return

            end

            local line = main:FindFirstChild("Line")
            local bars = main:FindFirstChild("Bars")

            if not line or not bars then

                Runtime.QteLineMoving = false

                return

            end

            local lineRot = line.Rotation

            if Runtime.PrevLineRot ~= nil then

                Runtime.QteLineMoving =
                    math.abs(lineRot - Runtime.PrevLineRot) > 0.1

            end

            Runtime.PrevLineRot = lineRot

            local targetBar

            for _, bar in pairs(bars:GetChildren()) do

                if bar:IsA("ImageLabel") and bar.Visible then

                    targetBar = bar
                    break

                end
            end

            if not targetBar then

                prevDiff = 999
                clicked = false

                return

            end

            local diff = angleDiff(
                lineRot,
                targetBar.Rotation
            )

            local barSize =
                tonumber(targetBar.Name:match("%d+"))
                or 15

            if not clicked and diff <= barSize / 2 then

                if diff > prevDiff then

                    safeVIMClick()

                    clicked = true

                end
            end

            if diff > barSize then

                clicked = false

            end

            prevDiff = diff

        end)

    end)

    task.spawn(function()

        while Settings.Main.LegitDig do

            if not Runtime.QteLineMoving then

                safeVIMClick()

            end

            task.wait(0.5)

        end

    end)

    print("[Sobat Kerang] Legit Dig Started")

end

-- fast legit dig
local function startFastLegitDig()

    local pgui = LocalPlayer.PlayerGui

    if Runtime.QteAutoClickConn then

        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil

    end

    Runtime.QteAutoClickConn =
        RunService.RenderStepped:Connect(function()

        if not Settings.Main.FastLegitDig then
            return
        end

        pcall(function()

            local qte = pgui:FindFirstChild("QTE")

            if not qte then

                Runtime.CachedBars = nil

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

            if Runtime.CachedBars
                and #Runtime.CachedBars ~= #bars:GetChildren()
            then

                Runtime.CachedBars = nil

            end

            if not Runtime.CachedBars then

                Runtime.CachedBars = {}

                for _, obj in ipairs(bars:GetChildren()) do

                    if obj:IsA("ImageLabel") then

                        table.insert(
                            Runtime.CachedBars,
                            obj
                        )

                    end
                end
            end

            local targetBar

            for i = 1, #Runtime.CachedBars do

                local bar = Runtime.CachedBars[i]

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

                if now - FastDigLastClick > 0.08 then

                    FastDigLastClick = now

                    safeVIMClick()

                end
            end

        end)

    end)

    task.spawn(function()

        while Settings.Main.FastLegitDig do

            local qte = pgui:FindFirstChild("QTE")

            if qte then

                local main = qte:FindFirstChild("Main")
                local line = main and main:FindFirstChild("Line")

                if line then

                    local currentRot = line.Rotation

                    if Runtime.PrevLineRot ~= nil then

                        Runtime.QteLineMoving =
                            math.abs(
                                currentRot -
                                Runtime.PrevLineRot
                            ) > 0.1

                    end

                    Runtime.PrevLineRot = currentRot

                    if not Runtime.QteLineMoving then

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

    print("[Sobat Kerang] Fast Legit Dig Started")

end

-- Mythic dig only
local function startMythicDig()

    local pgui = LocalPlayer.PlayerGui

    local prevDiff = 999
    local clicked = false
    local cancelCooldown = false

    Runtime.MythicPrevLineRot = nil
    Runtime.MythicDigMoving = false

    if Runtime.MythicDigConn then

        Runtime.MythicDigConn:Disconnect()
        Runtime.MythicDigConn = nil

    end

    Runtime.MythicDigConn =
        RunService.RenderStepped:Connect(function()

        if not Settings.Main.MythicOnly then

            prevDiff = 999
            clicked = false

            return

        end

        pcall(function()

            local qte = pgui:FindFirstChild("QTE")

            if not qte then

                prevDiff = 999
                clicked = false
                Runtime.MythicDigMoving = false

                return

            end

            local main = qte:FindFirstChild("Main")

            if not main then

                Runtime.MythicDigMoving = false

                return

            end

            local line = main:FindFirstChild("Line")
            local bars = main:FindFirstChild("Bars")

            if not line or not bars then
                return
            end

            local lineRot = line.Rotation

            if Runtime.MythicPrevLineRot ~= nil then

                Runtime.MythicDigMoving =
                    math.abs(
                        lineRot -
                        Runtime.MythicPrevLineRot
                    ) > 0.1

            end

            Runtime.MythicPrevLineRot = lineRot

            if not Runtime.MythicDigMoving then
                return
            end

            local surgeFrame =
                qte:FindFirstChild("Surge")

            local surgeVisible =
                surgeFrame and surgeFrame.Visible

            local targetBar

            for _, bar in pairs(bars:GetChildren()) do

                if bar:IsA("ImageLabel") and bar.Visible then

                    targetBar = bar
                    break

                end
            end

            if not targetBar then

                prevDiff = 999
                clicked = false

                return

            end

            local diff =
                angleDiff(
                    lineRot,
                    targetBar.Rotation
                )

            local barSize =
                tonumber(targetBar.Name:match("%d+"))
                or 15

            if not surgeVisible then

                if not cancelCooldown then

                    cancelCooldown = true

                    pcall(function()

                        local args = {
                            buffer.fromstring("6")
                        }

                        ReplicatedStorage
                            :WaitForChild("ByteNetReliable")
                            :FireServer(unpack(args))

                    end)

                    task.delay(2, function()

                        cancelCooldown = false

                        safeVIMClick()

                    end)

                end

                prevDiff = diff
                clicked = false

                Runtime.MythicDigMoving = false

                return

            end

            local pingOffset =
                barSize * 0.35

            if not clicked and
                diff <= (barSize / 2) + pingOffset
            then

                safeVIMClick()

                clicked = true

                cancelCooldown = false

            end

            if diff > barSize then

                clicked = false

            end

            prevDiff = diff

        end)

    end)

    task.spawn(function()

        while Settings.Main.MythicOnly do

            if not Runtime.MythicDigMoving
                and not cancelCooldown
            then

                safeVIMClick()

            end

            task.wait(0.2)

        end

    end)

    print("[Sobat Kerang] Mythic Only Dig Started")

end

-- auto debris

local function startAutoDebris()

    task.spawn(function()

        while Settings.Main.AutoDebris do

            local debrisList = {}

            for _, v in ipairs(workspace:GetChildren()) do

                if v.Name == "ImpactDebris"
                and not Runtime.CompletedDebris[v]
                then

                    table.insert(
                        debrisList,
                        v
                    )

                end
            end

            if #debrisList > 0 then

                if not Runtime.DebrisActive then

                    local char =
                        LocalPlayer.Character

                    local hrp =
                        char and
                        char:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if hrp then

                        Runtime.DebrisReturnPos =
                            hrp.Position

                        Runtime.DebrisActive = true

                    end
                end

                local randomDebris =
                    debrisList[
                        math.random(1,#debrisList)
                    ]

                local char =
                    LocalPlayer.Character

                local hrp =
                    char and
                    char:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if hrp then

                    local cf

                    local cf = nil

					if randomDebris:IsA("Model")
					and randomDebris.PrimaryPart then

					cf = randomDebris.PrimaryPart.CFrame

					end

					print(
					"[Auto Debris] Found:",
					randomDebris.Name,
					cf and cf.Position
)

                    if cf then

					print(
					"[Auto Debris] TP:",
					randomDebris:GetFullName()
					)

					tpTo(cf.Position)

					task.wait(4)

                        local foundPrompt = false
                        local startTick = tick()

                        repeat

                            local prompt =
                                findMoonGiftPrompt()

                            if prompt then

                                foundPrompt = true

                                pcall(function()

                                    fireproximityprompt(
                                        prompt
                                    )

                                end)

                                task.wait(2)

                                Runtime.CompletedDebris[
                                    randomDebris
                                ] = true

                                break

                            end

                            task.wait(0.2)

                        until tick() - startTick > 60

                        if not foundPrompt then

                            Runtime.CompletedDebris[
                                randomDebris
                            ] = true

                        end
                    end
                end
            end

            local stillExists = false

            for _, v in ipairs(
                workspace:GetChildren()
            ) do

                if v.Name == "ImpactDebris"
                and not Runtime.CompletedDebris[v]
                then

                    stillExists = true
                    break

                end
            end

            if not stillExists
            and Runtime.DebrisActive then

                if Runtime.DebrisReturnPos then

                    tpTo(
                        Runtime.DebrisReturnPos
                    )

                end

                Runtime.DebrisReturnPos = nil
                Runtime.DebrisActive = false
                Runtime.CompletedDebris = {}

            end

            task.wait(1)

        end

    end)

    print(
        "[Sobat Kerang] Auto Debris Started"
    )

end

-- auto sell
local function startAutoSell()

    if Runtime.SellRunning then
        return
    end

    Runtime.SellRunning = true

    task.spawn(function()

        while Settings.Main.AutoSell do

            pcall(function()

				sellInventory()

			end)

            task.wait(300)

        end

        Runtime.SellRunning = false

    end)

    print("[Sobat Kerang] Auto Sell Started")

end

local sellNpcPos = Vector3.new(
    110.58097839355469,
    3083.8408203125,
    1208.728515625
)

local function sellInventory()

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return
    end

    local returnPos = hrp.Position

    tpTo(sellNpcPos)

    task.wait(2.5)

    local args = {
        buffer.fromstring("@")
    }

    ReplicatedStorage
        :WaitForChild("ByteNetReliable")
        :FireServer(unpack(args))

    task.wait(2)

    tpTo(returnPos)
	pcall(function()

    Window:Notify({
        Title = "Sell Now",
        Description = "Inventory sold successfully!",
        Lifetime = 3
    })

end)

end

-- auto sell when full
local function startSellWhenFull()

    if Runtime.SellWhenFullRunning then
        return
    end

    Runtime.SellWhenFullRunning = true

    task.spawn(function()

        while Settings.Main.SellWhenFull do

            local inventoryFull = false

            pcall(function()

                for _, gui in pairs(
                    LocalPlayer.PlayerGui:GetDescendants()
                ) do

                    if gui:IsA("TextLabel")
                    and tostring(gui.Text):match("^%d+/%d+$")
                    then

                        local current, max =
                            gui.Text:match("(%d+)/(%d+)")

                        current = tonumber(current)
                        max = tonumber(max)

                        if current
                            and max
                            and current >= max
                        then

                            inventoryFull = true
                            break

                        end
                    end
                end

            end)

            if inventoryFull then

                sellInventory()

                task.wait(5)

            end

            task.wait(2)

        end

        Runtime.SellWhenFullRunning = false

    end)

    print("[Sobat Kerang] Sell When Full Started")

end

--favorite shell
local function favoriteShell(item)

    pcall(function()

        local args = {
            buffer.fromstring("\b\001\001"),
            { item }
        }

        ReplicatedStorage
            :WaitForChild("ByteNetReliable")
            :FireServer(unpack(args))

    end)

end

local function startAutoFavorite()

    task.spawn(function()

        while Settings.Favorites.AutoFavorite do

            local backpack =
                LocalPlayer.Backpack

            for _, item in ipairs(
                backpack:GetChildren()
            ) do

                if not Settings.Favorites.AutoFavorite then
                    break
                end

                for shellName in pairs(
                    Settings.Favorites.SelectedShells
                ) do

                    if item.Name:find(shellName) then

                        favoriteShell(item)

                        task.wait(0.05)

                    end
                end
            end

            task.wait(1)

        end

    end)

    print(
        "[Sobat Kerang] Auto Favorite Started"
    )

end

-- unfavorite shell 
local function unfavoriteShell(item)

    pcall(function()

        local args = {
            buffer.fromstring("\b\001\000"),
            { item }
        }

        ReplicatedStorage
            :WaitForChild("ByteNetReliable")
            :FireServer(unpack(args))

    end)

end

-- favorite rarity shell 
local function startAutoFavoriteRarity()

    task.spawn(function()

        while Settings.Favorites.AutoFavoriteRarity do

            local backpack =
                LocalPlayer.Backpack

            for _, item in ipairs(
                backpack:GetChildren()
            ) do

                if not Settings.Favorites.AutoFavoriteRarity then
                    break
                end

                local matched = false

                for shellName, rarity in pairs(
                    ShellRarities
                ) do

                    if item.Name:find(shellName) then

                        if Settings.Favorites.SelectedRarities[rarity] then

                            matched = true

                        end

                        break

                    end
                end

                if matched then

                    favoriteShell(item)

                    task.wait(0.05)

                end

            end

            task.wait(1)

        end

    end)

    print(
        "[Sobat Kerang] Auto Favorite Rarity Started"
    )

end

-- Find Shell to Gift
local function findGiftableShell()

    local backpack =
        LocalPlayer:FindFirstChild("Backpack")

    if not backpack then
        return nil
    end

    for _, item in ipairs(backpack:GetChildren()) do

        if item:IsA("Tool") then

            local rarity =
                getShellRarity(item.Name)

            if Settings.Gift.SelectedRarities[rarity] then

                return item

            end

        end

    end

    return nil

end

-- equip shell to gift
local function equipGiftShell(shell)

    if not shell then
        return false
    end

    local char =
        LocalPlayer.Character

    if not char then
        return false
    end

    pcall(function()

        shell.Parent = char

    end)

    task.wait(0.5)

    return true

end

-- trigger gift prompt
local function findGiftPrompt()

    local char =
        LocalPlayer.Character

    local hrp =
        char
        and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil
    end

    for _, targetPlayer in ipairs(
        Players:GetPlayers()
    ) do

        if targetPlayer ~= LocalPlayer then

            local targetChar =
                targetPlayer.Character

            local targetHRP =
                targetChar
                and targetChar:FindFirstChild(
                    "HumanoidRootPart"
                )

            if targetHRP then

                local dist =
                    (hrp.Position - targetHRP.Position)
                    .Magnitude

                if dist <= 15 then

                    for _, obj in ipairs(
                        targetChar:GetDescendants()
                    ) do

                        if obj:IsA("ProximityPrompt")
                        and tostring(obj.ActionText)
                            :find("Interact")
                        then

                            return obj

                        end
                    end
                end
            end
        end
    end

    return nil

end

-- start auto gift
local function startAutoGift()

    if Runtime.GiftRunning then
        return
    end

    Runtime.GiftRunning = true

    task.spawn(function()

        while Settings.Gift.AutoGift do

            local shell =
                findGiftableShell()

            if shell then
				print("[Auto Gift] Found:", shell.Name)
					
                if equipGiftShell(shell) then

                    local prompt =
                        findGiftPrompt()

                    if prompt then

                        fireproximityprompt(prompt)

                        task.wait(1)

						print("[Auto Gift] Confirming")
							
                        confirmGift()

                        task.wait(2)

                    end
                end
            end

            task.wait(0.5)

        end

        Runtime.GiftRunning = false

    end)

end

-- Stop Legit Dig
local function stopLegitDig()

    Settings.Main.LegitDig = false
    Settings.Main.FastLegitDig = false
    Settings.Main.MythicOnly = false

    if Runtime.QteAutoClickConn then

        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil

    end
	
	if Runtime.MythicDigConn then

    Runtime.MythicDigConn:Disconnect()
    Runtime.MythicDigConn = nil

	end

    Runtime.CachedBars = nil

    Runtime.QteLineMoving = false
    Runtime.PrevLineRot = nil
	
	Runtime.MythicPrevLineRot = nil
	Runtime.MythicDigMoving = false

    print("[Sobat Kerang] Legit Dig Stopped")

end


--========================================================
-- FLUENT UI
--========================================================

local Fluent = loadstring(game:HttpGet(
    "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"
))()

local Window = Fluent:CreateWindow({
    Title = "Sobat Kerang",
    SubTitle = "v2 Rewrite",
    TabWidth = 170,
    Size = UDim2.fromOffset(950, 650),

    Acrylic = true,
    Theme = "Dark",

    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {

    Main = Window:AddTab({
        Title = "Main",
        Icon = "pickaxe"
    }),

    Favorites = Window:AddTab({
        Title = "Favorites",
        Icon = "star"
    }),

    Gift = Window:AddTab({
        Title = "Gift",
        Icon = "gift"
    }),

    Crab = Window:AddTab({
        Title = "Hermit Crab",
        Icon = "shell"
    }),

    Trait = Window:AddTab({
        Title = "Trait Reroll",
        Icon = "refresh-cw"
    }),

    Merchant = Window:AddTab({
        Title = "Merchant",
        Icon = "shopping-cart"
    }),

    Teleport = Window:AddTab({
        Title = "Teleport",
        Icon = "map-pinned"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}
--========================================================
-- MAIN TAB
--========================================================

Tabs.Main:AddSection("Digging")

Tabs.Main:AddToggle("LegitDig", {
    Title = "Legit Dig",
    Default = Settings.Main.LegitDig,

    Callback = function(Value)

        Settings.Main.LegitDig = Value

        if Value then

            startLegitDig()

        else

            stopLegitDig()

        end
    end
})

Tabs.Main:AddToggle("FastLegitDig", {
    Title = "Fast Legit Dig",
    Default = Settings.Main.FastLegitDig,

    Callback = function(Value)

        Settings.Main.FastLegitDig = Value

        if Value then

            startFastLegitDig()
        else

            stopLegitDig()
        end

    end
})

Tabs.Main:AddToggle("MythicOnly", {
    Title = "Mythic Only Dig ✨",
    Default = Settings.Main.MythicOnly,

    Callback = function(Value)

        Settings.Main.MythicOnly = Value

        if Value then

            startMythicDig()

        else

            stopLegitDig()

        end

    end
})

Tabs.Main:AddToggle("AutoDebris", {
    Title = "Auto Debris",
    Default = Settings.Main.AutoDebris,

    Callback = function(Value)

        Settings.Main.AutoDebris = Value

        if Value then

            startAutoDebris()

        else

        end

    end
})

Tabs.Main:AddSection("Sell")

Tabs.Main:AddToggle("AutoSell", {
    Title = "Auto Sell",
    Default = Settings.Main.AutoSell,

    Callback = function(Value)

        Settings.Main.AutoSell = Value

        if Value then

            startAutoSell()

        else

        end

    end
})

Tabs.Main:AddToggle("SellWhenFull", {
    Title = "Sell When Full",
    Default = Settings.Main.SellWhenFull,

    Callback = function(Value)

        Settings.Main.SellWhenFull = Value

        if Value then

            startSellWhenFull()

        else

        end

    end
})

Tabs.Main:AddButton({
    Title = "Sell Now",

    Callback = function()

        sellInventory()

    end
})

Fluent:Notify({
    Title = "Sobat Kerang",
    Content = "SAATNYA SOBAT KERANG BERAKSI!",
    Duration = 5
})

--========================================================
-- FAVORITES TAB
--========================================================

Tabs.Favorites:AddSection("Shell Favorites")

local ShellDropdown =
    Tabs.Favorites:AddDropdown(
    "SelectedShells",
    {
        Title = "Select Shells",

        Values = getShellList(),

        Multi = true,

        Default = {}
    }
)

ShellDropdown:OnChanged(function(Value)

    Settings.Favorites.SelectedShells = Value

    print("Selected Shells:")

    for shellName in pairs(Value) do
        print(shellName)
    end

end)

Tabs.Favorites:AddToggle("AutoFavorite", {
    Title = "Auto Favorite Selected Shells",
    Default = Settings.Favorites.AutoFavorite,

    Callback = function(Value)

        Settings.Favorites.AutoFavorite = Value

        if Value then

            startAutoFavorite()

        else

        end

    end
})

Tabs.Favorites:AddButton({
    Title = "Unfavorite Selected Shells",

    Callback = function()

        local backpack =
            LocalPlayer.Backpack

        local count = 0

        for _, item in ipairs(
            backpack:GetChildren()
        ) do

            for shellName in pairs(
                Settings.Favorites.SelectedShells
            ) do

                if item.Name:find(shellName) then

                    unfavoriteShell(item)

                    count += 1

                end
            end
        end

        Fluent:Notify({
            Title = "Favorites",
            Content = "Unfavorited "..count.." shells",
            Duration = 3
        })

    end
})

Tabs.Favorites:AddSection("Rarity Favorites")

local RarityDropdown =
    Tabs.Favorites:AddDropdown(
    "SelectedRarities",
    {
        Title = "Select Rarities",

        Values = getRarityList(),

        Multi = true,

        Default = {}
    }
)

RarityDropdown:OnChanged(function(Value)

    Settings.Favorites.SelectedRarities = Value

    print("Selected Rarities:")

    for rarity in pairs(Value) do
        print(rarity)
    end

end)

Tabs.Favorites:AddToggle("AutoFavoriteRarity", {
    Title = "Auto Favorite Selected Rarities",
    Default = Settings.Favorites.AutoFavoriteRarity,

    Callback = function(Value)

        Settings.Favorites.AutoFavoriteRarity = Value

        if Value then

            startAutoFavoriteRarity()

        else

        end

    end
})

Tabs.Favorites:AddButton({
    Title = "Unfavorite Selected Rarities",

    Callback = function()

        local backpack = LocalPlayer.Backpack
        local count = 0

        for _, item in ipairs(backpack:GetChildren()) do

            for shellName, rarity in pairs(ShellRarities) do

                if item.Name:find(shellName) then

                    if Settings.Favorites.SelectedRarities[rarity] then

                        unfavoriteShell(item)

                        count += 1

                    end

                    break

                end
            end
        end

        Fluent:Notify({
            Title = "Favorites",
            Content = "Unfavorited "..count.." shells",
            Duration = 3
        })

    end
})

--========================================================
-- GIFT TAB
--========================================================

Tabs.Gift:AddSection("Gift Rarities")

local GiftRarityDropdown =
    Tabs.Gift:AddDropdown(
    "GiftRarities",
    {
        Title = "Select Gift Rarities",

        Values = getRarityList(),

        Multi = true,

        Default = {}
    }
)

GiftRarityDropdown:OnChanged(function(Value)

    Settings.Gift.SelectedRarities = Value

    print("Selected Gift Rarities:")

    for rarity in pairs(Value) do
        print(rarity)
    end

end)

Tabs.Gift:AddToggle("AutoGift", {
    Title = "Auto Gift Selected Rarities",
    Default = Settings.Gift.AutoGift,

    Callback = function(Value)

        Settings.Gift.AutoGift = Value

        if Value then

            startAutoGift()

        end

    end
})

Tabs.Gift:AddButton({
    Title = "Test Gift Confirm",

    Callback = function()

        confirmGift()

    end
})

--========================================================
-- LOOPS
--========================================================
