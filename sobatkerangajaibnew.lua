--========================================================
-- SCRIPT AVAIL CHECKER (ANTI NUMPUK)
--========================================================

if getgenv().SobatKerangLoaded and getgenv().SobatKerangCleanup then
    pcall(getgenv().SobatKerangCleanup)
end

getgenv().SobatKerangLoaded = true

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local workspace = game:GetService("workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local ShellData = require(ReplicatedStorage.Modules.GameModules.Info.Shells)
local ModifierData = require(ReplicatedStorage.Modules.GameModules.Info.ModifierData)

--========================================================
-- DATABASE TELEPORT
--========================================================

local TeleportLocations = {
    Islands = {
        ["Solmere"] = Vector3.new(-1570, 28.9, -1733.25),
        ["Caldera Cay"] = Vector3.new(1650, 25, -1428),
        ["Sea Stacks Island"] = Vector3.new(971, 26, 1398),
        ["Crescent Shore"] = Vector3.new(-1406, 35, 1570),
        ["Spawn Island"] = Vector3.new(71, 41, 42),
        ["Sacred Mountain"] = Vector3.new(3076, 259, 668),
        ["Sky Island"] = Vector3.new(119, 3083, 1265),
        ["Frostveil Isle"] = Vector3.new(3661.6, 33.3, -1017.5),
        ["Glowcap Cave"] = Vector3.new(1415.0, -66.4, 1219.6),
        ["Coral Graveyard"] = Vector3.new(2782.4, -127.9, -822.4),
        ["Lost City"] = Vector3.new(17141.4, -62.1, 3516.9),
    },
    NPCs = {
        ["Lost NPC"] = Vector3.new(1798, 62, -1619),
        ["Crab Bossfight"] = Vector3.new(-1365, 25, -1562),
        ["Tinkerer"] = Vector3.new(107, 46, 56),
        ["Sarah"] = Vector3.new(83, 35, 102),
        ["Boat NPC"] = Vector3.new(26, 22, 192),
        ["Merchant"] = Vector3.new(84, 42, 9),
        ["Backpack NPC"] = Vector3.new(0, 52, -2),
        ["Old Fisherman"] = Vector3.new(55, 24, 260),
        ["Ghost"] = Vector3.new(156, 124, -73),
        ["Shady NPC"] = Vector3.new(222, 330, -58),
        ["Georgie"] = Vector3.new(906, 28, 1452),
        ["Maxwell"] = Vector3.new(884, 26, 1358),
        ["Hermulese"] = Vector3.new(-1358, 25, -1569),
        ["Biologist"] = Vector3.new(-1453, 38, 1582),
        ["Oro"] = Vector3.new(-1413, 35, 1549),
        ["Psychic"] = Vector3.new(-1483, 38, 1512),
        ["Keeper Nyros"] = Vector3.new(67, 3093, 1420),
        ["Ardyn"] = Vector3.new(-56, 3136, 1322),
        ["Keeper Solen"] = Vector3.new(2780, 64, 454),
        ["Elder Kaelen"] = Vector3.new(2705, 36, 398),
        ["Virell"] = Vector3.new(3743.7, 63.3, -1137.1),
        ["Lyra"] = Vector3.new(3788.5, 28.6, -969.2),
        ["Lost Diver"] = Vector3.new(2780.8, -123.3, -827.1)
    }
}

local IslandNames = {}
for name in pairs(TeleportLocations.Islands) do
    table.insert(IslandNames, name)
end
table.sort(IslandNames)

local NpcNames = {}
for name in pairs(TeleportLocations.NPCs) do
    table.insert(NpcNames, name)
end
table.sort(NpcNames)

--========================================================
-- SETTINGS & RUNTIME
--========================================================

local Settings = {
    Main = {
        LegitDig = false,
        FastLegitDig = false,
        MythicOnly = false,
        AutoDebris = false,
        AutoSell = false,
        SellWhenFull = false
    },
    Favorites = {
        SelectedShells = {},
        SelectedRarities = {},
        AutoFavorite = false,
        AutoFavoriteRarity = false
    },
    Gift = {
        SelectedRarities = {},
        SelectedNonFavoriteRarities = {},
        SelectedShells = {},
        AutoGift = false,
        AutoGiftNonFavorite = false,
        AutoGiftShells = false
    },
    Crab = {
        SelectedUpgrades = {},
        AutoClaim = false,
        AutoUpgrade = false
    },
    Trait = {
        TargetTrait = nil,
        AutoReroll = false
    },
    Merchant = {
        SelectedItems = {},
        AutoBuy = false
    },
    Teleport = {
        SelectedIsland = nil,
        SelectedNpc = nil
    },
    Webhook = {
        Url = "",
        SelectedRarities = {},
        Enabled = false
    }
}

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
    MerchantRunning = false,
    UpgradeActive = false,
    AntiAfkConn = nil,
    WebhookMonitorActive = false,
    WebhookMonitorConn = nil
}

--========================================================
-- HELPER FUNCTIONS
--========================================================

local VIM = game:GetService("VirtualInputManager")
local FastDigLastClick = 0

local function safeVIMClick()
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function angleDiff(a, b)
    local diff = math.abs(a - b)
    return math.min(diff, 360 - diff)
end

local function tpTo(position)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFrame.new(position)
end

local function findMoonGiftPrompt()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local objectText = tostring(obj.ObjectText)
            local actionText = tostring(obj.ActionText)
            if objectText:find("Moon Gift") and actionText:find("Open") then
                return obj
            end
        end
    end
    return nil
end

