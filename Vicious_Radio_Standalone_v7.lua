-- ============================================================
-- VICIOUS RADIO (standalone) v7
-- Neon UI + Mini-Modus + Farbwahl + Hoehen-Anpassung + Library
-- Toggle UI: RightControl   |   Mini-Modus: RightShift
-- ============================================================

if _G.ViciousRadioStandalone and type(_G.ViciousRadioStandalone.destroy) == "function" then
    pcall(_G.ViciousRadioStandalone.destroy)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local CONFIG_FILE = "ViciousRadio_Config.json"

----------------------------------------------------------------
-- Executor file API (robust)
----------------------------------------------------------------
local _writefile = (type(writefile) == "function" and writefile)
    or (syn and type(syn.writefile) == "function" and syn.writefile) or nil
local _readfile = (type(readfile) == "function" and readfile)
    or (syn and type(syn.readfile) == "function" and syn.readfile) or nil
local _isfile = (type(isfile) == "function" and isfile)
    or (syn and type(syn.isfile) == "function" and syn.isfile)
    or function(path)
        if not _readfile then return false end
        local ok, res = pcall(_readfile, path)
        return ok and type(res) == "string"
    end

local function getAssetFunc()
    if type(getcustomasset) == "function" then return getcustomasset end
    if type(getsynasset) == "function" then return getsynasset end
    if syn and type(syn.getcustomasset) == "function" then return syn.getcustomasset end
    return nil
end

----------------------------------------------------------------
-- Built-in songs
----------------------------------------------------------------
local BUILTIN = {
    { name = "vyzee we go up",      url = "https://files.catbox.moe/bvpw7w.mp3", file = "vyzee.mp3" },
    { name = "balenciaga",          url = "https://files.catbox.moe/n6mu6i.mp3", file = "balenciaga.mp3" },
    { name = "du bist",             url = "https://files.catbox.moe/dwjk76.mp3", file = "dubist.mp3" },
    { name = "king nasir",          url = "https://files.catbox.moe/dkci4j.mp3", file = "kingnasir.mp3" },
    { name = "blue bands",          url = "https://files.catbox.moe/3g99za.mp3", file = "bluebands.mp3" },
    { name = "cool for the summer", url = "https://files.catbox.moe/wymx4d.mp3", file = "coolforthesummer.mp3" },
    { name = "cinderella",          url = "https://files.catbox.moe/uvkpzb.mp3", file = "cinderella.mp3" },
    { name = "ghetto love story",   url = "https://files.catbox.moe/tqunbw.mp3", file = "ghettolovestory.mp3" },
    { name = "nevada",              url = "https://files.catbox.moe/wmnpw2.mp3", file = "nevada.mp3" },
    { name = "raya",                url = "https://files.catbox.moe/uf7506.mp3", file = "raya.mp3" },
    { name = "vicious drop",        assetId = "rbxassetid://110919391228823" },
}

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local Config = {
    volume = 0.6, speed = 1, pitchLock = false, loop = true, index = 1,
    bass = 0, bassMid = 0, bassHigh = 0, drive = 0,
    posX = 40, posY = -198, posYScale = 0.5,
    editStretch = 1, songsHeight = 150, libScale = 1,
    -- Mini-Modus
    miniMode = false, miniPosX = 40, miniPosY = -60, miniPosYScale = 0.5, miniScale = 1,
    -- Farben (Akzente werden daraus berechnet)
    hueA = 258, hueB = 187, sat = 0.70, val = 0.95,
    library = {},
}

local function loadConfig()
    if not _readfile or not _isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(_readfile(CONFIG_FILE))
        if type(data) ~= "table" then return end
        Config.volume    = math.clamp(tonumber(data.volume) or 0.6, 0, 1)
        Config.speed     = math.clamp(tonumber(data.speed) or 1, 0.25, 3)
        Config.pitchLock = data.pitchLock == true
        Config.loop      = data.loop ~= false
        Config.index     = math.max(tonumber(data.index) or 1, 1)
        Config.bass      = math.clamp(tonumber(data.bass) or 0, 0, 100)
        Config.bassMid   = math.clamp(tonumber(data.bassMid) or 0, -40, 0)
        Config.bassHigh  = math.clamp(tonumber(data.bassHigh) or 0, -40, 0)
        Config.drive     = math.clamp(tonumber(data.drive) or 0, 0, 100)
        if tonumber(data.posX) then Config.posX = tonumber(data.posX) end
        if tonumber(data.posY) then Config.posY = tonumber(data.posY) end
        if tonumber(data.posYScale) then Config.posYScale = tonumber(data.posYScale) end
        Config.editStretch = math.clamp(tonumber(data.editStretch) or 1, 0.7, 1.8)
        Config.songsHeight = math.clamp(tonumber(data.songsHeight) or 150, 90, 460)
        Config.libScale    = math.clamp(tonumber(data.libScale) or 1, 0.6, 1.8)
        Config.miniMode  = data.miniMode == true
        if tonumber(data.miniPosX) then Config.miniPosX = tonumber(data.miniPosX) end
        if tonumber(data.miniPosY) then Config.miniPosY = tonumber(data.miniPosY) end
        if tonumber(data.miniPosYScale) then Config.miniPosYScale = tonumber(data.miniPosYScale) end
        Config.miniScale = math.clamp(tonumber(data.miniScale) or 1, 0.7, 1.6)
        Config.hueA = math.clamp(tonumber(data.hueA) or 258, 0, 360)
        Config.hueB = math.clamp(tonumber(data.hueB) or 187, 0, 360)
        Config.sat  = math.clamp(tonumber(data.sat) or 0.70, 0, 1)
        Config.val  = math.clamp(tonumber(data.val) or 0.95, 0.35, 1)
        if type(data.library) == "table" then
            Config.library = {}
            for _, e in ipairs(data.library) do
                if type(e) == "table" and e.id then
                    table.insert(Config.library, { name = tostring(e.name or e.id), id = tostring(e.id) })
                end
            end
        end
    end)
end

