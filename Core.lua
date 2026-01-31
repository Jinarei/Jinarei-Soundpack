-- MidnightHelper Core
local addonName, addonTable = ...

-- =========================================================================
-- CONFIGURATION
-- =========================================================================

-- Liste des fichiers de musique. Les fichiers doivent être dans le dossier "Sounds" de l'addon.
local MusicList = {
    "bloodlust.ogg",
    "bloodlust2.ogg",
    "bloodlust3.ogg",
    "bloodlust4.ogg",
    "bloodlust5.ogg",
    "bloodlust6.ogg",
    "bloodlust7.ogg",
    "bloodlust8.ogg", -- Ouioui
    "bloodlust9.ogg",
    "bloodlust10.ogg",
    "bloodlust11.ogg",
    "bloodlust12.ogg",
    "bloodlust13.ogg",
    "bloodlust14.ogg",
    "bloodlust15.ogg",
    "bloodlust16.ogg",
    "bloodlust17.ogg",
    "bloodlust18.ogg",
    "bloodlust19.ogg",
    "bloodlust20.ogg",
    "bloodlust21.ogg",
    "bloodlust22.ogg",
    "bloodlust23.ogg",
    "bloodlustjin.ogg", -- Metacoptere
}

-- IDs des sorts considérés comme Bloodlust / Heroism
local BL_SPELL_IDS = {
    [2825] = true,    -- Bloodlust (Shaman)
    [32182] = true,   -- Heroism (Shaman)
    [80353] = true,   -- Time Warp (Mage)
    [264667] = true,  -- Primal Rage (Hunter Pet)
    [390386] = true,  -- Fury of the Aspects (Evoker)
    [102364] = true,  -- Drums (Exemple générique, à vérifier selon les versions)
    [256740] = true,
    [230935] = true,
    [292686] = true,
    [178207] = true,
    [386540] = true,
    [381301] = true,
    [444257] = true,
    [466904] = true,
    [461476] = true, -- Might be missing from original, just keeping previous list logic mostly
}

-- =========================================================================
-- LOGIQUE
-- =========================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_SPELL_HASTE")

local ADDON_PREFIX = "JINAREI_SP"
local DEBUG_MODE = false 
local lastHaste = 0
local SettingsCategory -- To store the settings category object

-- Timer Frame Globals
local JinareiTimerFrame
local TIMER_DURATION = 40
local TIMER_END_TIME = 0

local function PlaySynchronizedMusic(source, isTest)
    -- Definition de la playlist selon le mode

    local playlist = MusicList
    
    if JinareiDB.noOuioui and JinareiDB.noMetacopter then
         -- Si les deux sont cochés -> Hasard entre les deux
         playlist = { "bloodlustjin.ogg", "bloodlust8.ogg" }
    elseif JinareiDB.noOuioui then
         -- "Sans Ouioui" coché -> On force Ouioui (bloodlust8) :)
         playlist = { "bloodlust8.ogg" }
    elseif JinareiDB.noMetacopter then
         -- "Sans Metacoptere" coché -> On force Metacoptere (bloodlustjin) :)
         playlist = { "bloodlustjin.ogg" }
    end

    if #playlist == 0 then
        print("|cFF00FF00Jinarei-Soundpack|r: Aucune musique configurée !")
        return
    end

    -- On utilise la minute actuelle pour synchroniser tout le monde
    local currentMinute = tonumber(date("%M"))
    local index = (currentMinute % #playlist) + 1
    local track = playlist[index]
    
    local path = "Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\" .. track
    local channel = JinareiDB and JinareiDB.channel or "Master"
    
    if JinareiDB.showDebug then
        print("|cFF00FF00Jinarei-Soundpack|r: Bloodlust détectée (Source: " .. (source or "Inconnue") .. ")! Musique: " .. track)
    end
    PlaySoundFile(path, channel)
    
    -- Trigger Timer
    if JinareiTimerFrame and JinareiDB.showTimer then
        JinareiTimerFrame:Show()
        TIMER_END_TIME = GetTime() + TIMER_DURATION
        JinareiTimerFrame.cooldown:SetCooldown(GetTime(), TIMER_DURATION)
    end
end

local function CreateTimerFrame()
    if JinareiTimerFrame then return end
    
    local f = CreateFrame("Frame", "JinareiTimerFrame", UIParent)
    f:SetSize(JinareiDB.timerSize or 64, JinareiDB.timerSize or 64)
    f:SetPoint("CENTER", 0, 100) -- Default pos
    if JinareiDB.timerPos then
        f:SetPoint(JinareiDB.timerPos.point, JinareiDB.timerPos.x, JinareiDB.timerPos.y)
    end
    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not JinareiDB.lockTimer then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        JinareiDB.timerPos = {point = point, x = x, y = y}
    end)
    f:Hide() -- Hide by default
    
    -- Icon
    local icon = f:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    -- Icone de Bloodlust (Spell ID 2825)
    icon:SetTexture(C_Spell.GetSpellTexture(2825)) 
    f.icon = icon
    
    -- Cooldown Swipe
    local cd = CreateFrame("Cooldown", "JinareiTimerCooldown", f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetReverse(false)
    cd:SetHideCountdownNumbers(true) -- Cache le texte par défaut de Blizzard (pour éviter le doublon)
    f.cooldown = cd
    
    -- Text
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)
    f.text = text
    
    -- Update Loop
    f:SetScript("OnUpdate", function(self, elapsed)
        local remaining = TIMER_END_TIME - GetTime()
        if remaining <= 0 then
            self:Hide()
        else
            -- Format text
            -- Utilisation de la taille configurée
            local fs = JinareiDB.timerFontSize or 12
             -- On doit recréer la font pour changer la taille dynamiquement si elle change
            local fontName, _ = text:GetFont()
            text:SetFont(fontName, fs, "OUTLINE")
            
            self:SetSize(JinareiDB.timerSize or 64, JinareiDB.timerSize or 64)
            
            self.text:SetText(math.ceil(remaining))
        end
    end)
    
    JinareiTimerFrame = f