local function getShellList()
    local shells = {}
    for _, shell in ipairs(ShellData.Items) do
        table.insert(shells, shell.Name)
    end
    table.sort(shells, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return shells
end

local function getRarityList()
    return { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic", "Abyssal" }
end

local ShellRarities = {}
for _, shell in ipairs(ShellData.Items) do
    ShellRarities[shell.Name] = shell.Rarity
end

local function getHermitUpgradeList()
    return { "Luck", "Speed", "Space", "Weight" }
end

local function confirmGift()
    local confirmGui = LocalPlayer.PlayerGui:FindFirstChild("Confirm")
    if not confirmGui then return false end
    local yesButton = confirmGui.Main.Buttons.Yes
    if not yesButton then return false end
    for _, connection in pairs(getconnections(yesButton.Activated)) do
        pcall(function()
            connection:Fire()
        end)
    end
    return true
end

local function getShellRarity(shellName)
    for knownShell, rarity in pairs(ShellRarities) do
        if shellName:find(knownShell) then
            return rarity
        end
    end
    return nil
end

local function findNonFavoriteShell()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local fav = item:GetAttribute("Favourite")
            if not fav then
                local rarity = getShellRarity(item.Name)
                if Settings.Gift.SelectedNonFavoriteRarities[rarity] then
                    return item
                end
            end
        end
    end
    return nil
end

local function findSelectedGiftShell()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    local bestShell, bestWeight = nil, 0
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local shellName = item:GetAttribute("Name")
            if shellName and Settings.Gift.SelectedShells[shellName] then
                local weight = item:GetAttribute("Weight") or 0
                if weight > bestWeight then
                    bestWeight = weight
                    bestShell = item
                end
            end
        end
    end
    return bestShell
end

local function getCurrentTool()
    local ok, result = pcall(function()
        return LocalPlayer.PlayerGui.Equipment.Main.LeftBar.TraitsFrame.ToolDisplay.NameLabel.Text
    end)
    return ok and result or "Unknown"
end

local function getCurrentTrait()
    local ok, result = pcall(function()
        return LocalPlayer.PlayerGui.Equipment.Main.LeftBar.TraitsFrame.ToolDisplay.Trait.TextLabel.Text
    end)
    return ok and result or "Unknown"
end

local function getCurrentPityText()
    local ok, result = pcall(function()
        return LocalPlayer.PlayerGui.Equipment.Main.LeftBar.TraitsFrame.PityBar.TrackerLabel.Text
    end)
    return ok and result or "0/0"
end

local function getCurrentPity()
    local pityText = getCurrentPityText()
    return tonumber(string.match(pityText, "(%d+)")) or 0
end

local function getTraitList()
    local traits = {}
    local frame = LocalPlayer.PlayerGui.Equipment.TraitsInfo.Core.ScrollingFrame
    for _, obj in ipairs(frame:GetChildren()) do
        if obj:IsA("Frame") then
            table.insert(traits, obj.Name)
        end
    end
    table.sort(traits)
    return traits
end

local function getCurrentPearls()
    local ok, result = pcall(function()
        return LocalPlayer.PlayerGui.Main.Stats.Pearls.Value.Value
    end)
    if ok and result then
        local formatted = tostring(result):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return formatted
    end
    return "0"
end

local function getBackpackCapacity()
    local current, max = "?", "?"
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and tostring(gui.Text):match("^%d+/%d+$") then
                current, max = gui.Text:match("(%d+)/(%d+)")
                break
            end
        end
    end)
    return string.format("%s/%s", current, max)
end

local function formatNumber(num)
    num = tonumber(num) or 0
    local formatted = tostring(math.floor(num))
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function getBackpackValue()
    local total = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return 0 end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local shellName = item:GetAttribute("Name")
            local weight = tonumber(item:GetAttribute("Weight")) or 0
            local modifier = item:GetAttribute("Modifier")
            local shellInfo = shellName and ShellData.Names[shellName]
            if shellInfo then
                local value = shellInfo.Cost or 0
                if modifier and ModifierData[modifier] then
                    value = value * (ModifierData[modifier].Mult or 1)
                end
                total = total + value * weight
            end
        end
    end
    return math.floor(total + 0.5)
end

--========================================================
-- WEBHOOK FUNCTIONS (with proper cleanup)
--========================================================

local function sendDiscordWebhook(webhookUrl, payload)
    if webhookUrl == nil or webhookUrl == "" then return false end

    local requestFunc = syn and syn.request or http_request or request
    if not requestFunc then
        warn("[Webhook] No request function available")
        return false
    end

    local success, response = pcall(function()
        return requestFunc({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not success then
        warn("[Webhook] Request failed:", response)
        return false
    end

    if type(response) == "table" and response.StatusCode then
        return response.StatusCode >= 200 and response.StatusCode < 300
    end

    return true
end

local function getShellValue(shellName, weight, modifier)
    local shellInfo = ShellData.Names and ShellData.Names[shellName]
    if not shellInfo then return 0 end
    local baseValue = shellInfo.Cost or 0
    if modifier and ModifierData[modifier] then
        baseValue = baseValue * (ModifierData[modifier].Mult or 1)
    end
    return math.floor(baseValue * weight + 0.5)
end

-- Monitor backpack untuk shell baru (webhook) - versi stabil, tanpa duplikasi
local function startWebhookMonitor()
    -- Hentikan monitor lama jika masih berjalan
    if Runtime.WebhookMonitorConn then
        Runtime.WebhookMonitorConn:Disconnect()
        Runtime.WebhookMonitorConn = nil
    end
    if Runtime.WebhookMonitorThread then
        task.cancel(Runtime.WebhookMonitorThread)
        Runtime.WebhookMonitorThread = nil
    end

    Runtime.WebhookMonitorActive = true
    Runtime.WebhookMonitorThread = task.spawn(function()
        local processedShells = {}  -- persistent table
        local backpack = nil
        local conn = nil

        while Runtime.WebhookMonitorActive do
            if not Settings.Webhook.Enabled then
                task.wait(1)
                continue
            end

            local newBackpack = LocalPlayer:FindFirstChild("Backpack")
            if newBackpack ~= backpack then
                -- backpack berubah (misal respawn), reset koneksi
                if conn then
                    conn:Disconnect()
                    conn = nil
                end
                backpack = newBackpack
                if backpack then
                    -- reset processed shells untuk backpack baru
                    processedShells = {}
                    for _, item in ipairs(backpack:GetChildren()) do
                        if item:IsA("Tool") then
                            processedShells[item] = true
                        end
                    end
                    conn = backpack.ChildAdded:Connect(function(item)
                        if not Runtime.WebhookMonitorActive or not Settings.Webhook.Enabled then
                            return
                        end
                        if item:IsA("Tool") and not processedShells[item] then
                            processedShells[item] = true
                            local shellName = item:GetAttribute("Name")
                            local rarity = getShellRarity(shellName)
                            if rarity and Settings.Webhook.SelectedRarities[rarity] then
                                local weight = item:GetAttribute("Weight") or 0
                                local modifier = item:GetAttribute("Modifier")
                                local value = getShellValue(shellName, weight, modifier)
                                local webhookUrl = Settings.Webhook.Url
                                if webhookUrl ~= "" then
                                    local embed = {
                                        embeds = {{
                                            title = "🐚 New Shell Obtained!",
                                            color = 0x00ff00,
                                            fields = {
                                                { name = "Name", value = shellName, inline = true },
                                                { name = "Rarity", value = rarity, inline = true },
                                                { name = "Weight", value = tostring(weight), inline = true },
                                                { name = "Value", value = tostring(value), inline = true },
                                                { name = "Modifier", value = modifier or "None", inline = true },
                                                { name = "Player", value = LocalPlayer.Name, inline = true }
                                            },
                                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                        }}
                                    }
                                    sendDiscordWebhook(webhookUrl, embed)
                                end
                            end
                        end
                    end)
                    Runtime.WebhookMonitorConn = conn
                end
            end
            task.wait(1)
        end

        -- cleanup saat loop berhenti
        if conn then
            conn:Disconnect()
        end
        Runtime.WebhookMonitorConn = nil
    end)
end

-- Start webhook monitor once (will be restarted on cleanup)
startWebhookMonitor()

--========================================================
-- MAIN FUNCTIONS (dig, sell, gift, etc.)
--========================================================

-- LegitDig
local function startLegitDig()
    local pgui = LocalPlayer.PlayerGui
    local prevDiff, clicked = 999, false
    Runtime.PrevLineRot, Runtime.QteLineMoving = nil, false

    if Runtime.QteAutoClickConn then
        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil
    end

    Runtime.QteAutoClickConn = RunService.RenderStepped:Connect(function()
        if not Settings.Main.LegitDig then return end
        pcall(function()
            local qte = pgui:FindFirstChild("QTE")
            if not qte then
                Runtime.QteLineMoving = false
                return
            end
            local main = qte:FindFirstChild("Main")
            if not main then
                Runtime.QteLineMoving = false
                return
            end
            local line, bars = main:FindFirstChild("Line"), main:FindFirstChild("Bars")
            if not line or not bars then
                Runtime.QteLineMoving = false
                return
            end

            local lineRot = line.Rotation
            if Runtime.PrevLineRot ~= nil then
                Runtime.QteLineMoving = math.abs(lineRot - Runtime.PrevLineRot) > 0.1
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
                clicked = false
                return
            end
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
        while Settings.Main.LegitDig do
            if not Runtime.QteLineMoving and not Runtime.UpgradeActive then
                safeVIMClick()
            end
            task.wait(0.5)
        end
    end)
end

-- Fast Legit Dig
local function startFastLegitDig()
    local pgui = LocalPlayer.PlayerGui
    if Runtime.QteAutoClickConn then
        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil
    end

    Runtime.QteAutoClickConn = RunService.RenderStepped:Connect(function()
        if not Settings.Main.FastLegitDig then return end
        pcall(function()
            local qte = pgui:FindFirstChild("QTE")
            if not qte then
                Runtime.CachedBars = nil
                return
            end
            local main = qte:FindFirstChild("Main")
            if not main then return end
            local line, bars = main:FindFirstChild("Line"), main:FindFirstChild("Bars")
            if not line or not bars then return end

            if Runtime.CachedBars and #Runtime.CachedBars ~= #bars:GetChildren() then
                Runtime.CachedBars = nil
            end
            if not Runtime.CachedBars then
                Runtime.CachedBars = {}
                for _, obj in ipairs(bars:GetChildren()) do
                    if obj:IsA("ImageLabel") then
                        table.insert(Runtime.CachedBars, obj)
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

            if not targetBar then return end
            local diff = angleDiff(line.Rotation, targetBar.Rotation)
            local barSize = tonumber(targetBar.Name:match("%d+")) or 15

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
                        Runtime.QteLineMoving = math.abs(currentRot - Runtime.PrevLineRot) > 0.1
                    end
                    Runtime.PrevLineRot = currentRot

                    if not Runtime.QteLineMoving and not Runtime.UpgradeActive then
                        safeVIMClick()
                    end
                else
                    if not Runtime.UpgradeActive then safeVIMClick() end
                end
            else
                if not Runtime.UpgradeActive then safeVIMClick() end
            end
            task.wait(0.5)
        end
    end)
end

-- Mythic Only Dig
local function startMythicDig()
    local pgui = LocalPlayer.PlayerGui
    local prevDiff, clicked, cancelCooldown = 999, false, false
    Runtime.MythicPrevLineRot, Runtime.MythicDigMoving = nil, false

    if Runtime.MythicDigConn then
        Runtime.MythicDigConn:Disconnect()
        Runtime.MythicDigConn = nil
    end

    Runtime.MythicDigConn = RunService.RenderStepped:Connect(function()
        if not Settings.Main.MythicOnly then return end
        pcall(function()
            local qte = pgui:FindFirstChild("QTE")
            if not qte then
                Runtime.MythicDigMoving = false
                return
            end
            local main = qte:FindFirstChild("Main")
            if not main then
                Runtime.MythicDigMoving = false
                return
            end
            local line, bars = main:FindFirstChild("Line"), main:FindFirstChild("Bars")
            if not line or not bars then return end

            local lineRot = line.Rotation
            if Runtime.MythicPrevLineRot ~= nil then
                Runtime.MythicDigMoving = math.abs(lineRot - Runtime.MythicPrevLineRot) > 0.1
            end
            Runtime.MythicPrevLineRot = lineRot
            if not Runtime.MythicDigMoving then return end

            local surgeFrame = qte:FindFirstChild("Surge")
            local surgeVisible = surgeFrame and surgeFrame.Visible

            local targetBar
            for _, bar in pairs(bars:GetChildren()) do
                if bar:IsA("ImageLabel") and bar.Visible then
                    targetBar = bar
                    break
                end
            end

            if not targetBar then return end
            local diff = angleDiff(lineRot, targetBar.Rotation)
            local barSize = tonumber(targetBar.Name:match("%d+")) or 15

            if not surgeVisible then
                if not cancelCooldown then
                    cancelCooldown = true
                    pcall(function()
                        ReplicatedStorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring("6"))
                    end)
                    task.delay(2, function()
                        cancelCooldown = false
                        safeVIMClick()
                    end)
                end
                prevDiff, clicked, Runtime.MythicDigMoving = diff, false, false
                return
            end

            local pingOffset = barSize * 0.35
            if not clicked and diff <= (barSize / 2) + pingOffset then
                safeVIMClick()
                clicked, cancelCooldown = true, false
            end
            if diff > barSize then clicked = false end
            prevDiff = diff
        end)
    end)

    task.spawn(function()
        while Settings.Main.MythicOnly do
            if not Runtime.MythicDigMoving and not cancelCooldown and not Runtime.UpgradeActive then
                safeVIMClick()
            end
            task.wait(0.2)
        end
    end)
end

-- Stop Dig
local function stopLegitDig()
    Settings.Main.LegitDig, Settings.Main.FastLegitDig, Settings.Main.MythicOnly = false, false, false
    if Runtime.QteAutoClickConn then
        Runtime.QteAutoClickConn:Disconnect()
        Runtime.QteAutoClickConn = nil
    end
    if Runtime.MythicDigConn then
        Runtime.MythicDigConn:Disconnect()
        Runtime.MythicDigConn = nil
    end
    Runtime.CachedBars, Runtime.QteLineMoving, Runtime.PrevLineRot = nil, false, nil
    Runtime.MythicPrevLineRot, Runtime.MythicDigMoving = nil, false
end

-- Auto Debris (versi fleksibel)
local function startAutoDebris()
    task.spawn(function()
        while Settings.Main.AutoDebris do
            local debrisList = {}
            for _, v in ipairs(workspace:GetChildren()) do
                local name = v.Name
                if (name:find("Debris") or name:find("Impact")) and not Runtime.CompletedDebris[v] then
                    local hasPosition = false
                    if v:IsA("BasePart") then
                        hasPosition = true
                    elseif v:IsA("Model") then
                        if v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart") then
                            hasPosition = true
                        end
                    end
                    if hasPosition then
                        table.insert(debrisList, v)
                    end
                end
            end

            if #debrisList > 0 then
                if not Runtime.DebrisActive then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        Runtime.DebrisReturnPos = hrp.Position
                        Runtime.DebrisActive = true
                    end
                end

                while #debrisList > 0 do
                    local idx = math.random(1, #debrisList)
                    local debris = debrisList[idx]

                    local cf = nil
                    if debris:IsA("BasePart") then
                        cf = debris.CFrame
                    elseif debris:IsA("Model") and debris.PrimaryPart then
                        cf = debris.PrimaryPart.CFrame
                    else
                        local part = debris:FindFirstChildWhichIsA("BasePart")
                        if part then cf = part.CFrame end
                    end

                    if cf then
                        tpTo(cf.Position)
                        local startWait = tick()
                        local promptFound = false
                        repeat
                            if not debris:IsDescendantOf(workspace) then break end
                            local prompt = findMoonGiftPrompt()
                            if prompt then
                                promptFound = true
                                pcall(function() fireproximityprompt(prompt) end)
                                task.wait(2)
                                break
                            end
                            task.wait(0.2)
                        until tick() - startWait > 15
                        Runtime.CompletedDebris[debris] = true
                    else
                        Runtime.CompletedDebris[debris] = true
                    end

                    table.remove(debrisList, idx)
                    task.wait(1)
                end

                if Runtime.DebrisReturnPos then
                    tpTo(Runtime.DebrisReturnPos)
                end
                Runtime.DebrisReturnPos = nil
                Runtime.DebrisActive = false
                Runtime.CompletedDebris = {}
            end
            task.wait(1)
        end
    end)
end

-- Auto Sell
local sellNpcPos = Vector3.new(110.58, 3083.84, 1208.72)
local function sellInventory()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local returnPos = hrp.Position

    tpTo(sellNpcPos)
    task.wait(2.5)
    pcall(function()
        ReplicatedStorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring("@"))
    end)
    task.wait(2)
    tpTo(returnPos)
end

local function startAutoSell()
    if Runtime.SellRunning then return end
    Runtime.SellRunning = true
    task.spawn(function()
        while Settings.Main.AutoSell do
            pcall(sellInventory)
            task.wait(300)
        end
        Runtime.SellRunning = false
    end)
end

local function startSellWhenFull()
    if Runtime.SellWhenFullRunning then return end
    Runtime.SellWhenFullRunning = true
    task.spawn(function()
        while Settings.Main.SellWhenFull do
            local inventoryFull = false
            pcall(function()
                for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextLabel") and tostring(gui.Text):match("^%d+/%d+$") then
                        local current, max = gui.Text:match("(%d+)/(%d+)")
                        if tonumber(current) and tonumber(max) and tonumber(current) >= tonumber(max) then
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
end

-- Auto Favorite
local function favoriteShell(item)
    pcall(function()
        ReplicatedStorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring("\b\001\001"), { item })
    end)
end

local function unfavoriteShell(item)
    pcall(function()
        ReplicatedStorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring("\b\001\000"), { item })
    end)
end

local function startAutoFavorite()
    task.spawn(function()
        while Settings.Favorites.AutoFavorite do
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if not Settings.Favorites.AutoFavorite then break end
                for shellName in pairs(Settings.Favorites.SelectedShells) do
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

local function startAutoFavoriteRarity()
    task.spawn(function()
        while Settings.Favorites.AutoFavoriteRarity do
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if not Settings.Favorites.AutoFavoriteRarity then break end
                local matched = false
                for shellName, rarity in pairs(ShellRarities) do
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
end

-- Auto Gift
local function findGiftableShell()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and Settings.Gift.SelectedRarities[getShellRarity(item.Name)] then
            return item
        end
    end
    return nil
end

local function equipGiftShell(shell)
    if not shell or not LocalPlayer.Character then return false end
    pcall(function()
        shell.Parent = LocalPlayer.Character
    end)
    task.wait(0.5)
    return true
end

local function findGiftPrompt()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer then
            local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and (hrp.Position - targetHRP.Position).Magnitude <= 15 then
                for _, obj in ipairs(targetPlayer.Character:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and tostring(obj.ActionText):find("Interact") then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function executeGiftRoutine(shell)
    if shell and equipGiftShell(shell) then
        local prompt = findGiftPrompt()
        if prompt then
            fireproximityprompt(prompt)
            task.wait(1)
            confirmGift()
            task.wait(2)
        end
    end
end

local function startAutoGift()
    if Runtime.GiftRunning then return end
    Runtime.GiftRunning = true
    task.spawn(function()
        while Settings.Gift.AutoGift do
            executeGiftRoutine(findGiftableShell())
            task.wait(0.5)
        end
        Runtime.GiftRunning = false
    end)
end

local function startAutoGiftNonFavorite()
    if Runtime.GiftRunning then return end
    Runtime.GiftRunning = true
    task.spawn(function()
        while Settings.Gift.AutoGiftNonFavorite do
            executeGiftRoutine(findNonFavoriteShell())
            task.wait(0.5)
        end
        Runtime.GiftRunning = false
    end)
end

local function startAutoGiftShells()
    if Runtime.GiftRunning then return end
    Runtime.GiftRunning = true
    task.spawn(function()
        while Settings.Gift.AutoGiftShells do
            executeGiftRoutine(findSelectedGiftShell())
            task.wait(0.5)
        end
        Runtime.GiftRunning = false
    end)
end

-- Hermit Crab Claim & Upgrade
local function claimAllHermitShells()
    pcall(function()
        ReplicatedStorage:WaitForChild("ByteNetQuery"):InvokeServer(buffer.fromstring("\b"), nil, 8)
    end)
end

local function startAutoHermitClaim()
    task.spawn(function()
        while Settings.Crab.AutoClaim do
            task.wait(300)
            claimAllHermitShells()
        end
    end)
end

local function virtualClickButton(buttonObj)
    if not buttonObj or not buttonObj:IsA("GuiButton") then return end
    pcall(function()
        local guiService = game:GetService("GuiService")
        local x = buttonObj.AbsolutePosition.X + (buttonObj.AbsoluteSize.X / 2)
        local y = buttonObj.AbsolutePosition.Y + (buttonObj.AbsoluteSize.Y / 2) + guiService:GetGuiInset().Y
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function upgradeHermit(stat)
    local hermitGui = LocalPlayer.PlayerGui:FindFirstChild("HermitCrab")
    if not hermitGui then return end
    local folderName = stat == "Weight" and "WeightCap" or stat
    pcall(function()
        local targetStatObj = hermitGui.Main.Core.InfoFrame.Stats.StatsFolder:FindFirstChild(folderName)
        if targetStatObj and targetStatObj:FindFirstChild("Upgrade") then
            if targetStatObj.Upgrade.AbsoluteSize.X > 0 and targetStatObj.Upgrade.AbsoluteSize.Y > 0 then
                virtualClickButton(targetStatObj.Upgrade)
            end
        end
    end)
end

local function startAutoHermitUpgrade()
    task.spawn(function()
        while Settings.Crab.AutoUpgrade do
            local hermitGui = LocalPlayer.PlayerGui:FindFirstChild("HermitCrab")
            if hermitGui then
                local mainFrame = hermitGui:FindFirstChild("Main")
                local isAlreadyOpen = mainFrame and mainFrame.Visible
                Runtime.UpgradeActive = true
                task.wait(0.1)

                if mainFrame and not isAlreadyOpen and hermitGui:FindFirstChild("OpenButton") then
                    virtualClickButton(hermitGui.OpenButton)
                    task.wait(0.4)
                end

                for upgradeName in pairs(Settings.Crab.SelectedUpgrades) do
                    if not Settings.Crab.AutoUpgrade then break end
                    upgradeHermit(upgradeName)
                    task.wait(0.6)
                end

                if mainFrame and not isAlreadyOpen and hermitGui:FindFirstChild("CloseButton") then
                    virtualClickButton(hermitGui.CloseButton)
                    task.wait(0.2)
                end

                Runtime.UpgradeActive = false
                task.wait(8)
            else
                task.wait(1)
            end
        end
    end)
end

-- Reroll Trait
local function rerollCurrentTool()
    local toolName = getCurrentTool()
    if toolName == "Unknown" or toolName == "" then return end
    pcall(function()
        local payload = "!" .. string.char(#toolName) .. "\000" .. toolName
        ReplicatedStorage:WaitForChild("ByteNetQuery"):InvokeServer(buffer.fromstring(payload), nil, 33)
    end)
end

local function startAutoTraitReroll()
    task.spawn(function()
        local lastPity = getCurrentPity()
        while Settings.Trait.AutoReroll do
            local currentTrait = getCurrentTrait()
            if currentTrait == Settings.Trait.TargetTrait or getCurrentPity() < lastPity then
                Settings.Trait.AutoReroll = false
                break
            end
            lastPity = getCurrentPity()
            rerollCurrentTool()
            task.wait(1)
        end
    end)
end

-- Auto Buy Merchant
local function buyMerchantItem(itemName)
    local payload = "&" .. string.char(#itemName) .. "\000" .. itemName
    pcall(function()
        ReplicatedStorage:WaitForChild("ByteNetQuery"):InvokeServer(buffer.fromstring(payload), nil, 38)
    end)
end

local function startAutoBuyMerchant()
    task.spawn(function()
        while Settings.Merchant.AutoBuy do
            local boughtAny = false
            for itemName in pairs(Settings.Merchant.SelectedItems) do
                buyMerchantItem(itemName)
                boughtAny = true
                task.wait(0.3)
            end
            task.wait(boughtAny and 0.2 or 1)
        end
    end)
end

--========================================================
-- FLUENT UI & ADDONS
--========================================================

local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Fluent:CreateWindow({
    Title = "Sobat Kerang",
    SubTitle = "v3 Ultimate",
    TabWidth = 170,
    Size = UDim2.fromOffset(480, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Info = Window:CreateTab({ Title = "Information", Icon = "info" }),
    Main = Window:CreateTab({ Title = "Auto Farm", Icon = "pickaxe" }),
    Favorites = Window:CreateTab({ Title = "Favorites", Icon = "star" }),
    Gift = Window:CreateTab({ Title = "Auto Gift Shells", Icon = "gift" }),
    Crab = Window:CreateTab({ Title = "Hermit Crab", Icon = "shell" }),
    Trait = Window:CreateTab({ Title = "Trait Reroll", Icon = "refresh-cw" }),
    Merchant = Window:CreateTab({ Title = "Merchant", Icon = "shopping-cart" }),
    Teleport = Window:CreateTab({ Title = "Teleport", Icon = "map-pinned" }),
    Webhook = Window:CreateTab({ Title = "Webhook", Icon = "webhook" }),
    Settings = Window:CreateTab({ Title = "Settings", Icon = "settings" })
}

--========================================================
-- FLOATING SHELL BUTTON (CUSTOM DRAG + BYPASS)
--========================================================

local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

if CoreGui:FindFirstChild("SobatKerangFloating") then
    CoreGui.SobatKerangFloating:Destroy()
end

local FloatGui = Instance.new("ScreenGui")
FloatGui.Name = "SobatKerangFloating"
FloatGui.ResetOnSpawn = false
FloatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FloatGui.DisplayOrder = 999999
FloatGui.Parent = CoreGui

local ShellButton = Instance.new("TextButton")
ShellButton.Name = "ShellButton"
ShellButton.Parent = FloatGui
ShellButton.Size = UDim2.fromOffset(50, 50)
ShellButton.Position = UDim2.new(0, 20, 0.5, -30)
ShellButton.Text = "🐚"
ShellButton.TextScaled = false
ShellButton.TextSize = 25
ShellButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ShellButton.TextColor3 = Color3.new(1, 1, 1)
ShellButton.AutoButtonColor = true

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = ShellButton

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 180, 255)
Stroke.Thickness = 2
Stroke.Parent = ShellButton

local dragging, dragStart, startPos = false, nil, nil

ShellButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, ShellButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ShellButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Minimized = false
ShellButton.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    pcall(function()
        local fluentGui = CoreGui:FindFirstChild("FluentRenewed") or CoreGui:FindFirstChild("Fluent")
        if fluentGui then
            for _, obj in ipairs(fluentGui:GetChildren()) do
                if obj:IsA("Frame") then
                    obj.Visible = not Minimized
                end
            end
        else
            Window:Minimize(Minimized)
        end
    end)
end)

--========================================================
-- TAB: INFORMATION
--========================================================
Tabs.Info:CreateSection("Account Information")

local InfoParagraph = Tabs.Info:CreateParagraph("AccountInfo", {
    Title = "Player Information",
    Content = "Loading..."
})

task.spawn(function()
    while true do
        local username = LocalPlayer.Name
        local level = "?"
        pcall(function()
            level = LocalPlayer.PlayerGui.Main.Stats.LevelFrame.Level.Text
        end)
        local money = 0
        pcall(function()
            money = LocalPlayer.PlayerGui.Main.Stats.Money.Value.Value
        end)
        local pearls = 0
        pcall(function()
            pearls = LocalPlayer.PlayerGui.Main.Stats.Pearls.Value.Value
        end)
        local backpack = getBackpackCapacity()
        local value = getBackpackValue()
        InfoParagraph:SetValue(string.format(
[[Username : %s
Level    : %s
Money    : %s
Pearls   : %s
Backpack : %s
Backpack Value : %s]],
            username, level, formatNumber(money), formatNumber(pearls), backpack, formatNumber(value)
        ))
        task.wait(2)
    end
end)

--========================================================
-- TAB: MAIN
--========================================================

Tabs.Main:CreateSection("Digging")
Tabs.Main:CreateToggle("LegitDig", {
    Title = "Legit Dig",
    Default = false,
    Callback = function(V)
        Settings.Main.LegitDig = V
        if V then startLegitDig() else stopLegitDig() end
    end
})
Tabs.Main:CreateToggle("FastLegitDig", {
    Title = "Fast Legit Dig",
    Default = false,
    Callback = function(V)
        Settings.Main.FastLegitDig = V
        if V then startFastLegitDig() else stopLegitDig() end
    end
})
Tabs.Main:CreateToggle("MythicOnly", {
    Title = "Mythic Only Dig ✨",
    Default = false,
    Callback = function(V)
        Settings.Main.MythicOnly = V
        if V then startMythicDig() else stopLegitDig() end
    end
})
Tabs.Main:CreateToggle("AutoDebris", {
    Title = "Auto Debris",
    Default = false,
    Callback = function(V)
        Settings.Main.AutoDebris = V
        if V then startAutoDebris() end
    end
})

Tabs.Main:CreateSection("Sell")
Tabs.Main:CreateToggle("AutoSell", {
    Title = "Auto Sell",
    Default = false,
    Callback = function(V)
        Settings.Main.AutoSell = V
        if V then startAutoSell() end
    end
})
Tabs.Main:CreateToggle("SellWhenFull", {
    Title = "Sell When Full",
    Default = false,
    Callback = function(V)
        Settings.Main.SellWhenFull = V
        if V then startSellWhenFull() end
    end
})
Tabs.Main:CreateButton({ Title = "Sell Now", Callback = function()
    sellInventory()
end })

--========================================================
-- TAB: FAVORITES
--========================================================

Tabs.Favorites:CreateSection("Shell Favorites")
Tabs.Favorites:CreateDropdown("SelectedShells", {
    Title = "Select Shells",
    Values = getShellList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Favorites.SelectedShells = V
end)
Tabs.Favorites:CreateToggle("AutoFavorite", {
    Title = "Auto Favorite Selected Shells",
    Default = false,
    Callback = function(V)
        Settings.Favorites.AutoFavorite = V
        if V then startAutoFavorite() end
    end
})
Tabs.Favorites:CreateButton({
    Title = "Unfavorite Selected Shells",
    Callback = function()
        local unfavCount = 0
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if not item:IsA("Tool") then continue end
            for shellName in pairs(Settings.Favorites.SelectedShells) do
                if item.Name:find(shellName) then
                    unfavoriteShell(item)
                    unfavCount = unfavCount + 1
                    task.wait(0.05)
                    break
                end
            end
        end
        Fluent:Notify({
            Title = "Unfavorite Complete",
            Content = "Unfavorited " .. unfavCount .. " shells!",
            Duration = 3
        })
    end
})

Tabs.Favorites:CreateSection("Rarity Favorites")
Tabs.Favorites:CreateDropdown("SelectedRarities", {
    Title = "Select Rarities",
    Values = getRarityList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Favorites.SelectedRarities = V
end)
Tabs.Favorites:CreateToggle("AutoFavoriteRarity", {
    Title = "Auto Favorite Selected Rarities",
    Default = false,
    Callback = function(V)
        Settings.Favorites.AutoFavoriteRarity = V
        if V then startAutoFavoriteRarity() end
    end
})
Tabs.Favorites:CreateButton({
    Title = "Unfavorite Selected Rarities",
    Callback = function()
        local unfavCount = 0
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if not item:IsA("Tool") then continue end
            local rarity = getShellRarity(item.Name)
            if rarity and Settings.Favorites.SelectedRarities[rarity] then
                unfavoriteShell(item)
                unfavCount = unfavCount + 1
                task.wait(0.05)
            end
        end
        Fluent:Notify({
            Title = "Unfavorite Rarity",
            Content = "Unfavorited " .. unfavCount .. " shells with selected rarities.",
            Duration = 3
        })
    end
})

--========================================================
-- TAB: GIFT
--========================================================

Tabs.Gift:CreateSection("Auto Gift Base on Rarities")
Tabs.Gift:CreateDropdown("GiftRarities", {
    Title = "Select Gift Rarities",
    Values = getRarityList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Gift.SelectedRarities = V
end)
Tabs.Gift:CreateToggle("AutoGift", {
    Title = "Selected Rarities",
    Default = false,
    Callback = function(V)
        Settings.Gift.AutoGift = V
        if V then startAutoGift() end
    end
})

Tabs.Gift:CreateSection("Auto Gift Base on Unfavorite Shells")
Tabs.Gift:CreateDropdown("GiftNFRarities", {
    Title = "Select Non-Favorite Rarities",
    Values = getRarityList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Gift.SelectedNonFavoriteRarities = V
end)
Tabs.Gift:CreateToggle("AutoGiftNonFavorite", {
    Title = "Auto Gift Non-Favorite",
    Default = false,
    Callback = function(V)
        Settings.Gift.AutoGiftNonFavorite = V
        if V then
            Settings.Gift.AutoGift = false
            startAutoGiftNonFavorite()
        end
    end
})

Tabs.Gift:CreateSection("Auto Gift Base on Shell Names")
Tabs.Gift:CreateDropdown("GiftShells", {
    Title = "Select Shells",
    Values = getShellList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Gift.SelectedShells = V
end)
Tabs.Gift:CreateToggle("AutoGiftShells", {
    Title = "Auto Gift Selected Shells",
    Default = false,
    Callback = function(V)
        Settings.Gift.AutoGiftShells = V
        if V then
            Settings.Gift.AutoGift = false
            Settings.Gift.AutoGiftNonFavorite = false
            startAutoGiftShells()
        end
    end
})

--========================================================
-- TAB: HERMIT CRAB
--========================================================

Tabs.Crab:CreateSection("Claim")
Tabs.Crab:CreateToggle("AutoClaim", {
    Title = "Auto Claim Shells",
    Default = false,
    Callback = function(V)
        Settings.Crab.AutoClaim = V
        if V then
            claimAllHermitShells()
            startAutoHermitClaim()
        end
    end
})

Tabs.Crab:CreateSection("Upgrades")
Tabs.Crab:CreateDropdown("HermitUpgrades", {
    Title = "Select Upgrades",
    Values = getHermitUpgradeList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Crab.SelectedUpgrades = V
end)
Tabs.Crab:CreateToggle("AutoUpgrade", {
    Title = "Auto Upgrade Selected",
    Default = false,
    Callback = function(V)
        Settings.Crab.AutoUpgrade = V
        if V then startAutoHermitUpgrade() end
    end
})

--========================================================
-- TAB: TRAIT REROLL
--========================================================
Tabs.Trait:CreateSection("Current Information")

local TraitInfo = Tabs.Trait:CreateParagraph("TraitInfo", {
    Title = "Trait Information",
    Content = "Loading..."
})

task.spawn(function()
    while true do
        pcall(function()
            local text = string.format(
                "Tool   : %s\nTrait  : %s\nPity   : %s\nPearls : %s\n\n━━━━━━━━━━━━━━\n\nInstructions:\n1. Open Equipment\n2. Enter Trait Reroll mode, that tool you want\n3. Choose your Target Trait\n4. Enable Auto Trait Reroll",
                getCurrentTool(),
                getCurrentTrait(),
                getCurrentPityText(),
                getCurrentPearls()
            )
            TraitInfo:SetValue(text)
        end)
        task.wait(1)
    end
end)

Tabs.Trait:CreateDropdown("TargetTrait", {
    Title = "Target Trait",
    Values = getTraitList(),
    Multi = false,
    Default = nil
}):OnChanged(function(V)
    Settings.Trait.TargetTrait = V
end)
Tabs.Trait:CreateToggle("AutoTraitReroll", {
    Title = "Auto Trait Reroll",
    Default = false,
    Callback = function(V)
        Settings.Trait.AutoReroll = V
        if V and Settings.Trait.TargetTrait then
            startAutoTraitReroll()
        end
    end
})

--========================================================
-- TAB: MERCHANT
--========================================================

local KnownMerchantItems = {
    "Abyssal Charm", "Colossus Charm", "Coral Charm", "Crystal Charm",
    "Driftwood Charm", "Eclipse Charm", "Leviathan Charm", "Moonstone Charm",
    "Pebble Charm", "Prism Charm", "Sea Glass Charm", "Starfish Charm",
    "Tidal Charm", "Tide Charm", "Void Charm", "Crab Treat", "Pearl", "Mystic Shell"
}
Tabs.Merchant:CreateSection("Auto Buy Items")
Tabs.Merchant:CreateDropdown("MerchantItems", {
    Title = "Select Known Items",
    Values = KnownMerchantItems,
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Merchant.SelectedItems = V
end)
Tabs.Merchant:CreateToggle("AutoBuyMerchant", {
    Title = "Enable Auto Buy Merchant",
    Default = false,
    Callback = function(V)
        Settings.Merchant.AutoBuy = V
        if V then startAutoBuyMerchant() end
    end
})

--========================================================
-- TAB: TELEPORT
--========================================================

Tabs.Teleport:CreateSection("Island Teleport")
Tabs.Teleport:CreateDropdown("SelectedIsland", {
    Title = "Select Island",
    Values = IslandNames,
    Multi = false,
    Default = nil
}):OnChanged(function(V)
    Settings.Teleport.SelectedIsland = V
end)
Tabs.Teleport:CreateButton({ Title = "🚀 Teleport Instan ke Pulau", Callback = function()
    if Settings.Teleport.SelectedIsland then
        tpTo(TeleportLocations.Islands[Settings.Teleport.SelectedIsland] + Vector3.new(0, 5, 0))
    end
end })

Tabs.Teleport:CreateSection("NPC Teleport")
Tabs.Teleport:CreateDropdown("SelectedNPC", {
    Title = "Select NPC",
    Values = NpcNames,
    Multi = false,
    Default = nil
}):OnChanged(function(V)
    Settings.Teleport.SelectedNpc = V
end)
Tabs.Teleport:CreateButton({ Title = "🚀 Teleport Instan ke NPC", Callback = function()
    if Settings.Teleport.SelectedNpc then
        tpTo(TeleportLocations.NPCs[Settings.Teleport.SelectedNpc] + Vector3.new(0, 5, 0))
    end
end })

--========================================================
-- TAB: WEBHOOK
--========================================================
Tabs.Webhook:CreateSection("Discord Webhook Settings")

local WebhookInput = Tabs.Webhook:CreateInput("WebhookUrl", {
    Title = "Webhook URL",
    Default = Settings.Webhook.Url,
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        Settings.Webhook.Url = Value
        SaveManager:Save()
        Fluent:Notify({
            Title = "Webhook",
            Content = "URL saved!",
            Duration = 1
        })
    end
})

Tabs.Webhook:CreateButton({
    Title = "🔔 Test Webhook",
    Callback = function()
        local url = Settings.Webhook.Url
        if url == nil or url == "" then
            Fluent:Notify({
                Title = "Webhook Error",
                Content = "Please enter a valid webhook URL first.",
                Duration = 3
            })
            return
        end

        local testPayload = {
            content = "🐚 Sobat Kerang webhook is working! Test message."
        }

        local success = sendDiscordWebhook(url, testPayload)
        if success then
            Fluent:Notify({
                Title = "Webhook Test",
                Content = "Test notification sent to Discord!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Webhook Error",
                Content = "Failed to send test. Check your URL and console.",
                Duration = 5
            })
        end
    end
})

Tabs.Webhook:CreateDropdown("WebhookRarities", {
    Title = "Notify on Rarities",
    Values = getRarityList(),
    Multi = true,
    Default = {}
}):OnChanged(function(V)
    Settings.Webhook.SelectedRarities = V
    SaveManager:Save()
end)

Tabs.Webhook:CreateToggle("WebhookEnabled", {
    Title = "Enable Webhook Notifications",
    Default = false,
    Callback = function(V)
        Settings.Webhook.Enabled = V
        SaveManager:Save()
        if V then
            Fluent:Notify({
                Title = "Webhook",
                Content = "Webhook monitoring started!",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Webhook",
                Content = "Webhook monitoring stopped.",
                Duration = 2
            })
        end
    end
})

--========================================================
-- MANAGEMENT SETUP (INTERFACE & SAVE)
--========================================================

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("SobatKerangHub")
SaveManager:SetFolder("SobatKerangHub/SobatKerangAjaib")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

--========================================================
-- FINALIZE EXECUTION & ANTI-AFK
--========================================================

Window:SelectTab(2) -- Pilih Auto Farm tab
Fluent:Notify({
    Title = "Sobat Kerang",
    Content = "SAATNYA SOBAT KERANG BERAKSI!",
    Duration = 5
})
SaveManager:LoadAutoloadConfig()

-- Anti-AFK Otomatis
if not Runtime.AntiAfkConn then
    Runtime.AntiAfkConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        print("[Sobat Kerang] Timer AFK direset!")
    end)
end

-- Cleanup function (called when script is re-run)
getgenv().SobatKerangCleanup = function()
    pcall(function()
        if CoreGui:FindFirstChild("SobatKerangFloating") then
            CoreGui.SobatKerangFloating:Destroy()
        end
    end)
    pcall(function()
        -- Stop webhook monitor properly
        Runtime.WebhookMonitorActive = false
        if Runtime.WebhookMonitorConn then
            Runtime.WebhookMonitorConn:Disconnect()
            Runtime.WebhookMonitorConn = nil
        end
        -- Disconnect anti-afk
        if Runtime.AntiAfkConn then
            Runtime.AntiAfkConn:Disconnect()
            Runtime.AntiAfkConn = nil
        end
        -- Destroy UI window
        Window:Destroy()
    end)
end

print("SCRIPT END")