local function writeConfigNow()
    if not _writefile then return end
    pcall(function() _writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
end

-- Sammelt schnelle Aenderungen (Slider) und schreibt nur einmal
local saveQueued = false
local function saveConfig()
    if not _writefile or saveQueued then return end
    saveQueued = true
    task.delay(0.35, function()
        saveQueued = false
        writeConfigNow()
    end)
end

loadConfig()

----------------------------------------------------------------
-- Song list (builtin + library)
----------------------------------------------------------------
local SONGS = {}
local function rebuildSongs()
    SONGS = {}
    for _, s in ipairs(BUILTIN) do table.insert(SONGS, s) end
    for _, e in ipairs(Config.library) do
        table.insert(SONGS, { name = e.name, assetId = e.id, custom = true })
    end
end
rebuildSongs()
if Config.index > #SONGS then Config.index = 1 end

local function normalizeId(raw)
    raw = tostring(raw or ""):gsub("%s", "")
    local digits = raw:match("(%d+)")
    if not digits then return nil end
    return "rbxassetid://" .. digits
end

----------------------------------------------------------------
-- Sound engine
----------------------------------------------------------------
local Sound = Instance.new("Sound")
Sound.Name = "ViciousRadioSound"
Sound.Volume = Config.volume
Sound.PlaybackSpeed = Config.speed
Sound.Looped = Config.loop
Sound.Parent = SoundService

local pitchFx = Instance.new("PitchShiftSoundEffect")
pitchFx.Name = "ViciousPitchLock"
pitchFx.Octave = 1
pitchFx.Enabled = false
pitchFx.Parent = Sound

local eqFx = Instance.new("EqualizerSoundEffect")
eqFx.Name = "ViciousBassBoost"
eqFx.LowGain = 0
eqFx.MidGain = 0
eqFx.HighGain = 0
eqFx.Enabled = false
eqFx.Parent = Sound

local compFx = Instance.new("CompressorSoundEffect")
compFx.Name = "ViciousComp"
compFx.Threshold = -25
compFx.Ratio = 8
compFx.Attack = 0.01
compFx.Release = 0.12
compFx.GainMakeup = 0
compFx.Enabled = false
compFx.Parent = Sound

local distFx = Instance.new("DistortionSoundEffect")
distFx.Name = "ViciousDrive"
distFx.Level = 0
distFx.Enabled = false
distFx.Parent = Sound

local function applyVolume()
    -- FIX: Bass Boost macht jetzt LAUTER statt leiser
    local a = math.clamp(Config.bass, 0, 100) / 100
    local mult = 1 + a * 1.6
    Sound.Volume = math.clamp(Config.volume * mult, 0, 10)
end

local function applyBass()
    local a = math.clamp(Config.bass, 0, 100) / 100
    -- FIX: Lows werden angehoben, Mitten/Hoehen nur leicht zurueckgenommen
    eqFx.LowGain  = math.clamp(a * 10, -80, 10)
    eqFx.MidGain  = math.clamp(-a * 8 + Config.bassMid, -80, 10)
    eqFx.HighGain = math.clamp(-a * 4 + Config.bassHigh, -80, 10)
    eqFx.Enabled  = a > 0 or Config.bassMid < 0 or Config.bassHigh < 0

    compFx.Threshold = -18 - a * 10
    compFx.Ratio = 3 + a * 5
    compFx.GainMakeup = a * 8
    compFx.Enabled = a > 0

    local d = math.clamp(Config.drive, 0, 100) / 100
    distFx.Level = d * 0.95
    distFx.Enabled = d > 0

    applyVolume()
end

local setVolumeExternal -- wird von der Mini-Leiste gesetzt (haelt beide Regler synchron)
local currentIndex = math.clamp(Config.index, 1, math.max(#SONGS, 1))
local requestId = 0
local statusRef, songRef

local function setStatus(txt)
    if statusRef and statusRef.Parent then statusRef.Text = txt end
end

local function applySpeed()
    Sound.PlaybackSpeed = Config.speed
    pitchFx.Enabled = Config.pitchLock
    if Config.pitchLock then
        pitchFx.Octave = math.clamp(1 / math.max(Config.speed, 0.01), 0.5, 2)
    end
end

local function playSong(song, label)
    requestId = requestId + 1
    local myRequest = requestId
    if songRef and songRef.Parent then songRef.Text = label or song.name end
    setStatus("loading...")

    task.spawn(function()
        local ok, err = pcall(function()
            if myRequest ~= requestId then return end
            Sound:Stop()
            if song.assetId then
                Sound.SoundId = song.assetId
            else
                local cached = false
                pcall(function()
                    if song.file and _isfile(song.file) then cached = true end
                end)
                if not cached and song.url then
                    local data = game:HttpGet(song.url)
                    if _writefile and song.file then _writefile(song.file, data) end
                end
                if myRequest ~= requestId then return end
                local getAsset = getAssetFunc()
                if getAsset and song.file and _isfile(song.file) then
                    Sound.SoundId = getAsset(song.file)
                elseif song.url then
                    Sound.SoundId = song.url
                end
            end
            if myRequest ~= requestId then return end
            applyVolume()
            Sound.Looped = Config.loop
            applySpeed()
            Sound:Play()
        end)
        if myRequest ~= requestId then return end
        if ok then setStatus("playing") else setStatus("load failed") warn("[Vicious Radio]", err) end
        saveConfig()
    end)
end

local function playIndex(index)
    if not index or index < 1 or index > #SONGS then return end
    currentIndex = index
    Config.index = index
    playSong(SONGS[index])
end

local function togglePlay()
    if Sound.IsPlaying then
        Sound:Pause()
        setStatus("paused")
        return false
    end
    if Sound.SoundId ~= "" and (Sound.IsPaused or Sound.TimePosition > 0.05) then
        Sound:Resume()
        setStatus("playing")
        return true
    end
    playIndex(currentIndex)
    return true
end

local function nextSong()
    if #SONGS == 0 then return end
    playIndex(currentIndex % #SONGS + 1)
end
local function prevSong()
    if #SONGS == 0 then return end
    playIndex((currentIndex - 2) % #SONGS + 1)
end

----------------------------------------------------------------
-- UI helpers
----------------------------------------------------------------
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local THEME = {
    bg        = Color3.fromRGB(13, 12, 22),
    card      = Color3.fromRGB(25, 23, 40),
    card2     = Color3.fromRGB(31, 29, 50),
    accentA   = Color3.fromRGB(139, 92, 246),
    accentB   = Color3.fromRGB(34, 211, 238),
    text      = Color3.fromRGB(240, 238, 252),
    dim       = Color3.fromRGB(150, 146, 178),
}

-- ---- Farb-Engine: Akzente werden aus Config berechnet und live nachgezogen ----
local accentHooks = {}

local function accentFromConfig()
    THEME.accentA = Color3.fromHSV(Config.hueA / 360, Config.sat, Config.val)
    THEME.accentB = Color3.fromHSV(Config.hueB / 360,
        math.clamp(Config.sat * 0.9, 0, 1), math.clamp(Config.val * 1.02, 0, 1))
end
accentFromConfig()

-- fn wird sofort und bei jeder Farbaenderung ausgefuehrt
local function onAccent(fn)
    table.insert(accentHooks, fn)
    local ok, err = pcall(fn)
    if not ok then warn("[Vicious Radio] accent hook", err) end
end

local function refreshAccent()
    accentFromConfig()
    for _, fn in ipairs(accentHooks) do pcall(fn) end
end

local function tint(inst, prop, key)
    onAccent(function()
        if inst.Parent or true then inst[prop] = THEME[key] end
    end)
    return inst
end

local function corner(inst, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, inst)
end

local function stroke(inst, t, c)
    new("UIStroke", {
        Color = c or Color3.fromRGB(150, 130, 255),
        Thickness = 1,
        Transparency = t or 0.75,
    }, inst)
end

-- Farbverlauf (folgt automatisch der gewaehlten Farbe)
local function grad(inst, a, b, rot)
    local keyA = (a == nil or a == THEME.accentA) and "accentA" or (a == THEME.accentB and "accentB" or nil)
    local keyB = (b == nil or b == THEME.accentB) and "accentB" or (b == THEME.accentA and "accentA" or nil)
    local g = new("UIGradient", {
        Color = ColorSequence.new(a or THEME.accentA, b or THEME.accentB),
        Rotation = rot or 25,
    }, inst)
    if keyA or keyB then
        onAccent(function()
            g.Color = ColorSequence.new(keyA and THEME[keyA] or a, keyB and THEME[keyB] or b)
        end)
    end
    return g
end

-- weicher Hintergrund-Verlauf fuer Karten
local function cardGrad(inst)
    return new("UIGradient", {
        Color = ColorSequence.new(THEME.card2, THEME.card),
        Rotation = 90,
    }, inst)
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging then
                        dragging = false
                        Config.posX = frame.Position.X.Offset
                        Config.posY = frame.Position.Y.Offset
                        Config.posYScale = frame.Position.Y.Scale
                        saveConfig()
                    end
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

----------------------------------------------------------------
-- GUI shell
----------------------------------------------------------------
local BASE_W = 296  -- Inhaltsbreite jeder Sektion (vor Skalierung)

local gui = new("ScreenGui", {
    Name = "ViciousRadioGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 320, 0, 640),
    Position = UDim2.new(0, Config.posX, Config.posYScale, Config.posY),
    BackgroundColor3 = THEME.bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 2,
}, gui)
corner(main, 16)
stroke(main, 0.35)
new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(26, 22, 45), Color3.fromRGB(11, 11, 19)),
    Rotation = 90,
}, main)

-- Akzent-Leiste oben
local accentBar = new("Frame", {
    Size = UDim2.new(1, -28, 0, 3),
    Position = UDim2.new(0, 14, 0, 6),
    BackgroundColor3 = THEME.accentA,
    BorderSizePixel = 0,
    ZIndex = 5,
}, main)
corner(accentBar, 2)
tint(accentBar, "BackgroundColor3", "accentA")
grad(accentBar)

local header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundTransparency = 1,
    ZIndex = 3,
}, main)
makeDraggable(main, header)