end



local JinareiMinimapButton
local JinareiConfigFrame

local function OpenSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(SettingsCategory:GetID())
    else
        -- Fallback for older versions if needed, though TWW uses Settings
        InterfaceOptionsFrame_OpenToCategory(SettingsCategory)
    end
end

local function CreateAddonSettingsPanel()
    -- Create the panel frame
    local panel = CreateFrame("Frame", "JinareiOptionsPanel", UIParent)
    
    -- Register in the new Settings API (Dragonflight/TWW)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, "Jinarei Soundpack")
        SettingsCategory = category
        Settings.RegisterAddOnCategory(category)
    else
        -- Legacy Fallback (shouldn't be needed on Retail but good practice)
        panel.name = "Jinarei Soundpack"
        InterfaceOptions_AddCategory(panel)
        SettingsCategory = panel 
    end

    -- --- UI ELEMENTS ---
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Jinarei Soundpack Configuration")

    -- Dropdown Label
    local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    lbl:SetText("Canal Audio (Volume):")

    -- Dropdown
    local channels = {"Master", "Music", "SFX", "Ambience", "Dialog"}
    local dropdown = CreateFrame("Frame", "JinareiChannelDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", -15, -10)
    
    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
        JinareiDB.channel = self.value
        print("|cFF00FF00Jinarei|r: Canal réglé sur " .. self.value)
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for k, v in pairs(channels) do
            info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    UIDropDownMenu_SetSelectedValue(dropdown, JinareiDB.channel or "Master")
    UIDropDownMenu_SetText(dropdown, JinareiDB.channel or "Master")

    -- Checkbox: Debug
    local chkDebug = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkDebug:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -20)
    chkDebug.text:SetText("Afficher les debugs")
    chkDebug:SetChecked(JinareiDB.showDebug)
    chkDebug:SetScript("OnClick", function(self)
        JinareiDB.showDebug = self:GetChecked()
        DEBUG_MODE = JinareiDB.showDebug
    end)
    
    -- Header: Filtres
    local headerFiltres = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerFiltres:SetPoint("TOPLEFT", chkDebug, "BOTTOMLEFT", 0, -20)
    headerFiltres:SetText("Filtres Spéciaux (Restrictions)")

    -- Checkbox: Sans Ouioui
    local chkNoOuioui = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkNoOuioui:SetPoint("TOPLEFT", headerFiltres, "BOTTOMLEFT", 0, -10)
    chkNoOuioui.text:SetText("Sans Ouioui")
    chkNoOuioui:SetChecked(JinareiDB.noOuioui)
    chkNoOuioui:SetScript("OnClick", function(self)
        JinareiDB.noOuioui = self:GetChecked()
    end)

    -- Checkbox: Sans Metacoptere
    local chkNoMeta = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkNoMeta:SetPoint("TOPLEFT", chkNoOuioui, "BOTTOMLEFT", 0, 0)
    chkNoMeta.text:SetText("Sans Métacoptère")
    chkNoMeta:SetChecked(JinareiDB.noMetacopter)
    chkNoMeta:SetScript("OnClick", function(self)
        JinareiDB.noMetacopter = self:GetChecked()
    end)

    -- Test Button
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", chkNoMeta, "BOTTOMLEFT", 0, -30)
    btn:SetSize(120, 25)
    btn:SetText("Tester le son (+Timer)")
    btn:SetScript("OnClick", function()
        PlaySynchronizedMusic("TestConfig", true)
    end)

    -- Header: Timer UI
    local headerTimer = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerTimer:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -20)
    headerTimer:SetText("Timer Visuel Bloodlust")

    -- Checkbox: Afficher Timer
    local chkTimer = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkTimer:SetPoint("TOPLEFT", headerTimer, "BOTTOMLEFT", 0, -10)
    chkTimer.text:SetText("Afficher l'icône du Timer")
    chkTimer:SetChecked(JinareiDB.showTimer)
    chkTimer:SetScript("OnClick", function(self)
        JinareiDB.showTimer = self:GetChecked()
        if JinareiTimerFrame then if not JinareiDB.showTimer then JinareiTimerFrame:Hide() end end
    end)

    -- Checkbox: Verrouiller
    local chkLock = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    chkLock:SetPoint("LEFT", chkTimer.text, "RIGHT", 200, 0)
    chkLock.text:SetText("Verrouiller la position")
    chkLock:SetChecked(JinareiDB.lockTimer)
    chkLock:SetScript("OnClick", function(self)
        JinareiDB.lockTimer = self:GetChecked()
    end)
    
    -- Slider: Taille Icone
    local sliderSize = CreateFrame("Slider", "JinareiTimerSizeSlider", panel, "OptionsSliderTemplate")
    sliderSize:SetPoint("TOPLEFT", chkTimer, "BOTTOMLEFT", 0, -30)
    sliderSize:SetMinMaxValues(32, 128)
    sliderSize:SetValue(JinareiDB.timerSize or 64)
    sliderSize:SetValueStep(1)
    sliderSize:SetObeyStepOnDrag(true)
    _G[sliderSize:GetName() .. 'Low']:SetText('32')
    _G[sliderSize:GetName() .. 'High']:SetText('128')
    _G[sliderSize:GetName() .. 'Text']:SetText('Taille Icône: ' .. (JinareiDB.timerSize or 64))
    
    sliderSize:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        JinareiDB.timerSize = val
        _G[self:GetName() .. 'Text']:SetText('Taille Icône: ' .. val)
        if JinareiTimerFrame then JinareiTimerFrame:SetSize(val, val) end
    end)

    -- Slider: Taille Police
    local sliderFont = CreateFrame("Slider", "JinareiTimerFontSlider", panel, "OptionsSliderTemplate")
    sliderFont:SetPoint("LEFT", sliderSize, "RIGHT", 40, 0)
    sliderFont:SetMinMaxValues(8, 48)
    sliderFont:SetValue(JinareiDB.timerFontSize or 12)
    sliderFont:SetValueStep(1)
    sliderFont:SetObeyStepOnDrag(true)
    _G[sliderFont:GetName() .. 'Low']:SetText('8')
    _G[sliderFont:GetName() .. 'High']:SetText('48')
    _G[sliderFont:GetName() .. 'Text']:SetText('Taille Texte: ' .. (JinareiDB.timerFontSize or 12))
    
    sliderFont:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        JinareiDB.timerFontSize = val
        _G[self:GetName() .. 'Text']:SetText('Taille Texte: ' .. val)
        -- Refraichissement temps réel dans l'Update du frame
    end)
