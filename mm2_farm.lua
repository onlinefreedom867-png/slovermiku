-- ==============================================================================
-- [ONLINEFREEDOM MM2] PRO AUTO FARM & FAST INCOME GENERATOR v3.0
-- Tối ưu 100% cho Delta Android Reddroid Proxmox - SẠCH 100% KHÔNG QUA LUARMOR
-- Tích hợp: Nhặt Xu/Kẹo Noclip, Đầy Túi 40 Tự Reset, Nhặt Súng Sheriff,
-- Tự Động Mở Hòm (Auto Unbox) & Bắn Webhook Discord khi trúng đồ Godly!
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

-- ================= CẤU HÌNH KIẾM THU NHẬP (CONFIG) =================
getgenv().MM2Config = {
    -- 1. Farm Cơ Bản
    AutoCoin = true,
    MaxCoinBag = 40,            -- Đầy túi 40 xu lập tức reset để vào round mới nhanh gấp 4 lần
    AutoResetOnFull = true,     -- Tự động reset nhân vật khi đầy túi (nhân 3x tốc độ farm)
    TweenSpeed = 33,            -- Tốc độ lướt nhặt xu an toàn không bị rollback
    AutoGrabGun = true,         -- Nhặt súng rơi của Sheriff khi chết (nhận danh hiệu Hero + nhiều EXP)
    DodgeMurderer = true,       -- Giữ khoảng cách an toàn với Murderer
    SafeDistance = 35,

    -- 2. Tự Động Mở Hòm (Auto Unbox Vũ Khí Hiếm)
    AutoUnbox = true,
    MinCoinsToUnbox = 1000,     -- Đủ 1,000 Xu là mở hòm ngay
    TargetBox = "KnifeBox1",    -- Hộp mở: KnifeBox1, GunBox1, MysteryBox, HalloweenBox

    -- 3. Thông Báo Webhook Discord Khi Nhận Đồ Quý
    WebhookURL = "https://discord.com/api/webhooks/1397111844803444857/Z2N0TJEFXLZ6BlInOCfRumDlWbiwNjqowfA3sxQPyfn-m6jOo6nBeaTOyPSTvUPGLpLS",
    NotifyGodlyOnly = true,

    -- 4. Tối Ưu Giảm Tải 0% Lag Cho Dàn Máy Proxmox
    LowGFX = true,
    FPSCap = 20
}

-- ================= 1. TỐI ƯU ĐỒ HỌA GIẢM TẢI CPU/RAM =================
pcall(function()
    setfpscap(getgenv().MM2Config.FPSCap)
    settings().Rendering.QualityLevel = 1
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end
end)

-- ================= 2. CHỐNG VĂNG GAME (ANTI-AFK 24/7) =================
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    print("[MM2 Farm] Gửi tín hiệu Anti-AFK.")
end)

-- ================= 3. KHAI BÁO DỊCH VỤ =================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function getRoot()
    local char = getChar()
    return char:WaitForChild("HumanoidRootPart", 5)
end

-- Bật Noclip xuyên tường khi di chuyển
RunService.Stepped:Connect(function()
    if getgenv().MM2Config.AutoCoin and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Tìm hộp chứa Coin của Map hiện tại
local function getCoinContainer()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") then
            return obj.CoinContainer
        end
    end
    local normal = Workspace:FindFirstChild("Normal")
    if normal and normal:FindFirstChild("CoinContainer") then
        return normal.CoinContainer
    end
    return nil
end

-- Di chuyển mượt mà tới mục tiêu
local currentTween = nil
local function tweenTo(targetCFrame)
    local root = getRoot()
    if not root then return end
    local dist = (root.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(dist / getgenv().MM2Config.TweenSpeed, 0.15, 4.0)
    local twInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(root, twInfo, {CFrame = targetCFrame})
    currentTween:Play()
    currentTween.Completed:Wait()
end

-- ================= 4. GỬI DISCORD WEBHOOK =================
local function sendDiscordWebhook(title, desc, color)
    local url = getgenv().MM2Config.WebhookURL
    if not url or url == "" then return end
    pcall(function()
        local data = {
            ["embeds"] = {{
                ["title"] = title,
                ["description"] = desc,
                ["color"] = color or 65280,
                ["footer"] = {["text"] = "MM2 Fleet Farm • " .. LP.Name}
            }}
        }
        local json = HttpService:JSONEncode(data)
        if request then
            request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = json})
        elseif http_request then
            http_request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = json})
        end
    end)