local titleLbl = new("TextLabel", {
    Text = "VICIOUS  RADIO",
    Font = Enum.Font.GothamBlack,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 6),
    Size = UDim2.new(1, -60, 1, 0),
    ZIndex = 4,
}, header)
grad(titleLbl, THEME.accentB, THEME.accentA, 0)

local closeBtn = new("TextButton", {
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 220, 230),
    BackgroundColor3 = Color3.fromRGB(52, 34, 62),
    AutoButtonColor = false,
    Position = UDim2.new(1, -34, 0, 12),
    Size = UDim2.new(0, 22, 0, 22),
    ZIndex = 4,
}, header)
corner(closeBtn, 8)
stroke(closeBtn, 0.7)

local miniBtn = new("TextButton", {
    Text = "–",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(225, 222, 245),
    BackgroundColor3 = Color3.fromRGB(38, 34, 62),
    AutoButtonColor = false,
    Position = UDim2.new(1, -60, 0, 12),
    Size = UDim2.new(0, 22, 0, 22),
    ZIndex = 4,
}, header)
corner(miniBtn, 8)
stroke(miniBtn, 0.7)

-- Tabs
local tabBar = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 46),
    Size = UDim2.new(1, -24, 0, 28),
    ZIndex = 3,
}, main)

local pages = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 82),
    Size = UDim2.new(1, -24, 1, -94),
    ZIndex = 3,
    ClipsDescendants = false,
}, main)

local playerPage = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3 }, pages)
local libraryPage = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 3 }, pages)
local sizePage = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 3 }, pages)
local colorPage = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 3 }, pages)

-- Sektionen (jede eigener Maßstab)
local editSection = new("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, BASE_W, 0, 470),
    ZIndex = 3,
}, playerPage)


local songsSection = new("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, BASE_W, 0, 150),
    ZIndex = 3,
}, playerPage)


local librarySection = new("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, BASE_W, 0, 330),
    ZIndex = 3,
}, libraryPage)
local libScaleFx = new("UIScale", { Scale = Config.libScale }, librarySection)

local EDIT_H, SONGS_H, LIB_H, SIZE_H, COLOR_H = 470, 150, 330, 256, 260
local setMiniScaleExternal -- wird von der Mini-Leiste gesetzt
local currentTab = "PLAYER"

-- Elemente der Edit-Sektion: Basis-Positionen merken, damit nur die
-- HOEHE (Laenge) veraendert wird, die Breite bleibt gleich.
local editItems = {}
local function trackEdit(inst)
    table.insert(editItems, {
        inst = inst,
        y = inst.Position.Y.Offset,
        h = inst.Size.Y.Offset,
    })
    return inst
end

local songsList  -- vorwaerts

local function applyEditStretch()
    local st = Config.editStretch
    local hf = 1 + (st - 1) * 0.5
    for _, it in ipairs(editItems) do
        it.inst.Position = UDim2.new(it.inst.Position.X.Scale, it.inst.Position.X.Offset,
            0, math.floor(it.y * st))
        it.inst.Size = UDim2.new(it.inst.Size.X.Scale, it.inst.Size.X.Offset,
            0, math.floor(it.h * hf))
    end
end

local function relayout()
    libScaleFx.Scale = Config.libScale
    applyEditStretch()
    local editH = math.floor(EDIT_H * Config.editStretch)
    local songsH = math.floor(Config.songsHeight)
    if songsList then
        songsSection.Size = UDim2.new(0, BASE_W, 0, songsH)
        songsList.Size = UDim2.new(1, 0, 0, songsH - 18)
    end
    local w, h
    if currentTab == "PLAYER" then
        editSection.Position = UDim2.new(0, 0, 0, 0)
        editSection.Size = UDim2.new(0, BASE_W, 0, editH)
        songsSection.Position = UDim2.new(0, 0, 0, editH + 12)
        w = BASE_W
        h = editH + 12 + songsH
    elseif currentTab == "LIBRARY" then
        w = BASE_W * Config.libScale
        h = LIB_H * Config.libScale
    elseif currentTab == "SIZE" then
        w = BASE_W
        h = SIZE_H
    else
        w = BASE_W
        h = COLOR_H
    end
    main.Size = UDim2.new(0, math.floor(w) + 24, 0, math.floor(h) + 94)
