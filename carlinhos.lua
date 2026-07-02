--[[
    Carlinhos Chan v11.0 – Nova interface, Boneco R6, Foco em partes do corpo
    by DAN
    Compatível com JJsploit
--]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")

-- ========== CONFIGS ==========
local cfg = {
    aimbotHard = false,
    aimbotSoft = false,
    wallhack = false,
    pullAll = false,
    teamCheck = true,
    errorRate = 20,
    fovRadius = 30,
    aimSmoothness = 0.15,
    focusEnabled = false,      -- foco em parte específica
    targetPart = "Head",       -- parte do corpo selecionada
}

-- ========== PERSONAGEM ==========
repeat wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head")
local char = player.Character
local root = char.HumanoidRootPart
local head = char.Head

player.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
    head = c:WaitForChild("Head")
end)

-- ========== UTILITÁRIOS ==========
local function getBodyPart(character, partName)
    -- Mapeia nomes comuns para as partes do corpo
    local map = {
        Head = "Head",
        Torso = "Torso",
        ["Left Arm"] = "Left Arm",
        ["Right Arm"] = "Right Arm",
        ["Left Leg"] = "Left Leg",
        ["Right Leg"] = "Right Leg",
        UpperTorso = "UpperTorso",
        LowerTorso = "LowerTorso",
    }
    local target = map[partName]
    if target and character:FindFirstChild(target) then
        return character[target]
    end
    return nil
end

-- ========== ALVOS ==========
local function getAlvos()
    local alvos = {}
    if not root or not root.Parent then return alvos end
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character then
            local c = p.Character
            local h = c:FindFirstChild("Humanoid")
            local cabeca = c:FindFirstChild("Head")
            local rp = c:FindFirstChild("HumanoidRootPart")
            if h and cabeca and rp and h.Health > 0 then
                if cfg.teamCheck and player.Team and p.Team == player.Team then
                    -- ignora time
                else
                    local dist = (root.Position - rp.Position).Magnitude
                    local screenPos, onScreen = camera:WorldToViewportPoint(cabeca.Position)
                    table.insert(alvos, {
                        player = p,
                        char = c,
                        head = cabeca,
                        rootPart = rp,
                        distancia = dist,
                        onScreen = onScreen,
                        screenPos = Vector2.new(screenPos.X, screenPos.Y),
                    })
                end
            end
        end
    end
    table.sort(alvos, function(a, b) return a.distancia < b.distancia end)
    return alvos
end

-- Retorna o ponto de mira de acordo com a parte selecionada
local function getAimPosition(alvo)
    if cfg.focusEnabled and cfg.targetPart then
        local part = getBodyPart(alvo.char, cfg.targetPart)
        if part then
            return part.Position
        end
    end
    return alvo.head.Position -- fallback para cabeça
end

-- ========== AIMBOT HARD ==========
spawn(function()
    while wait(0.01) do
        if cfg.aimbotHard and not cfg.aimbotSoft then
            local alvo = getAlvos()[1]
            if alvo then
                camera.CameraType = Enum.CameraType.Custom
                local pos = getAimPosition(alvo)
                camera.CFrame = CFrame.new(camera.CFrame.Position, pos)
            end
        end
    end
end)

-- ========== AIMBOT SOFT ==========
spawn(function()
    while wait(0.01) do
        if cfg.aimbotSoft and not cfg.aimbotHard then
            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local melhor = nil
            local melhorDist = cfg.fovRadius
            for _, alvo in ipairs(getAlvos()) do
                if alvo.onScreen then
                    local d = (alvo.screenPos - center).Magnitude
                    if d < melhorDist then
                        melhorDist = d
                        melhor = alvo
                    end
                end
            end
            if melhor then
                camera.CameraType = Enum.CameraType.Custom
                local pos = getAimPosition(melhor)
                local desiredCF = CFrame.new(camera.CFrame.Position, pos)
                camera.CFrame = camera.CFrame:Lerp(desiredCF, cfg.aimSmoothness)
                if math.random(100) <= cfg.errorRate then
                    local offset = Vector3.new(math.random(-2, 2), math.random(-1, 1), math.random(-2, 2))
                    camera.CFrame = CFrame.new(camera.CFrame.Position, pos + offset)
                end
            end
        end
    end
end)

