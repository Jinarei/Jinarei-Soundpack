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
-- IMAGES PAUSE
-- =========================================================================

local PauseImages = {
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img1.jpg",  width = 213, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img2.jpg",  width = 442, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img3.jpg",  width = 417, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img4.png",  width = 369, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img5.jpg",  width = 368, height = 260 }, 
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img6.png",  width = 336, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img7.jpg",  width = 347, height = 260 },    
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img8.png",  width = 314, height = 260 },    
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img9.jpg",  width = 263, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img10.jpg", width = 432, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img11.png", width = 463, height = 260 },    
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img12.jpg", width = 140, height = 260 }, 
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img13.jpg", width = 195, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img14.jpg", width = 329, height = 260 },
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img15.jpg", width = 265, height = 260 },
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img16.jpg", width = 347, height = 260 },
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img17.jpg", width = 260, height = 260 },
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img18.jpg", width = 230, height = 260 }, 
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img19.jpg", width = 197, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img20.jpg", width = 229, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img21.jpg", width = 368, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img22.jpg", width = 368, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img23.jpg", width = 344, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img24.png", width = 200, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img25.jpg", width = 275, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img26.jpg", width = 194, height = 260 },  
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img27.png", width = 319, height = 260 },   
    { path = "Interface\\AddOns\\Jinarei-Soundpack\\Images\\img28.jpg", width = 119, height = 260 }
}

-- IDs Additionnels
local SPELL_LEVITATE = 111759


-- Globaux Modules
local JinareiDeathFrame
local MplusEndTime = nil
local MplusDepletePlayed = false

-- =========================================================================
-- LOGIQUE
-- =========================================================================