end

local tabButtons = {}
local function setTab(name)
    currentTab = name
    playerPage.Visible = (name == "PLAYER")
    libraryPage.Visible = (name == "LIBRARY")
    sizePage.Visible = (name == "SIZE")
    colorPage.Visible = (name == "COLOR")
    for n, b in pairs(tabButtons) do
        local on = (n == name)
        b.BackgroundTransparency = on and 0 or 0.45
        b.TextColor3 = on and Color3.fromRGB(255, 255, 255) or THEME.dim
        local g = b:FindFirstChildOfClass("UIGradient")
        if g then g.Enabled = on end
    end
    relayout()
end

local tabNames = { "PLAYER", "LIBRARY", "SIZE", "COLOR" }
local TABS = #tabNames
for i, n in ipairs(tabNames) do
    local b = new("TextButton", {
        Text = n,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = THEME.dim,
        BackgroundColor3 = Color3.fromRGB(38, 34, 62),
        BackgroundTransparency = 0.35,
        AutoButtonColor = false,
        Position = UDim2.new((i - 1) / TABS, 2, 0, 0),
        Size = UDim2.new(1 / TABS, -4, 1, 0),
        ZIndex = 4,
    }, tabBar)
    corner(b, 9)
    stroke(b, 0.8)
    local g = grad(b, THEME.accentA, THEME.accentB, 15)
    g.Enabled = false
    tabButtons[n] = b
    b:SetAttribute("hasGrad", true)
    b.Name = "Tab_" .. n
    b.MouseButton1Click:Connect(function() setTab(n) end)
end

----------------------------------------------------------------
-- Now playing + transport (edit section)
----------------------------------------------------------------
local nowCard = new("Frame", {
    BackgroundColor3 = THEME.card,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 54),
    ZIndex = 3,
}, editSection)
corner(nowCard, 12)
stroke(nowCard, 0.6)
cardGrad(nowCard)

local eqDot = new("Frame", {
    BackgroundColor3 = THEME.accentB,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -20, 0, 12),
    Size = UDim2.new(0, 8, 0, 8),
    ZIndex = 5,
}, nowCard)
corner(eqDot, 4)
tint(eqDot, "BackgroundColor3", "accentB")

songRef = new("TextLabel", {
    Text = SONGS[currentIndex] and SONGS[currentIndex].name or "Radio",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 9),
    Size = UDim2.new(1, -36, 0, 18),
    ZIndex = 4,
}, nowCard)

statusRef = new("TextLabel", {
    Text = "stopped",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = THEME.dim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 29),
    Size = UDim2.new(1, -24, 0, 16),
    ZIndex = 4,
}, nowCard)

local function transportBtn(text, x, w)
    local b = new("TextButton", {
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = THEME.text,
        BackgroundColor3 = THEME.card2,
        AutoButtonColor = false,
        Position = UDim2.new(0, x, 0, 64),
        Size = UDim2.new(0, w, 0, 34),
        ZIndex = 3,
    }, editSection)
    corner(b, 11)
    stroke(b, 0.7)
    cardGrad(b)
    return b
end

local prevBtn = transportBtn("◀◀", 0, 88)
local playBtn = transportBtn(Sound.IsPlaying and "❚❚" or "▶", 96, 104)
local nextBtn = transportBtn("▶▶", 208, 88)
-- Play-Button bekommt den Akzent-Verlauf
for _, g in ipairs(playBtn:GetChildren()) do
    if g:IsA("UIGradient") then g:Destroy() end
end
tint(playBtn, "BackgroundColor3", "accentA")
grad(playBtn)
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

----------------------------------------------------------------
-- Slider builder
----------------------------------------------------------------
local function makeSlider(parent, label, y, minV, maxV, value, fmt, onChange, onRelease)
    local holder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 3,
    }, parent)

    new("TextLabel", {
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = THEME.dim,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 16),
        ZIndex = 4,
    }, holder)

    local valLbl = new("TextLabel", {
        Text = string.format(fmt, value),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 0),
        Size = UDim2.new(0, 60, 0, 16),
        ZIndex = 4,
    }, holder)

    local track = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(44, 40, 68),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 8),
        ZIndex = 4,
    }, holder)
    corner(track, 4)

    local fill = new("Frame", {
        BackgroundColor3 = THEME.accentA,
        BorderSizePixel = 0,
        Size = UDim2.new((value - minV) / (maxV - minV), 0, 1, 0),
        ZIndex = 5,
    }, track)
    corner(fill, 4)
    grad(fill, THEME.accentA, THEME.accentB, 0)
    tint(fill, "BackgroundColor3", "accentA")

    local knob = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - minV) / (maxV - minV), 0, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        ZIndex = 6,
    }, track)
    corner(knob, 8)
    stroke(knob, 0.2, THEME.accentB)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -6, 0, -8),
        Size = UDim2.new(1, 12, 0, 24),
        ZIndex = 7,
    }, track)

    local function setFromX(px)
        local a = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = minV + a * (maxV - minV)
        v = math.floor(v * 100 + 0.5) / 100
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = string.format(fmt, v)
        onChange(v)
    end

    local sliding = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if sliding then
                sliding = false
                if onRelease then onRelease() end
                saveConfig()
            end
        end
    end)

    local api = {}
    function api.set(v)
        local a = math.clamp((v - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = string.format(fmt, v)
    end
    return api
end

local volSlider
volSlider = makeSlider(editSection, "VOLUME", 100, 0, 1, Config.volume, "%.2f", function(v)
    if setVolumeExternal then
        setVolumeExternal(v, "main")
    else
        Config.volume = v
        applyVolume()
    end
end)

local speedSlider = makeSlider(editSection, "SPEED / PITCH", 146, 0.25, 3, Config.speed, "%.2fx", function(v)
    Config.speed = v
    applySpeed()
end)

local bassSlider = makeSlider(editSection, "BASS BOOST", 192, 0, 100, Config.bass, "%.0f%%", function(v)
    Config.bass = v
    applyBass()
end)

local driveSlider = makeSlider(editSection, "DRIVE / EARRAPE", 238, 0, 100, Config.drive, "%.0f%%", function(v)
    Config.drive = v
    applyBass()
end)

local midSlider = makeSlider(editSection, "MID CUT", 284, -40, 0, Config.bassMid, "%+.0f dB", function(v)
    Config.bassMid = v
    applyBass()
end)

local highSlider = makeSlider(editSection, "TREBLE CUT", 330, -40, 0, Config.bassHigh, "%+.0f dB", function(v)
    Config.bassHigh = v
    applyBass()
end)

-- Bass presets
local bassRow = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 374),
    Size = UDim2.new(1, 0, 0, 24),
    ZIndex = 3,
}, editSection)