-- ========== WALLHACK ==========
local espName = "CarlinhosESP_" .. math.random(1000, 9999)
spawn(function()
    while wait(0.3) do
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character then
                local box = p.Character:FindFirstChild(espName)
                if box then box:Destroy() end
            end
        end
        if cfg.wallhack then
            for _, alvo in ipairs(getAlvos()) do
                local c = alvo.char
                if c and not c:FindFirstChild(espName) then
                    local box = Instance.new("BillboardGui")
                    box.Name = espName
                    box.Size = UDim2.new(4, 0, 6, 0)
                    box.StudsOffset = Vector3.new(0, 3, 0)
                    box.AlwaysOnTop = true
                    box.MaxDistance = math.huge
                    box.Parent = c
                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundTransparency = 0.3
                    frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    frame.BorderSizePixel = 3
                    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
                    frame.Parent = box
                end
            end
        end
    end
end)

-- ========== PUXAR TODOS + AUTO-FIRE ==========
spawn(function()
    while wait(0.15) do
        if cfg.pullAll and root and root.Parent then
            local pos = root.CFrame * CFrame.new(0, 0, -10).Position
            local todos = {}
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local rp = p.Character:FindFirstChild("HumanoidRootPart")
                    if rp then
                        table.insert(todos, rp)
                    end
                end
            end
            for _, part in ipairs(todos) do part.Anchored = true end
            for _, part in ipairs(todos) do
                part.CFrame = CFrame.new(pos) * CFrame.new(0, part.Size.Y / 2, 0)
            end
            for _, part in ipairs(todos) do part.Anchored = false end

            -- Auto-fire mirando na parte selecionada
            local alvo = getAlvos()[1]
            if alvo then
                local aimPos = getAimPosition(alvo)
                camera.CFrame = CFrame.new(camera.CFrame.Position, aimPos)
            end
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            wait(0.05)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- ========== INTERFACE NOVA ==========
local gui = Instance.new("ScreenGui")
gui.Name = "CarlinhosChanGUI"
gui.ResetOnSpawn = false
gui.ZIndex = 100
gui.Parent = player.PlayerGui

-- Fundo do cheat com imagem (placeholder)
local bgImage = "rbxassetid://123456789" -- substitua pelo seu ID de imagem

-- Painel principal (retângulo)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 400)
main.Position = UDim2.new(0.5, -210, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Fundo com imagem (opcional)
local fundo = Instance.new("ImageLabel")
fundo.Image = bgImage
fundo.Size = UDim2.new(1, 0, 1, 0)
fundo.BackgroundTransparency = 1
fundo.ScaleType = Enum.ScaleType.Crop
fundo.Parent = main

-- Barra de título
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Text = "Carlinhos Chan v11"
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 140, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = titleBar

-- Botão X (fechar)
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0.5, -17)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 17)

-- Botão flutuante ⚡ (com imagem personalizada se quiser)
local ball = Instance.new("ImageButton")  -- ou TextButton se prefirir texto
ball.Size = UDim2.new(0, 55, 0, 55)
ball.Position = UDim2.new(0.02, 0, 0.5, -27)
ball.Image = bgImage -- mesma imagem, ou "rbxassetid://" da bolinha
ball.BackgroundTransparency = 0.2
ball.Visible = true
ball.Parent = gui
Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

-- Menu lateral (direita) com ícones
local sideBar = Instance.new("Frame")
sideBar.Size = UDim2.new(0, 60, 1, -40)
sideBar.Position = UDim2.new(1, -60, 0, 40)
sideBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
sideBar.BorderSizePixel = 0
sideBar.Parent = main

