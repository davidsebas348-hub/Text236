-- ===== SERVICES =====
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ===== TOGGLE =====
if _G.AUTO_Q_WALL_CONN then
    _G.AUTO_Q_WALL_CONN:Disconnect()
    _G.AUTO_Q_WALL_CONN = nil
    return
end

-- ===== CONFIG =====
local RANGE = 15          -- rango para detectar jugadores/NPCs adelante
local M1_THRESHOLD = 4    -- activar Q cuando haya 4 M1ing
local RESET_THRESHOLD = 5 -- reiniciar si hay 5 M1ing
local TIMEOUT = 1.5       -- reiniciar si no aparece ninguno en 1.5 seg

-- Variables de control
local m1ingCount = 0
local seenM1ing = {}
local lastM1ingTime = 0

-- ===== FUNCIONES =====

-- Obtener modelo del jugador
local function getMyModel()
    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return nil end
    return liveFolder:FindFirstChild(LocalPlayer.Name)
end

-- Simular tecla Q
local function pressQ()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end

-- Detectar pared adelante usando un “cajón”
local function isWallAhead()
    local character = LocalPlayer.Character
    if not character then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local boxSize = Vector3.new(10, 10, 10) -- ancho, alto, profundidad
    local boxCFrame = rootPart.CFrame * CFrame.new(0, 0, boxSize.Z/2 + 2)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {character}

    local parts = Workspace:GetPartBoundsInBox(boxCFrame, boxSize, params)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            return true
        end
    end

    return false
end

-- Obtener objetivos adelante (jugadores, NPCs o Parts HumanoidRootPart)
local function getTargetsAhead()
    local character = LocalPlayer.Character
    if not character then return {} end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local targets = {}
    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return targets end

    for _, obj in ipairs(liveFolder:GetChildren()) do
        -- Si es modelo con HumanoidRootPart
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj ~= character then
            local objHRP = obj.HumanoidRootPart
            local direction = (objHRP.Position - hrp.Position).Unit
            local distance = (objHRP.Position - hrp.Position).Magnitude
            if distance <= RANGE and hrp.CFrame.LookVector:Dot(direction) > 0 then
                table.insert(targets, objHRP)
            end
        end
        -- Si es Part llamado HumanoidRootPart
        if obj:IsA("BasePart") and obj.Name == "HumanoidRootPart" then
            local direction = (obj.Position - hrp.Position).Unit
            local distance = (obj.Position - hrp.Position).Magnitude
            if distance <= RANGE and hrp.CFrame.LookVector:Dot(direction) > 0 then
                table.insert(targets, obj)
            end
        end
    end

    return targets
end

-- ===== LOOP PRINCIPAL =====
_G.AUTO_Q_WALL_CONN = RunService.Heartbeat:Connect(function()
    local myModel = getMyModel()
    if not myModel then
        seenM1ing = {}
        m1ingCount = 0
        return
    end

    local newM1Detected = false

    -- Contar M1ing
    for _, child in ipairs(myModel:GetChildren()) do
        if child.Name:lower() == "m1ing" and not seenM1ing[child] then
            seenM1ing[child] = true
            m1ingCount += 1
            newM1Detected = true
            lastM1ingTime = tick()
        end
    end

    -- Reiniciar si pasa timeout sin M1ing
    if not newM1Detected and m1ingCount > 0 and (tick() - lastM1ingTime) > TIMEOUT then
        seenM1ing = {}
        m1ingCount = 0
    end

    -- Reiniciar si alcanza 5
    if m1ingCount >= RESET_THRESHOLD then
        seenM1ing = {}
        m1ingCount = 0
    end

    -- Activar Q si hay exactamente 4 M1ing y hay objetivo adelante y pared adelante
    if m1ingCount == M1_THRESHOLD then
        local targets = getTargetsAhead()
        if #targets > 0 and isWallAhead() then
            pressQ()
        end
    end
end)