local bassPresets = {
    { "OFF",     0,   0 },
    { "CLUB",    35,  0 },
    { "DJ",      60,  10 },
    { "EARRAPE", 100, 70 },
}
for i, p in ipairs(bassPresets) do
    local b = new("TextButton", {
        Text = p[1],
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(226, 222, 245),
        BackgroundColor3 = THEME.card,
        AutoButtonColor = false,
        Position = UDim2.new(0, (i - 1) * 75, 0, 0),
        Size = UDim2.new(0, 71, 0, 24),
        ZIndex = 4,
    }, bassRow)
    corner(b, 9)
    stroke(b, 0.82)
    cardGrad(b)
    b.MouseButton1Click:Connect(function()
        Config.bass, Config.drive = p[2], p[3]
        applyBass()
        bassSlider.set(Config.bass)
        driveSlider.set(Config.drive)
        saveConfig()
    end)
end

-- Speed presets
local presetRow = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 404),
    Size = UDim2.new(1, 0, 0, 24),
    ZIndex = 3,
}, editSection)

local presets = { 0.5, 0.75, 1, 1.25, 1.5, 2 }
for i, p in ipairs(presets) do
    local b = new("TextButton", {
        Text = tostring(p) .. "x",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(226, 222, 245),
        BackgroundColor3 = THEME.card,
        AutoButtonColor = false,
        Position = UDim2.new(0, (i - 1) * 49, 0, 0),
        Size = UDim2.new(0, 45, 0, 24),
        ZIndex = 4,
    }, presetRow)
    corner(b, 9)
    stroke(b, 0.82)
    cardGrad(b)
    b.MouseButton1Click:Connect(function()
        Config.speed = p
        applySpeed()
        speedSlider.set(p)
        saveConfig()
    end)
end

----------------------------------------------------------------
-- Toggles
----------------------------------------------------------------
local function makeToggle(parent, label, x, y, w, state, onChange)
    local row = new("TextButton", {
        Text = "",
        BackgroundColor3 = THEME.card,
        BackgroundTransparency = 0.05,
        AutoButtonColor = false,
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, 32),
        ZIndex = 3,
    }, parent)
    corner(row, 11)
    stroke(row, 0.75)
    cardGrad(row)

    new("TextLabel", {
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(210, 210, 220),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -48, 1, 0),
        ZIndex = 4,
    }, row)

    local OFFCOL = Color3.fromRGB(52, 48, 76)
    local track = new("Frame", {
        BackgroundColor3 = state and THEME.accentA or OFFCOL,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 34, 0, 18),
        ZIndex = 4,
    }, row)
    corner(track, 9)
    onAccent(function()
        track.BackgroundColor3 = state and THEME.accentA or OFFCOL
    end)

    local knob = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(250, 250, 255),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 5,
    }, track)
    corner(knob, 7)

    row.MouseButton1Click:Connect(function()
        state = not state
        track.BackgroundColor3 = state and THEME.accentA or OFFCOL
        knob.Position = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
        onChange(state)
        saveConfig()
    end)
end

makeToggle(editSection, "PITCH LOCK", 0, 436, 144, Config.pitchLock, function(s)
    Config.pitchLock = s
    applySpeed()
end)

makeToggle(editSection, "LOOP", 152, 436, 144, Config.loop, function(s)
    Config.loop = s
    Sound.Looped = s
end)

-- Basiswerte fuer die Hoehen-Anpassung merken
for _, ch in ipairs(editSection:GetChildren()) do
    if ch:IsA("GuiObject") then trackEdit(ch) end
end

----------------------------------------------------------------
-- Song list (eigene Sektion, eigene Größe)
----------------------------------------------------------------
new("TextLabel", {
    Text = "SONGS",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = THEME.dim,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 14),
    ZIndex = 3,
}, songsSection)

local list = new("ScrollingFrame", {
    BackgroundColor3 = Color3.fromRGB(19, 17, 32),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 18),
    Size = UDim2.new(1, 0, 0, Config.songsHeight - 18),
    CanvasSize = UDim2.new(0, 0, 0, #SONGS * 28 + 6),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = THEME.accentA,
    ZIndex = 3,
}, songsSection)
corner(list, 12)
stroke(list, 0.8)
songsList = list

local songButtons = {}
local highlight

local function refreshSongList()
    for _, b in ipairs(songButtons) do b:Destroy() end
    songButtons = {}
    list.CanvasSize = UDim2.new(0, 0, 0, #SONGS * 28 + 6)
    for i, song in ipairs(SONGS) do
        local b = new("TextButton", {
            Text = "  " .. song.name .. (song.custom and "  ·" or ""),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(205, 200, 225),
            BackgroundColor3 = THEME.accentA,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Position = UDim2.new(0, 4, 0, (i - 1) * 28 + 4),
            Size = UDim2.new(1, -14, 0, 25),
            ZIndex = 4,
        }, list)
        corner(b, 6)
        songButtons[i] = b
        b.MouseButton1Click:Connect(function()
            playIndex(i)
            highlight()
        end)
    end
    highlight()
end

function highlight()
    for i, b in ipairs(songButtons) do
        local on = (i == currentIndex)
        b.BackgroundTransparency = on and 0.25 or 1
        b.TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 186, 215)
    end
end

refreshSongList()

----------------------------------------------------------------
-- LIBRARY page
----------------------------------------------------------------
new("TextLabel", {
    Text = "EIGENE ROBLOX IDS",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = THEME.dim,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 14),
    ZIndex = 3,
}, librarySection)

local function makeBox(placeholder, y, w, x)
    local box = new("TextBox", {
        PlaceholderText = placeholder,
        Text = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = THEME.text,
        PlaceholderColor3 = Color3.fromRGB(126, 120, 158),
        BackgroundColor3 = Color3.fromRGB(24, 22, 40),
        BorderSizePixel = 0,
        Position = UDim2.new(0, x or 0, 0, y),
        Size = UDim2.new(0, w, 0, 28),
        ZIndex = 4,
    }, librarySection)
    corner(box, 10)
    stroke(box, 0.7)
    new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)
    return box
end

local nameBox = makeBox("Name", 20, BASE_W)
local idBox = makeBox("Roblox ID oder rbxassetid://…", 54, BASE_W)

local libStatus = new("TextLabel", {
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(160, 160, 170),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 124),
    Size = UDim2.new(1, 0, 0, 14),
    ZIndex = 4,
}, librarySection)