-- Área de conteúdo
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -70, 1, -40)
content.Position = UDim2.new(0, 5, 0, 40)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Parent = main

-- Navegação entre abas
local currentTab = "Aimbot"
local pages = {}

local function switchTab(tabName)
    for name, page in pairs(pages) do
        page.Visible = false
    end
    if pages[tabName] then
        pages[tabName].Visible = true
        currentTab = tabName
    end
end

-- Função para criar ícones na barra lateral
local function createSideIcon(order, text, tabName)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 5, 0, 10 + (order - 1) * 55)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    btn.Parent = sideBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
        -- destaque visual
        for _, b in pairs(sideBar:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(50, 50, 55) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    end)
    return btn
end

-- Ícones do menu
createSideIcon(1, "🎯", "Aimbot")   -- Aimbot
createSideIcon(2, "👁", "Visual")   -- Wallhack
createSideIcon(3, "🧍", "Alvo")     -- Boneco R6
createSideIcon(4, "🧲", "Puxar")    -- Puxar todos
createSideIcon(5, "⚙", "Config")   -- Configurações extras

-- ========== PÁGINA AIMBOT ==========
local aimPage = Instance.new("ScrollingFrame")
aimPage.Size = UDim2.new(1, -10, 1, -10)
aimPage.Position = UDim2.new(0, 5, 0, 5)
aimPage.BackgroundTransparency = 1
aimPage.ScrollBarThickness = 4
aimPage.CanvasSize = UDim2.new(0, 0, 0, 300)
aimPage.Parent = content
pages["Aimbot"] = aimPage

-- Função para criar toggle em qualquer página
local function addToggle(page, y, nome, padrao, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 40)
    f.Position = UDim2.new(0, 10, 0, y)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    f.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Text = nome
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0.05, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Text = padrao and "ON" or "OFF"
    btn.Size = UDim2.new(0, 55, 0, 25)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = padrao and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    btn.Parent = f

    local state = padrao
    local function atualizar()
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
        callback(state)
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        atualizar()
    end)
    return { atualizar = atualizar }
end