local eventFrame = CreateFrame("Frame", "JinareiEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_SPELL_HASTE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
eventFrame:RegisterEvent("UNIT_AURA")


local ADDON_PREFIX = "JINAREI_SP"
local DEBUG_MODE = false 
local lastHaste = 0
local SettingsCategory -- To store the settings category object

local GAS_SPELL_IDS = {
    [471755] = true,
    [1215073] = true,
    [1215074] = true,
}

-- Timer Frame Globals
local JinareiTimerFrame
local TIMER_DURATION = 40
local TIMER_END_TIME = 0

local function PlaySynchronizedMusic(source, isTest)
    if JinareiDB.muteMusic then
         if JinareiDB.showDebug then
            print("|cFF00FFFF[DEBUG]|r Music triggered but MUTE is enabled.")
         end
         -- On return pas tout de suite si on veut quand même afficher le timer ?
         -- Le user a dit "enlever tout le son des musique".
         -- Mais est-ce qu'il veut le Timer ?
         -- On va assumer que Mute = Juste pas de son, mais le reste (Timer) fonctionne.
    else
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
    
    if not JinareiDB.muteMusic then
        PlaySoundFile(path, channel)
    end
    end
    
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

-- =========================================================================
-- LOGIQUE MORT (DARK SOULS)
-- =========================================================================
local function CreateDeathFrame()
    if JinareiDeathFrame then return end
    
    local f = CreateFrame("Frame", "JinareiDeathFrame", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetAllPoints()
    f:Hide()
    f:SetAlpha(0)
    
    -- Bande noire
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.8) -- Transparence demandée
    bg:SetHeight(150)
    bg:SetPoint("LEFT", 0, 0)
    bg:SetPoint("RIGHT", 0, 0)
    bg:SetPoint("CENTER", 0, 50) -- Un peu au dessus du centre
    f.bg = bg
    
    -- Texte
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetPoint("CENTER", bg, "CENTER", 0, 0)
    text:SetText("VOUS ÊTES MORT")
    -- Custom Font Size/Style if possible, otherwise scale
    text:SetTextColor(1, 0, 0, 1) -- Red
    text:SetScale(2.5) -- Make it BIG
    f.text = text
    
    JinareiDeathFrame = f
end

local function HideDeath()
    if JinareiDeathFrame and JinareiDeathFrame:IsShown() then
        JinareiDeathFrame:Hide()
        JinareiDeathFrame:SetAlpha(0)
    end
end

local function TriggerDeath()
    if not JinareiDB.enableDeath then return end
    
    if not JinareiDeathFrame then CreateDeathFrame() end
    
    if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r Player Died. Triggering Dark Souls screen.") end
    
    -- Play Sound
    PlaySoundFile("Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\mort.ogg", JinareiDB.channel or "Master")
    
    -- Show and Fade In
    JinareiDeathFrame:Show()
    UIFrameFadeIn(JinareiDeathFrame, 3, 0, 1) -- 3 seconds fade in
    
    -- Auto Hide after 8 seconds
    C_Timer.After(8, function() HideDeath() end)
end

-- =========================================================================
-- LOGIQUE MYTHIC+ DEPLETE
-- =========================================================================
local function StartMplusTimer()
    local _, _, difficulty, _, _, _, _, _, _ = GetInstanceInfo()
    if difficulty == 8 then -- Mythic Keystone
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        if mapID then
            local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
            if timeLimit and timeLimit > 0 then
                MplusEndTime = GetTime() + timeLimit
                MplusDepletePlayed = false
                if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r M+ Timer Started. Limit: " .. timeLimit .. "s") end
            end
        end
    else
        MplusEndTime = nil
    end
end

local function CheckMplusDeplete()
    if not JinareiDB.enableDeplete or not MplusEndTime then return end
    
    if not MplusDepletePlayed and GetTime() > MplusEndTime then
        if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r M+ Key Depleted!") end
        PlaySoundFile("Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\deplete.ogg", JinareiDB.channel or "Master")
        MplusDepletePlayed = true
    end
end

local function StopMplusTimer()
    MplusEndTime = nil
    MplusDepletePlayed = false
end

-- =========================================================================
-- LOGIQUE PAUSE
-- =========================================================================

local JinareiPauseFrame
local PAUSE_END_TIME = 0

local function StopPause()
    if JinareiPauseFrame then
        JinareiPauseFrame:Hide()
    end
end

local function TriggerPause(duration)
    if not JinareiDB.enablePause then return end
    
    if JinareiDB.showDebug then
        print("|cFF00FFFF[DEBUG]|r Pause triggered for " .. duration .. " seconds.")
    end

    -- Play Sound
    local soundPath = "Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\pause.ogg"
    PlaySoundFile(soundPath, JinareiDB.channel or "Master")

    -- Setup Frame
    if not JinareiPauseFrame then
        local f = CreateFrame("Frame", "JinareiPauseFrame", UIParent)
        f:SetSize(400, 300) -- Will be resized based on image
        f:SetPoint("CENTER", 0, 150) -- "Un peu au dessus du centre"
        
        -- Image
        local img = f:CreateTexture(nil, "ARTWORK")
        img:SetPoint("CENTER")
        f.img = img
        
        -- Text "Pause !"
        local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        txt:SetText("Pause !")
        txt:SetTextColor(1, 0.8, 0, 1) -- Gold-ish
        txt:SetPoint("RIGHT", img, "LEFT", -20, 0)
        f.txt = txt
        
        -- Timer
        local timerTxt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        timerTxt:SetPoint("TOP", img, "BOTTOM", 0, -10)
        f.timerTxt = timerTxt
        
        -- Close/Toggle Button
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(100, 30)
        btn:SetPoint("BOTTOM", img, "TOP", 0, 10)
        btn:SetText("Cacher Image")
        btn:SetScript("OnClick", function(self)
            if f.img:IsShown() then
                f.img:Hide()
                f.txt:Hide()
                self:SetText("Afficher Image")
            else
                f.img:Show()
                f.txt:Show()
                self:SetText("Cacher Image")
            end
        end)
        f.btn = btn

        -- OnUpdate for Timer
        f:SetScript("OnUpdate", function(self, elapsed)
            local remaining = PAUSE_END_TIME - GetTime()
            if remaining <= 0 then
                self:Hide()
            else
                local m = math.floor(remaining / 60)
                local s = math.floor(remaining % 60)
                self.timerTxt:SetText(string.format("%d:%02d", m, s))
            end
        end)
        
        JinareiPauseFrame = f
    end
    
    -- Select Image
    local currentMinute = tonumber(date("%M"))
    local index = (currentMinute % #PauseImages) + 1
    local imgData = PauseImages[index]
    
    if imgData then
        JinareiPauseFrame.img:SetTexture(imgData.path)
        JinareiPauseFrame.img:SetSize(imgData.width, imgData.height)
        -- Re-anchor text based on new size
        JinareiPauseFrame:SetSize(imgData.width + 200, imgData.height + 100) -- Approx
    end

    -- Reset visibility if it was hidden
    JinareiPauseFrame.img:Show()
    JinareiPauseFrame.txt:Show()
    JinareiPauseFrame.btn:SetText("Cacher Image")

    PAUSE_END_TIME = GetTime() + duration
    JinareiPauseFrame:Show()
end

local function InitPauseListeners()
    -- DBM
    if DBM then
        DBM:RegisterCallback("DBM_TimerStart", function(event, id, text, time, icon, type)
            if type == "break" or (id and string.find(string.lower(id), "break")) or (text and string.find(string.lower(text), "pause")) then
                TriggerPause(time)
            end
        end)
        DBM:RegisterCallback("DBM_TimerStop", function(event, id)
            if id and string.find(string.lower(id), "break") then
                StopPause()
            end
        end)
        if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r DBM Listeners Registered.") end
    end
    
    -- BigWigs
    if BigWigsLoader then
        BigWigsLoader.RegisterMessage(JinareiPauseFrame or "JinareiSoundpack", "BigWigs_StartBreak", function(event, ...)
             local args = {...}
             local seconds = 0
             for _, v in ipairs(args) do
                 if type(v) == "number" then
                     seconds = v
                     break
                 end
             end
             
             if seconds > 0 then
                 TriggerPause(seconds)
             end
        end)
        BigWigsLoader.RegisterMessage(JinareiPauseFrame or "JinareiSoundpack", "BigWigs_StopBreak", function(event)
             StopPause()
        end)
        if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r BigWigs Listeners Registered.") end
    end
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
    -- Create the main panel frame (Canvas)
    local panel = CreateFrame("Frame", "JinareiOptionsPanel", UIParent)
    
    -- Register in the new Settings API (Dragonflight/TWW)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, "Jinarei Soundpack")
        SettingsCategory = category
        Settings.RegisterAddOnCategory(category)
    else
        -- Legacy Fallback
        panel.name = "Jinarei Soundpack"
        InterfaceOptions_AddCategory(panel)
        SettingsCategory = panel 
    end

    -- --- SCROLL FRAME SETUP ---
    -- Title (Outside Scroll)
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Jinarei Soundpack Configuration")

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -50) -- Below title
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10) -- Leave room for scrollbar

    -- ScrollChild
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(panel:GetWidth()-50) -- Initial width
    scrollChild:SetHeight(1) -- Will expand

    -- Force width update
    panel:SetScript("OnSizeChanged", function(self, w, h)
        scrollChild:SetWidth(w-50)
    end)

    -- --- UI ELEMENTS (Parented to scrollChild) ---
    local content = scrollChild
    local MARGIN_LEFT = 10 -- Relative to scrollChild
    
    -- 1. General Section
    local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", content, "TOPLEFT", MARGIN_LEFT, -10) 
    lbl:SetText("Canal Audio (Volume):")

    local channels = {"Master", "Music", "SFX", "Ambience", "Dialog"}
    local dropdown = CreateFrame("Frame", "JinareiChannelDropdown", content, "UIDropDownMenuTemplate")
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

    local chkMute = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkMute:SetPoint("LEFT", dropdown, "RIGHT", 150, 0) 
    chkMute.text:SetText("Couper la musique (Mute)")
    chkMute:SetChecked(JinareiDB.muteMusic)
    chkMute:SetScript("OnClick", function(self)
        JinareiDB.muteMusic = self:GetChecked()
        if JinareiDB.muteMusic then StopMusic() end
    end)

    local chkDebug = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkDebug:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -10) 
    chkDebug.text:SetText("Afficher les debugs")
    chkDebug:SetChecked(JinareiDB.showDebug)
    chkDebug:SetScript("OnClick", function(self)
        JinareiDB.showDebug = self:GetChecked()
        DEBUG_MODE = JinareiDB.showDebug
    end)
    
    -- Helper to create a Full Width Separator relative to scrollChild
    local function CreateSeparator(prevRegion)
        local sep = content:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetColorTexture(1, 1, 1, 0.2)
        -- Anchor Top (Y) to previous element, but enforce full width independently
        sep:SetPoint("TOP", prevRegion, "BOTTOM", 0, -20)
        sep:SetPoint("LEFT", content, "LEFT", 10, 0)
        sep:SetPoint("RIGHT", content, "RIGHT", -10, 0)
        return sep
    end

    -- Separator 1
    local sep1 = CreateSeparator(chkDebug)

    -- 2. Filters Section
    local headerFiltres = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerFiltres:SetPoint("TOPLEFT", sep1, "BOTTOMLEFT", 0, -15) 
    headerFiltres:SetPoint("LEFT", content, "LEFT", MARGIN_LEFT, 0)
    headerFiltres:SetText("Filtres Spéciaux")

    local chkNoOuioui = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkNoOuioui:SetPoint("TOPLEFT", headerFiltres, "BOTTOMLEFT", 0, -5)
    chkNoOuioui.text:SetText("Sans Ouioui")
    chkNoOuioui:SetChecked(JinareiDB.noOuioui)
    chkNoOuioui:SetScript("OnClick", function(self)
        JinareiDB.noOuioui = self:GetChecked()
    end)

    local chkNoMeta = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkNoMeta:SetPoint("TOPLEFT", chkNoOuioui, "BOTTOMLEFT", 0, 0)
    chkNoMeta.text:SetText("Sans Métacoptère")
    chkNoMeta:SetChecked(JinareiDB.noMetacopter)
    chkNoMeta:SetScript("OnClick", function(self)
        JinareiDB.noMetacopter = self:GetChecked()
    end)

    local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", chkNoMeta, "BOTTOMLEFT", 0, -15)
    btn:SetSize(140, 25)
    btn:SetText("Tester le son (+Timer)")
    btn:SetScript("OnClick", function()
        PlaySynchronizedMusic("TestConfig", true)
    end)

    -- Separator 2
    local sep2 = CreateSeparator(btn)

    -- 3. Timer Section
    local headerTimer = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerTimer:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -15)
    headerTimer:SetPoint("LEFT", content, "LEFT", MARGIN_LEFT, 0)
    headerTimer:SetText("Timer Visuel Bloodlust")

    local chkTimer = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkTimer:SetPoint("TOPLEFT", headerTimer, "BOTTOMLEFT", 0, -5)
    chkTimer.text:SetText("Afficher l'icône du Timer")
    chkTimer:SetChecked(JinareiDB.showTimer)
    chkTimer:SetScript("OnClick", function(self)
        JinareiDB.showTimer = self:GetChecked()
        if JinareiTimerFrame then if not JinareiDB.showTimer then JinareiTimerFrame:Hide() end end
    end)

    local chkLock = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkLock:SetPoint("LEFT", chkTimer.text, "RIGHT", 50, 0)
    chkLock.text:SetText("Verrouiller la position")
    chkLock:SetChecked(JinareiDB.lockTimer)
    chkLock:SetScript("OnClick", function(self)
        JinareiDB.lockTimer = self:GetChecked()
    end)
    
    local sliderSize = CreateFrame("Slider", "JinareiTimerSizeSlider", content, "OptionsSliderTemplate")
    sliderSize:SetPoint("TOPLEFT", chkTimer, "BOTTOMLEFT", 5, -25) 
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

    local sliderFont = CreateFrame("Slider", "JinareiTimerFontSlider", content, "OptionsSliderTemplate")
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
    end)

    -- Separator 3
    local sep3 = CreateSeparator(sliderSize)
    
    -- 4. Pause Section
    local headerPause = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerPause:SetPoint("TOPLEFT", sep3, "BOTTOMLEFT", 0, -15)
    headerPause:SetPoint("LEFT", content, "LEFT", MARGIN_LEFT, 0)
    headerPause:SetText("Module Pause")

    local chkPause = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkPause:SetPoint("TOPLEFT", headerPause, "BOTTOMLEFT", 0, -5)
    chkPause.text:SetText("Activer l'écran de Pause")
    chkPause:SetChecked(JinareiDB.enablePause)
    chkPause:SetScript("OnClick", function(self)
        JinareiDB.enablePause = self:GetChecked()
    end)
    
    local btnPause = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btnPause:SetPoint("LEFT", chkPause.text, "RIGHT", 150, 0)
    btnPause:SetSize(100, 25)
    btnPause:SetText("Test Pause")
    btnPause:SetScript("OnClick", function()
        TriggerPause(10) -- Test 10s
    end)

    -- Separator 4
    local sep4 = CreateSeparator(btnPause)
    
    -- 5. Module Divers (Levitation, Gateway, Mort, M+)
    local headerDivers = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerDivers:SetPoint("TOPLEFT", sep4, "BOTTOMLEFT", 0, -15)
    headerDivers:SetPoint("LEFT", content, "LEFT", MARGIN_LEFT, 0)
    headerDivers:SetText("Autres")

    -- Checkbox: Mort (Dark Souls)
    local chkDeath = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkDeath:SetPoint("TOPLEFT", headerDivers, "BOTTOMLEFT", 0, -10)
    chkDeath.text:SetText("Écran 'VOUS ÊTES MORT' (Dark Souls)")
    chkDeath:SetChecked(JinareiDB.enableDeath)
    chkDeath:SetScript("OnClick", function(self)
        JinareiDB.enableDeath = self:GetChecked()
        if self:GetChecked() then print("Testez en mourant ou avec /run TriggerDeath()") end
    end)

    -- Checkbox: Mythic+ Deplete
    local chkDeplete = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkDeplete:SetPoint("TOPLEFT", chkDeath, "BOTTOMLEFT", 0, 0)
    chkDeplete.text:SetText("Son quand la clé M+ est deplete (Fin du timer)")
    chkDeplete:SetChecked(JinareiDB.enableDeplete)
    chkDeplete:SetScript("OnClick", function(self)
        JinareiDB.enableDeplete = self:GetChecked()
    end)

    -- Checkbox: Levitation
    local chkLevitate = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chkLevitate:SetPoint("TOPLEFT", chkDeplete, "BOTTOMLEFT", 0, 0)
    chkLevitate.text:SetText("Son Lévitation")
    chkLevitate:SetChecked(JinareiDB.enableLevitate)
    chkLevitate:SetScript("OnClick", function(self)
        JinareiDB.enableLevitate = self:GetChecked()
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

-- Global access for testing
function TriggerDeath_Test() TriggerDeath() end


local function HasBloodlustBuff()
    if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r Verifying against BL_SPELL_IDS list...") end
    
    for spellId, _ in pairs(BL_SPELL_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
        if aura then
            if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r Match found in list! ID: " .. spellId) end
            return true
        end
    end

    if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r No match found in BL_SPELL_IDS.") end
    return false
end

local function OnEvent(self, event, arg1, arg2, arg3, arg4, ...)
    if event == "ADDON_LOADED" and arg1 == "Jinarei-Soundpack" then
        -- Init SavedVariables correctly when addon loads
        if not JinareiDB then JinareiDB = {} end
        if not JinareiDB.channel then JinareiDB.channel = "Master" end
        -- NOTE: minimapPos might default to nil if we want it to center reset, but let's keep it safe
        if not JinareiDB.minimapPos then JinareiDB.minimapPos = 45 end
        if JinareiDB.showDebug == nil then JinareiDB.showDebug = false end 
        if JinareiDB.muteMusic == nil then JinareiDB.muteMusic = false end 
        -- Changed logic vars
        if JinareiDB.noOuioui == nil then JinareiDB.noOuioui = false end
        if JinareiDB.noMetacopter == nil then JinareiDB.noMetacopter = false end
        
        -- Timer defaults
        if JinareiDB.showTimer == nil then JinareiDB.showTimer = false end
        if JinareiDB.lockTimer == nil then JinareiDB.lockTimer = false end
        if not JinareiDB.timerSize then JinareiDB.timerSize = 64 end
        if not JinareiDB.timerSize then JinareiDB.timerSize = 64 end
        if not JinareiDB.timerFontSize then JinareiDB.timerFontSize = 20 end
        
        -- Pause defaults
        if JinareiDB.enablePause == nil then JinareiDB.enablePause = true end
        
        -- New Modules Defaults
        if JinareiDB.enableDeath == nil then JinareiDB.enableDeath = true end
        if JinareiDB.enableDeplete == nil then JinareiDB.enableDeplete = true end
        if JinareiDB.enableLevitate == nil then JinareiDB.enableLevitate = true end


        -- Apply globals
        DEBUG_MODE = JinareiDB.showDebug

        print("|cFF00FF00Jinarei-Soundpack|r: Variables chargées.")
        
    elseif event == "PLAYER_LOGIN" then
        CreateAddonSettingsPanel()
        CreateMinimapButton()
        CreateTimerFrame()

        InitPauseListeners()
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
                     -- Petite pause pour laisser le temps au serveur/client d'appliquer l'aura
                     C_Timer.After(0.1, function()
                         local shouldTrigger = false
                         
                         if InCombatLockdown() then
                             shouldTrigger = true
                         else
                             -- Double verification si hors combat: On scanne la liste des buffs BL
                             if HasBloodlustBuff() then
                                 shouldTrigger = true
                             else
                                 if JinareiDB.showDebug then
                                     print("|cFF00FFFF[DEBUG]|r Haste Spike ignores (Hors combat + Pas de buff BL dans la liste).")
                                 end
                             end
                         end

                         if shouldTrigger then
                             if JinareiDB.showDebug then
                                 print("|cFF00FFFF[DEBUG]|r Haste Spike Detected: +" .. string.format("%.2f", diff) .. "%")
                             end
                             PlaySynchronizedMusic("HasteDetection")
                         end
                     end)
                end
            end
            lastHaste = currentHaste
        end
        
    elseif event == "PLAYER_DEAD" then
        TriggerDeath()

    elseif event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
        HideDeath()
        
    elseif event == "CHALLENGE_MODE_START" then
        StartMplusTimer()
        
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        StopMplusTimer()
        
    elseif event == "UNIT_AURA" then
         local unit = arg1
         if unit == "player" and JinareiDB.enableLevitate then
             -- Check Levitate
             local aura = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_LEVITATE)
             -- Pour éviter le spam, on pourrait checker si on l'avait pas avant, mais UNIT_AURA spamme un peu.
             -- On va juste jouer le son si l'aura est refresh ou appliquée.
             -- Idéalement on garde un state, mais faisons simple : play si presence. 
             -- Mais UNIT_AURA proc souvent. Faut un debounce.
             -- Simple debounce generic sur le spellId ?
             if aura then
                 if not aura.wasPresent then -- Hacky flag? No.
                     -- Check last play time
                    local now = GetTime()
                    if not JinareiDB.lastLevitate or (now - JinareiDB.lastLevitate > 2) then
                         PlaySoundFile("Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\levitation.mp3", JinareiDB.channel or "Master")
                         JinareiDB.lastLevitate = now
                         if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r Levitation Detected!") end
                    end
                 end
             end
         end



    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellId = arg1, arg2, arg3
        
        if unit == "player" then
             -- GasGasGas Check (Existing)
            if GAS_SPELL_IDS[spellId] then
                if JinareiDB.showDebug then
                     print("|cFF00FFFF[DEBUG]|r GasGasGas Triggered by SpellID: " .. spellId)
                end
                if not JinareiDB.muteMusic then
                    PlaySoundFile("Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\GasGasGas.ogg", JinareiDB.channel or "Master")
                end
            end
            
            -- Gateway Shard Check (Backup / Removed in favor of CLEU if this was failing)
            -- if JinareiDB.enableGateway and spellId == SPELL_GATEWAY_SHARD then
            --      if JinareiDB.showDebug then print("|cFF00FFFF[DEBUG]|r Gateway Shard Spell Detected: " .. spellId) end
            --      PlaySoundFile("Interface\\AddOns\\Jinarei-Soundpack\\Sounds\\squalala.ogg", JinareiDB.channel or "Master")
            -- end
            
            -- Debug finder for items
            if JinareiDB.showDebug then
                 -- print("SpellCast: " .. spellId) -- Spammy but useful if needed
            end
        end
    end
end

eventFrame:SetScript("OnUpdate", function(self, elapsed)
    if JinareiTimerFrame and JinareiTimerFrame:IsShown() and JinareiTimerFrame.SetScript then
         -- The TimerFrame has its own OnUpdate, so we don't need to drive it here. Is handled in CreateTimerFrame.
    end
    
    -- Check M+ Timer
    CheckMplusDeplete()
end)

eventFrame:SetScript("OnEvent", OnEvent)

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