local function libBtn(text, x, w)
    local b = new("TextButton", {
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = THEME.text,
        BackgroundColor3 = THEME.card2,
        AutoButtonColor = false,
        Position = UDim2.new(0, x, 0, 90),
        Size = UDim2.new(0, w, 0, 30),
        ZIndex = 4,
    }, librarySection)
    corner(b, 10)
    stroke(b, 0.72)
    cardGrad(b)
    return b
end

local testBtn = libBtn("TESTEN", 0, 94)
local saveBtn = libBtn("SPEICHERN", 101, 94)
local stopBtn = libBtn("STOP", 202, 94)

local libList = new("ScrollingFrame", {
    BackgroundColor3 = Color3.fromRGB(19, 17, 32),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 142),
    Size = UDim2.new(1, 0, 0, LIB_H - 142),
    CanvasSize = UDim2.new(0, 0, 0, 6),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = THEME.accentA,
    ZIndex = 3,
}, librarySection)
corner(libList, 12)
stroke(libList, 0.8)

local libRows = {}
local function refreshLibrary()
    for _, r in ipairs(libRows) do r:Destroy() end
    libRows = {}
    libList.CanvasSize = UDim2.new(0, 0, 0, #Config.library * 30 + 6)
    for i, entry in ipairs(Config.library) do
        local row = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 3, 0, (i - 1) * 30 + 3),
            Size = UDim2.new(1, -12, 0, 27),
            ZIndex = 4,
        }, libList)
        libRows[i] = row

        local play = new("TextButton", {
            Text = "  " .. entry.name .. "   (" .. entry.id:gsub("rbxassetid://", "") .. ")",
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextColor3 = Color3.fromRGB(210, 205, 232),
            BackgroundColor3 = THEME.card2,
            BackgroundTransparency = 0.15,
            AutoButtonColor = false,
            Size = UDim2.new(1, -34, 1, 0),
            ZIndex = 5,
        }, row)
        corner(play, 6)
        play.MouseButton1Click:Connect(function()
            playSong({ assetId = entry.id, name = entry.name })
            libStatus.Text = "spiele: " .. entry.name
        end)

        local del = new("TextButton", {
            Text = "×",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 170, 170),
            BackgroundColor3 = Color3.fromRGB(64, 28, 52),
            AutoButtonColor = false,
            Position = UDim2.new(1, -28, 0, 0),
            Size = UDim2.new(0, 28, 1, 0),
            ZIndex = 5,
        }, row)
        corner(del, 6)
        del.MouseButton1Click:Connect(function()
            table.remove(Config.library, i)
            rebuildSongs()
            if currentIndex > #SONGS then currentIndex = 1 end
            refreshLibrary()
            refreshSongList()
            saveConfig()
            libStatus.Text = "gelöscht"
        end)
    end
end
refreshLibrary()

testBtn.MouseButton1Click:Connect(function()
    local id = normalizeId(idBox.Text)
    if not id then libStatus.Text = "ungültige ID" return end
    playSong({ assetId = id, name = nameBox.Text ~= "" and nameBox.Text or id })
    libStatus.Text = "teste " .. id
end)

saveBtn.MouseButton1Click:Connect(function()
    local id = normalizeId(idBox.Text)
    if not id then libStatus.Text = "ungültige ID" return end
    local name = nameBox.Text
    if name == "" then name = "custom " .. (#Config.library + 1) end
    table.insert(Config.library, { name = name, id = id })
    rebuildSongs()
    refreshLibrary()
    refreshSongList()
    saveConfig()
    nameBox.Text, idBox.Text = "", ""
    libStatus.Text = "gespeichert · steht jetzt in SONGS"
end)

stopBtn.MouseButton1Click:Connect(function()
    Sound:Stop()
    setStatus("stopped")
    libStatus.Text = "gestoppt"
end)

----------------------------------------------------------------
-- SIZE page
----------------------------------------------------------------
new("TextLabel", {
    Text = "UI GRÖSSE PRO BEREICH",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(150, 150, 160),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 14),
    ZIndex = 3,
}, sizePage)

new("TextLabel", {
    Text = "Laenge (Hoehe) – Breite bleibt gleich",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(120, 116, 150),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 15),
    Size = UDim2.new(1, 0, 0, 12),
    ZIndex = 3,
}, sizePage)

local editSizeSlider = makeSlider(sizePage, "MAIN / EDIT  LAENGE", 32, 0.7, 1.8, Config.editStretch, "%.2fx", function(v)
    Config.editStretch = v
    relayout()
end)

local songsSizeSlider = makeSlider(sizePage, "SONGS  LAENGE", 78, 90, 460, Config.songsHeight, "%.0f px", function(v)
    Config.songsHeight = v
    relayout()
end)

local libSizeSlider = makeSlider(sizePage, "LIBRARY  GROESSE", 124, 0.6, 1.8, Config.libScale, "%.2fx", function(v)
    Config.libScale = v
    relayout()
end)

local miniSizeSlider = makeSlider(sizePage, "MINI  GROESSE", 170, 0.7, 1.6, Config.miniScale, "%.2fx", function(v)
    Config.miniScale = v
    if setMiniScaleExternal then setMiniScaleExternal(v) end
end)

local resetSize = new("TextButton", {
    Text = "RESET",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(230, 230, 240),
    BackgroundColor3 = THEME.card2,
    AutoButtonColor = false,
    Position = UDim2.new(0, 0, 0, 218),
    Size = UDim2.new(0, 94, 0, 28),
    ZIndex = 4,
}, sizePage)
corner(resetSize, 10)
stroke(resetSize, 0.75)
cardGrad(resetSize)
resetSize.MouseButton1Click:Connect(function()
    Config.editStretch, Config.songsHeight, Config.libScale, Config.miniScale = 1, 150, 1, 1
    editSizeSlider.set(1)
    songsSizeSlider.set(150)
    libSizeSlider.set(1)
    miniSizeSlider.set(1)
    if setMiniScaleExternal then setMiniScaleExternal(1) end
    relayout()
    saveConfig()
end)


----------------------------------------------------------------
-- COLOR page (Farbanpassung)
----------------------------------------------------------------
new("TextLabel", {
    Text = "FARBEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = THEME.dim,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 14),
    ZIndex = 3,
}, colorPage)

-- Vorschau
local colorPreview = new("Frame", {
    BackgroundColor3 = THEME.accentA,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 18),
    Size = UDim2.new(1, 0, 0, 22),
    ZIndex = 4,
}, colorPage)
corner(colorPreview, 8)
tint(colorPreview, "BackgroundColor3", "accentA")
grad(colorPreview)

local hueASlider, hueBSlider, satSlider, valSlider

local function applyColors()
    refreshAccent()
    saveConfig()
end

hueASlider = makeSlider(colorPage, "FARBE 1 (HUE)", 46, 0, 360, Config.hueA, "%.0f°", function(v)
    Config.hueA = v
    applyColors()
end)