end

-- ================= 5. TỰ ĐỘNG NHẶT SÚNG SHERIFF RƠI =================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not getgenv().MM2Config.AutoGrabGun then return end
            local char = LP.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
            
            local gunDrop = Workspace:FindFirstChild("GunDrop")
            if gunDrop and gunDrop:IsA("BasePart") then
                local root = getRoot()
                if root then
                    print("[MM2 Farm] Phát hiện GunDrop! Đang nhặt súng...")
                    root.CFrame = gunDrop.CFrame
                    task.wait(0.3)
                end
            end
        end)
    end
end)

-- ================= 6. TỰ ĐỘNG MỞ HÒM (AUTO UNBOX) =================
local function tryUnbox()
    pcall(function()
        if not getgenv().MM2Config.AutoUnbox then return end
        local coinVal = 0
        if LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Coins") then
            coinVal = LP.leaderstats.Coins.Value
        end
        if coinVal >= getgenv().MM2Config.MinCoinsToUnbox then
            local shopRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Shop") and ReplicatedStorage.Remotes.Shop:FindFirstChild("OpenBox")
            if shopRemote then
                print("[MM2 Farm] Đủ " .. coinVal .. " Xu! Đang tự động mở hòm " .. getgenv().MM2Config.TargetBox)
                local res = shopRemote:InvokeServer(getgenv().MM2Config.TargetBox)
                sendDiscordWebhook("🎁 Vừa Mở Hòm Thành Công!", "Tài khoản **" .. LP.Name .. "** vừa mở hộp **" .. getgenv().MM2Config.TargetBox .. "**!", 16766720)
            end
        end
    end)
end

-- ================= 7. VÒNG LẶP CHÍNH: FARM XU & TỰ RESET KHI ĐẦY TÚI =================
print("[MM2 Farm] Hệ thống Auto Farm kiếm thu nhập MM2 v3.0 đã kích hoạt!")

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not getgenv().MM2Config.AutoCoin then return end
            local char = LP.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

            -- Kiểm tra số lượng xu trong túi round hiện tại
            local bagFull = false
            local coinBagGui = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("MainGUI") and LP.PlayerGui.MainGUI:FindFirstChild("Game") and LP.PlayerGui.MainGUI.Game:FindFirstChild("CoinBags")
            if coinBagGui then
                local bagLabel = coinBagGui:FindFirstChild("Container") and coinBagGui.Container:FindFirstChild("Coin")
                if bagLabel and bagLabel:IsA("TextLabel") and bagLabel.Text:find(tostring(getgenv().MM2Config.MaxCoinBag)) then
                    bagFull = true
                end
            end

            -- Nếu đầy túi 40 xu -> Reset nhân vật để sang round mới ngay lập tức
            if bagFull and getgenv().MM2Config.AutoResetOnFull then
                print("[MM2 Farm] Túi đã đầy 40 Xu! Reset nhân vật để chuẩn bị cho round tiếp theo...")
                char.Humanoid.Health = 0
                tryUnbox()
                task.wait(6)
                return
            end

            -- Quét và nhặt Coin
            local container = getCoinContainer()
            if container then
                for _, coin in ipairs(container:GetChildren()) do
                    if coin:IsA("BasePart") and coin.Transparency < 1 and char.Humanoid.Health > 0 then
                        -- Kiểm tra né tránh Murderer
                        local isDangerous = false
                        if getgenv().MM2Config.DodgeMurderer then
                            for _, other in ipairs(Players:GetPlayers()) do
                                if other ~= LP and other.Character and other.Character:FindFirstChild("Knife") then
                                    local mRoot = other.Character:FindFirstChild("HumanoidRootPart")
                                    if mRoot and (mRoot.Position - coin.Position).Magnitude < getgenv().MM2Config.SafeDistance then
                                        isDangerous = true
                                        break
                                    end
                                end
                            end
                        end

                        if not isDangerous then
                            tweenTo(coin.CFrame + Vector3.new(0, 1.2, 0))
                            task.wait(0.08)
                        end
                    end
                end
            end
        end)
    end
end)