end

local function CreateMinimapButton()
    local btn = CreateFrame("Button", "JinareiMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameLevel(9) 
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Background Circle
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(25, 25)
    bg:SetPoint("CENTER")
    bg:SetVertexColor(0, 0, 0, 0.6)

    -- Icon (Using FileID for Rabbit to be safe: 134040 = INV_Pet_Rabbit)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(134040) -- Rabbit Icon FileID
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    
    -- Border (Gold ring)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)


    -- Click code
    btn:SetScript("OnClick", function()
        OpenSettings()
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Jinarei Soundpack")
        GameTooltip:AddLine("Clic gauche: Ouvrir la configuration", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Dragging Logic
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton", "RightButton") -- Allow Left or Right click drag
    
    -- Position math
    local function UpdatePosition()
         local angle = JinareiDB.minimapPos or 45 -- Radians
         -- 88 was too close? Trying 103 (Standard is often ~80-100 depending on border)
         -- Minimap Width is 140. Radius 70. Tracking border pushes out.
         local r = 103 
         btn:SetPoint("CENTER", Minimap, "CENTER", r * math.cos(angle), r * math.sin(angle))
    end

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            x, y = x / scale, y / scale
            local mx, my = Minimap:GetCenter()
            local dx, dy = x - mx, y - my
            local angle = math.atan2(dy, dx)
            JinareiDB.minimapPos = angle
            UpdatePosition()
        end)
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    UpdatePosition()
end

local function OnEvent(self, event, arg1, arg2, arg3, arg4, ...)
    if event == "ADDON_LOADED" and arg1 == "Jinarei-Soundpack" then
        -- Init SavedVariables correctly when addon loads
        if not JinareiDB then JinareiDB = {} end
        if not JinareiDB.channel then JinareiDB.channel = "Master" end
        -- NOTE: minimapPos might default to nil if we want it to center reset, but let's keep it safe
        if not JinareiDB.minimapPos then JinareiDB.minimapPos = 45 end
        if JinareiDB.showDebug == nil then JinareiDB.showDebug = false end 
        -- Changed logic vars
        if JinareiDB.noOuioui == nil then JinareiDB.noOuioui = false end
        if JinareiDB.noMetacopter == nil then JinareiDB.noMetacopter = false end
        
        -- Timer defaults
        if JinareiDB.showTimer == nil then JinareiDB.showTimer = false end
        if JinareiDB.lockTimer == nil then JinareiDB.lockTimer = false end
        if not JinareiDB.timerSize then JinareiDB.timerSize = 64 end
        if not JinareiDB.timerFontSize then JinareiDB.timerFontSize = 20 end

        -- Apply globals
        DEBUG_MODE = JinareiDB.showDebug

        print("|cFF00FF00Jinarei-Soundpack|r: Variables chargées.")
        
    elseif event == "PLAYER_LOGIN" then
        CreateAddonSettingsPanel()
        CreateMinimapButton()
        CreateTimerFrame()
        lastHaste = UnitSpellHaste("player") -- Initialize haste on login
        print("|cFF00FF00Jinarei-Soundpack|r: Prêt (v1.0.28).")
        
    elseif event == "UNIT_SPELL_HASTE" then
        local unit = arg1
        if unit == "player" then
            local currentHaste = UnitSpellHaste("player")
            if lastHaste then
                local diff = currentHaste - lastHaste
                -- On cherche une augmentation subite de ~30% (Bloodlust = 30%)
                -- On met 29.5 pour être sûr de capter même si petit arrondi
                if diff >= 29.5 then
                     if JinareiDB.showDebug then
                         print("|cFF00FFFF[DEBUG]|r Haste Spike Detected: +" .. string.format("%.2f", diff) .. "%")
                     end
                     PlaySynchronizedMusic("HasteDetection")
                end
            end
            lastHaste = currentHaste
        end
    end
end

frame:SetScript("OnEvent", OnEvent)

-- =========================================================================
-- EXTENSIBILITÉ (Debuffs)
-- =========================================================================

-- Ici tu pourras ajouter tes futurs codes pour les debuffs.
-- Exemple de structure:
-- local debuffFrame = CreateFrame("Frame")
-- debuffFrame:RegisterEvent("UNIT_AURA")
-- ...


-- =========================================================================
-- COMMANDES SLASH
-- =========================================================================

SLASH_JINAREI1 = "/jinarei"
SLASH_JINAREI2 = "/jin"

SlashCmdList["JINAREI"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    
    if command == "test" then
        print("|cFF00FF00Jinarei-Soundpack|r: Test local de la musique sur le canal: " .. (JinareiDB.channel or "Master"))
        PlaySynchronizedMusic(nil, true)
    elseif command == "config" then
        OpenSettings()
    else
        print("|cFF00FF00Jinarei-Soundpack|r: Commandes disponibles:")
        print("  /jin test - Teste la musique localement")
        print("  /jin config - Ouvre la fenêtre de configuration")
        print("  Debug Mode: " .. (DEBUG_MODE and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    end
end