hueBSlider = makeSlider(colorPage, "FARBE 2 (HUE)", 92, 0, 360, Config.hueB, "%.0f°", function(v)
    Config.hueB = v
    applyColors()
end)

satSlider = makeSlider(colorPage, "SAETTIGUNG", 138, 0, 1, Config.sat, "%.2f", function(v)
    Config.sat = v
    applyColors()
end)

valSlider = makeSlider(colorPage, "HELLIGKEIT", 184, 0.35, 1, Config.val, "%.2f", function(v)
    Config.val = v
    applyColors()
end)

local colorPresets = {
    { "VIOLET", 258, 187, 0.70, 0.95 },
    { "TOXIC",  110, 155, 0.85, 0.92 },
    { "SUNSET",  22, 330, 0.85, 0.98 },
    { "BLOOD",  355, 300, 0.85, 0.90 },
    { "ICE",    205, 175, 0.55, 1.00 },
    { "MONO",   240, 240, 0.05, 0.95 },
}

local presetsRow = new("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 228),
    Size = UDim2.new(1, 0, 0, 24),
    ZIndex = 3,
}, colorPage)

for i, p in ipairs(colorPresets) do
    local b = new("TextButton", {
        Text = p[1],
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(228, 224, 246),
        BackgroundColor3 = THEME.card,
        AutoButtonColor = false,
        Position = UDim2.new(0, (i - 1) * 49, 0, 0),
        Size = UDim2.new(0, 45, 0, 24),
        ZIndex = 4,
    }, presetsRow)
    corner(b, 8)
    stroke(b, 0.82)
    cardGrad(b)
    local dot = new("Frame", {
        BackgroundColor3 = Color3.fromHSV(p[2] / 360, p[4], p[5]),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 2),
        Size = UDim2.new(0, 24, 0, 2),
        ZIndex = 4,
    }, b)
    corner(dot, 1)
    b.MouseButton1Click:Connect(function()
        Config.hueA, Config.hueB, Config.sat, Config.val = p[2], p[3], p[4], p[5]
        hueASlider.set(Config.hueA)
        hueBSlider.set(Config.hueB)
        satSlider.set(Config.sat)
        valSlider.set(Config.val)
        applyColors()
    end)
end

----------------------------------------------------------------
-- MINI player (verkleinerte Leiste)
----------------------------------------------------------------
local uiVisible = true
local MINI_W, MINI_H = 232, 46

local mini = new("Frame", {
    Name = "Mini",
    Size = UDim2.new(0, MINI_W, 0, MINI_H),
    Position = UDim2.new(0, Config.miniPosX, Config.miniPosYScale, Config.miniPosY),
    BackgroundColor3 = THEME.bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
    ZIndex = 2,
}, gui)
corner(mini, 14)
stroke(mini, 0.35)
new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(26, 22, 45), Color3.fromRGB(11, 11, 19)),
    Rotation = 90,
}, mini)
local miniScaleFx = new("UIScale", { Scale = Config.miniScale }, mini)

-- Mini merkt sich seine eigene Position
do
    local dragging, dragStart, startPos = false, nil, nil
    mini.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, mini.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and dragging then
                    dragging = false
                    Config.miniPosX = mini.Position.X.Offset
                    Config.miniPosY = mini.Position.Y.Offset
                    Config.miniPosYScale = mini.Position.Y.Scale
                    saveConfig()
                end
            end)
        end
    end)
    mini.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            mini.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local miniAccent = new("Frame", {
    Size = UDim2.new(1, -20, 0, 2),
    Position = UDim2.new(0, 10, 0, 4),
    BackgroundColor3 = THEME.accentA,
    BorderSizePixel = 0,
    ZIndex = 4,
}, mini)
corner(miniAccent, 1)
tint(miniAccent, "BackgroundColor3", "accentA")
grad(miniAccent)

local function miniButton(text, x, w)
    local b = new("TextButton", {
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = THEME.text,
        BackgroundColor3 = THEME.card2,
        AutoButtonColor = false,
        Position = UDim2.new(0, x, 0, 12),
        Size = UDim2.new(0, w, 0, 26),
        ZIndex = 4,
    }, mini)
    corner(b, 9)
    stroke(b, 0.72)
    cardGrad(b)
    return b
end

local miniPrev = miniButton("◀◀", 8, 34)
local miniPlay = miniButton(Sound.IsPlaying and "❚❚" or "▶", 45, 38)
local miniNext = miniButton("▶▶", 86, 34)
for _, g in ipairs(miniPlay:GetChildren()) do
    if g:IsA("UIGradient") then g:Destroy() end
end
tint(miniPlay, "BackgroundColor3", "accentA")
grad(miniPlay)
miniPlay.TextColor3 = Color3.fromRGB(255, 255, 255)

local miniExpand = miniButton("⤢", MINI_W - 34, 26)

-- kompakter Lautstaerke-Regler
local function compactSlider(parent, x, y, w, minV, maxV, value, onChange)
    local track = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(44, 40, 68),
        BorderSizePixel = 0,
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, 6),
        ZIndex = 4,
    }, parent)
    corner(track, 3)

    local a0 = math.clamp((value - minV) / (maxV - minV), 0, 1)
    local fill = new("Frame", {
        BackgroundColor3 = THEME.accentA,
        BorderSizePixel = 0,
        Size = UDim2.new(a0, 0, 1, 0),
        ZIndex = 5,
    }, track)
    corner(fill, 3)
    tint(fill, "BackgroundColor3", "accentA")
    grad(fill, THEME.accentA, THEME.accentB, 0)

    local knob = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(a0, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 6,
    }, track)
    corner(knob, 6)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -6, 0, -9),
        Size = UDim2.new(1, 12, 0, 24),
        ZIndex = 7,
    }, track)

    local sliding = false
    local function setFromX(px)
        local a = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = minV + a * (maxV - minV)
        v = math.floor(v * 100 + 0.5) / 100
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        onChange(v)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
            saveConfig()
        end
    end)

    local api = {}
    function api.set(v)
        local a = math.clamp((v - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
    end
    return api
end

new("TextLabel", {
    Text = "♪",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = THEME.dim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 124, 0, 12),
    Size = UDim2.new(0, 12, 0, 26),
    ZIndex = 4,
}, mini)

local miniVolLbl = new("TextLabel", {
    Text = tostring(math.floor(Config.volume * 100 + 0.5)) .. "%",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(235, 232, 250),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 138, 0, 10),
    Size = UDim2.new(0, 40, 0, 10),
    ZIndex = 5,
}, mini)

local miniVol -- vorwaerts