local function addSlider(page, y, nome, min, max, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 50)
    f.Position = UDim2.new(0, 10, 0, y)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    f.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Text = nome .. ": " .. tostring(default)
    lbl.Size = UDim2.new(1, -20, 0, 25)
    lbl.Position = UDim2.new(0.05, 0, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = f

    local txt = Instance.new("TextBox")
    txt.Text = tostring(default)
    txt.Size = UDim2.new(1, -20, 0, 20)
    txt.Position = UDim2.new(0.05, 0, 0, 25)
    txt.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.Font = Enum.Font.Code
    txt.TextSize = 11
    Instance.new("UICorner", txt).CornerRadius = UDim.new(0, 4)
    txt.Parent = f

    txt.FocusLost:Connect(function()
        local num = tonumber(txt.Text)
        if num then
            num = math.clamp(num, min, max)
            txt.Text = tostring(num)
            lbl.Text = nome .. ": " .. tostring(num)
            callback(num)
        else
            txt.Text = tostring(default)
        end
    end)
end

-- Preenche página Aimbot
local aimHardTog = addToggle(aimPage, 10, "Aimbot Hard", false, function(on)
    cfg.aimbotHard = on
    if on then
        cfg.aimbotSoft = false
        aimSoftTog.atualizar()
    end
end)
local aimSoftTog = addToggle(aimPage, 60, "Aimbot Soft", false, function(on)
    cfg.aimbotSoft = on
    if on then
        cfg.aimbotHard = false
        aimHardTog.atualizar()
    end
end)
addSlider(aimPage, 110, "Raio Soft (px)", 5, 200, cfg.fovRadius, function(val) cfg.fovRadius = val end)
addSlider(aimPage, 170, "Taxa de Erro %", 0, 100, cfg.errorRate, function(val) cfg.errorRate = val end)

-- ========== PÁGINA VISUAL (Wallhack) ==========
local visPage = Instance.new("ScrollingFrame")
visPage.Size = UDim2.new(1, -10, 1, -10)
visPage.Position = UDim2.new(0, 5, 0, 5)
visPage.BackgroundTransparency = 1
visPage.ScrollBarThickness = 4
visPage.CanvasSize = UDim2.new(0, 0, 0, 100)
visPage.Visible = false
visPage.Parent = content
pages["Visual"] = visPage

addToggle(visPage, 10, "Wallhack", false, function(on) cfg.wallhack = on end)

-- ========== PÁGINA ALVO (Boneco R6) ==========
local alvoPage = Instance.new("Frame")
alvoPage.Size = UDim2.new(1, -10, 1, -10)
alvoPage.Position = UDim2.new(0, 5, 0, 5)
alvoPage.BackgroundTransparency = 1
alvoPage.Visible = false
alvoPage.Parent = content
pages["Alvo"] = alvoPage

-- Boneco R6 2D (desenhado com frames)
local doll = Instance.new("Frame")
doll.Size = UDim2.new(0, 100, 0, 180)
doll.Position = UDim2.new(0.5, -50, 0.1, 0)
doll.BackgroundTransparency = 1
doll.Parent = alvoPage

-- Partes do boneco
local parts = {
    { name = "Head", color = Color3.fromRGB(255, 200, 150), sizeX = 40, sizeY = 40, posX = 30, posY = 0 },
    { name = "Torso", color = Color3.fromRGB(100, 150, 255), sizeX = 30, sizeY = 50, posX = 35, posY = 45 },
    { name = "Left Arm", color = Color3.fromRGB(255, 200, 150), sizeX = 15, sizeY = 50, posX = 15, posY = 45 },
    { name = "Right Arm", color = Color3.fromRGB(255, 200, 150), sizeX = 15, sizeY = 50, posX = 70, posY = 45 },
    { name = "Left Leg", color = Color3.fromRGB(80, 80, 200), sizeX = 18, sizeY = 55, posX = 25, posY = 100 },
    { name = "Right Leg", color = Color3.fromRGB(80, 80, 200), sizeX = 18, sizeY = 55, posX = 57, posY = 100 },
}

local selectedPart = "Head"
local partButtons = {}

for _, partData in ipairs(parts) do
    local partBtn = Instance.new("TextButton")
    partBtn.Size = UDim2.new(0, partData.sizeX, 0, partData.sizeY)
    partBtn.Position = UDim2.new(0, partData.posX, 0, partData.posY)
    partBtn.BackgroundColor3 = partData.color
    partBtn.BorderSizePixel = 0
    partBtn.Text = ""
    partBtn.Parent = doll
    Instance.new("UICorner", partBtn).CornerRadius = UDim.new(0, 8)

    partBtn.MouseButton1Click:Connect(function()
        -- Reseta todas as cores
        for _, b in pairs(partButtons) do
            b.BackgroundColor3 = b.Tag or Color3.fromRGB(200, 200, 200) -- restaura cor original
        end
        -- Destaca a selecionada em vermelho
        partBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        selectedPart = partData.name
        cfg.targetPart = selectedPart
    end)

    partBtn.Tag = partData.color -- guarda a cor original
    table.insert(partButtons, partBtn)
end

-- Destaque inicial na cabeça
partButtons[1].BackgroundColor3 = Color3.fromRGB(255, 0, 0)

-- Controles de foco abaixo do boneco
local focusFrame = Instance.new("Frame")
focusFrame.Size = UDim2.new(1, -10, 0, 80)
focusFrame.Position = UDim2.new(0, 5, 0, 230)
focusFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Instance.new("UICorner", focusFrame).CornerRadius = UDim.new(0, 8)
focusFrame.Parent = alvoPage

local focusLabel = Instance.new("TextLabel")
focusLabel.Text = "Foco: " .. selectedPart
focusLabel.Size = UDim2.new(1, -10, 0, 25)
focusLabel.Position = UDim2.new(0, 5, 0, 5)
focusLabel.BackgroundTransparency = 1
focusLabel.TextColor3 = Color3.new(1, 1, 1)
focusLabel.Font = Enum.Font.GothamBold
focusLabel.TextSize = 14
focusLabel.Parent = focusFrame

-- Botão "Ativar Foco" e toggle ON/OFF lado a lado
local focusBtn = Instance.new("TextButton")
focusBtn.Text = "Ativar Foco"
focusBtn.Size = UDim2.new(0, 100, 0, 30)
focusBtn.Position = UDim2.new(0, 10, 0, 35)
focusBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
focusBtn.TextColor3 = Color3.new(1, 1, 1)
focusBtn.Font = Enum.Font.GothamBold
focusBtn.TextSize = 13
Instance.new("UICorner", focusBtn).CornerRadius = UDim.new(0, 8)
focusBtn.Parent = focusFrame

local focusToggle = Instance.new("TextButton")
focusToggle.Text = "OFF"
focusToggle.Size = UDim2.new(0, 60, 0, 30)
focusToggle.Position = UDim2.new(0, 120, 0, 35)
focusToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
focusToggle.TextColor3 = Color3.new(1, 1, 1)
focusToggle.Font = Enum.Font.GothamBold
focusToggle.TextSize = 13
Instance.new("UICorner", focusToggle).CornerRadius = UDim.new(0, 8)
focusToggle.Parent = focusFrame

focusBtn.MouseButton1Click:Connect(function()
    cfg.targetPart = selectedPart
    focusLabel.Text = "Foco: " .. selectedPart
end)

local focusState = false
focusToggle.MouseButton1Click:Connect(function()
    focusState = not focusState
    cfg.focusEnabled = focusState
    focusToggle.Text = focusState and "ON" or "OFF"
    focusToggle.BackgroundColor3 = focusState and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

-- ========== PÁGINA PUXAR ==========
local pullPage = Instance.new("ScrollingFrame")
pullPage.Size = UDim2.new(1, -10, 1, -10)
pullPage.Position = UDim2.new(0, 5, 0, 5)
pullPage.BackgroundTransparency = 1
pullPage.ScrollBarThickness = 4
pullPage.CanvasSize = UDim2.new(0, 0, 0, 100)
pullPage.Visible = false
pullPage.Parent = content
pages["Puxar"] = pullPage

addToggle(pullPage, 10, "Puxar TODOS", false, function(on) cfg.pullAll = on end)

-- ========== PÁGINA CONFIG ==========
local configPage = Instance.new("ScrollingFrame")
configPage.Size = UDim2.new(1, -10, 1, -10)
configPage.Position = UDim2.new(0, 5, 0, 5)
configPage.BackgroundTransparency = 1
configPage.ScrollBarThickness = 4
configPage.CanvasSize = UDim2.new(0, 0, 0, 100)
configPage.Visible = false
configPage.Parent = content
pages["Config"] = configPage

addToggle(configPage, 10, "Team Check", true, function(on) cfg.teamCheck = on end)

-- ========== CONTROLES DE MENU ==========
local function abrirMenu()
    main.Visible = true
    ball.Visible = false
    uis.MouseBehavior = Enum.MouseBehavior.Default
end

local function fecharMenu()
    main.Visible = false
    uis.MouseBehavior = Enum.MouseBehavior.LockCenter
    ball.Visible = true
end

closeBtn.MouseButton1Click:Connect(fecharMenu)
ball.MouseButton1Click:Connect(abrirMenu)

-- Arrastar
local dragging, startPos, startMouse
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startPos = main.Position
        startMouse = input.Position
    end
end)
uis.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - startMouse
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Atalhos TAB e RightShift
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.RightShift then
        if main.Visible then
            fecharMenu()
        else
            abrirMenu()
        end
    end
end)

-- Inicial
uis.MouseBehavior = Enum.MouseBehavior.LockCenter
ball.Visible = true