-- Lautstaerke bleibt zwischen gross und klein synchron
local function setVolume(v, from)
    Config.volume = math.clamp(v, 0, 1)
    applyVolume()
    miniVolLbl.Text = tostring(math.floor(Config.volume * 100 + 0.5)) .. "%"
    if from ~= "mini" and miniVol then miniVol.set(Config.volume) end
    if from ~= "main" and volSlider then volSlider.set(Config.volume) end
end
setVolumeExternal = setVolume

miniVol = compactSlider(mini, 138, 28, MINI_W - 182, 0, 1, Config.volume, function(v)
    setVolume(v, "mini")
end)

local function updatePlayIcons()
    local t = Sound.IsPlaying and "❚❚" or "▶"
    playBtn.Text = t
    miniPlay.Text = t
end

-- Sichtbarkeit: genau eine der beiden Ansichten ist offen
local function applyVisibility()
    main.Visible = uiVisible and not Config.miniMode
    mini.Visible = uiVisible and Config.miniMode
    miniScaleFx.Scale = Config.miniScale
end

local function setMini(on)
    Config.miniMode = on and true or false
    applyVisibility()
    updatePlayIcons()
    saveConfig()
end

local function setVisible(v)
    uiVisible = v and true or false
    applyVisibility()
end

setMiniScaleExternal = function(v)
    Config.miniScale = math.clamp(tonumber(v) or 1, 0.7, 1.6)
    miniScaleFx.Scale = Config.miniScale
    saveConfig()
end

miniPrev.MouseButton1Click:Connect(function() prevSong(); highlight(); updatePlayIcons() end)
miniNext.MouseButton1Click:Connect(function() nextSong(); highlight(); updatePlayIcons() end)
miniPlay.MouseButton1Click:Connect(function()
    togglePlay()
    updatePlayIcons()
    highlight()
end)
miniExpand.MouseButton1Click:Connect(function() setMini(false) end)
miniBtn.MouseButton1Click:Connect(function() setMini(true) end)

----------------------------------------------------------------
-- Wiring
----------------------------------------------------------------
prevBtn.MouseButton1Click:Connect(function() prevSong(); highlight(); updatePlayIcons() end)
nextBtn.MouseButton1Click:Connect(function() nextSong(); highlight(); updatePlayIcons() end)
playBtn.MouseButton1Click:Connect(function()
    togglePlay()
    updatePlayIcons()
    highlight()
end)

-- Icons/Status folgen immer dem echten Sound-Zustand
Sound.Played:Connect(function() updatePlayIcons(); setStatus("playing") end)
Sound.Resumed:Connect(function() updatePlayIcons(); setStatus("playing") end)
Sound.Paused:Connect(function() updatePlayIcons(); setStatus("paused") end)
Sound.Stopped:Connect(function() updatePlayIcons() end)

Sound.Ended:Connect(function()
    if not Config.loop then
        nextSong()
        highlight()
    end
    updatePlayIcons()
end)

closeBtn.MouseButton1Click:Connect(function() setVisible(false) end)

local keyConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        setVisible(not uiVisible)
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        if not uiVisible then setVisible(true) end
        setMini(not Config.miniMode)
    end
end)

----------------------------------------------------------------
-- Public API / cleanup
----------------------------------------------------------------
_G.ViciousRadioStandalone = {
    sound = Sound,
    songs = SONGS,
    play = function(i) playIndex(i); highlight() end,
    next = function() nextSong(); highlight() end,
    prev = function() prevSong(); highlight() end,
    toggle = togglePlay,
    addToLibrary = function(name, id)
        local nid = normalizeId(id)
        if not nid then return false end
        table.insert(Config.library, { name = tostring(name or nid), id = nid })
        rebuildSongs(); refreshLibrary(); refreshSongList(); saveConfig()
        return true
    end,
    setScales = function(editS, songsH, libS)
        Config.editStretch = math.clamp(tonumber(editS) or Config.editStretch, 0.7, 1.8)
        Config.songsHeight = math.clamp(tonumber(songsH) or Config.songsHeight, 90, 460)
        Config.libScale = math.clamp(tonumber(libS) or Config.libScale, 0.6, 1.8)
        relayout(); saveConfig()
    end,
    setSpeed = function(v)
        Config.speed = math.clamp(tonumber(v) or 1, 0.25, 3)
        applySpeed(); speedSlider.set(Config.speed); saveConfig()
    end,
    setVolume = function(v)
        setVolume(math.clamp(tonumber(v) or 0.6, 0, 1))
        saveConfig()
    end,
    setDrive = function(v)
        Config.drive = math.clamp(tonumber(v) or 0, 0, 100)
        applyBass(); driveSlider.set(Config.drive); saveConfig()
    end,
    setBass = function(v)
        Config.bass = math.clamp(tonumber(v) or 0, 0, 100)
        applyBass(); bassSlider.set(Config.bass); saveConfig()
    end,
    setMids = function(v)
        Config.bassMid = math.clamp(tonumber(v) or 0, -40, 0)
        applyBass(); midSlider.set(Config.bassMid); saveConfig()
    end,
    setHighs = function(v)
        Config.bassHigh = math.clamp(tonumber(v) or 0, -40, 0)
        applyBass(); highSlider.set(Config.bassHigh); saveConfig()
    end,
    setPosition = function(x, y, yScale)
        Config.posX, Config.posY = tonumber(x) or Config.posX, tonumber(y) or Config.posY
        Config.posYScale = tonumber(yScale) or Config.posYScale
        main.Position = UDim2.new(0, Config.posX, Config.posYScale, Config.posY)
        saveConfig()
    end,
    showUI = setVisible,
    setMini = setMini,
    isMini = function() return Config.miniMode end,
    setColors = function(hueA, hueB, sat, val)
        Config.hueA = math.clamp(tonumber(hueA) or Config.hueA, 0, 360)
        Config.hueB = math.clamp(tonumber(hueB) or Config.hueB, 0, 360)
        Config.sat  = math.clamp(tonumber(sat) or Config.sat, 0, 1)
        Config.val  = math.clamp(tonumber(val) or Config.val, 0.35, 1)
        hueASlider.set(Config.hueA); hueBSlider.set(Config.hueB)
        satSlider.set(Config.sat); valSlider.set(Config.val)
        refreshAccent(); saveConfig()
    end,
    destroy = function()
        pcall(function() keyConn:Disconnect() end)
        pcall(function() Sound:Stop() Sound:Destroy() end)
        pcall(function() mini:Destroy() end)
        pcall(function() gui:Destroy() end)
        _G.ViciousRadioStandalone = nil
    end,
}

setTab("PLAYER")
applySpeed()
applyBass()
refreshAccent()
applyVisibility()
updatePlayIcons()
setVolume(Config.volume)
setStatus("ready · RightCtrl = UI · RightShift = Mini")
print("[Vicious Radio] v7 loaded · songs:", #SONGS)
