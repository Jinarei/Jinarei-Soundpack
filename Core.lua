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
    "bloodlust8.ogg",
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
    "bloodlustjin.ogg",
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
frame:RegisterEvent("ADDON_LOADED") -- Register this event
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("CHAT_MSG_ADDON")

local ADDON_PREFIX = "JINAREI_SP"
local lastTriggerTime = 0
local COOLDOWN_DURATION = 40 -- Anti-spam cooldown in seconds
local DEBUG_MODE = false -- Mettre à false une fois que tout marche

local function PlaySynchronizedMusic(source, isTest)
    -- Anti-spam check
    if not isTest then
        local now = GetTime()
        if (now - lastTriggerTime) < COOLDOWN_DURATION then
            if JinareiDB.showDebug then
                print("|cFF00FFFF[DEBUG]|r Ignored due to cooldown (" .. math.floor(COOLDOWN_DURATION - (now - lastTriggerTime)) .. "s remaining).")
            end
            return
        end
        lastTriggerTime = now
    end

    -- Definition de la playlist selon le mode
    local playlist = MusicList
    if JinareiDB.jokeMode then
        if JinareiDB.showDebug then
            print("|cFF00FF00Jinarei|r: Mode 'Sans Ouioui' activé !")
        end
        playlist = { "bloodlustjin.ogg", "bloodlust8.ogg" }
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
end

local function SendSyncMessage(spellId)
    local channel = "PARTY"
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    end
    
    -- Payload: BL:spellId:serverTime
    local payload = string.format("BL:%d:%d", spellId, GetServerTime())
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, payload, channel)
end

local JinareiMinimapButton
local JinareiConfigFrame

local function CreateConfigFrame()
    -- Create the main frame with a nice backdrop
    local f = CreateFrame("Frame", "JinareiConfigFrame", UIParent, "BackdropTemplate")
    JinareiConfigFrame = f
    f:SetSize(300, 220) -- Increased Height significantly to fit all options
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    f:SetFrameStrata("DIALOG")

    -- Beautiful stylized backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Header/Title Background
    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(300)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", header, "TOP", 0, -14)
    f.title:SetText("Jinarei Soundpack")

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Channel Dropdown Label
    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", 25, -50)
    lbl:SetText("Canal Audio (Volume):")

    -- Dropdown
    local channels = {"Master", "Music", "SFX", "Ambience", "Dialog"}
    local dropdown = CreateFrame("Frame", "JinareiChannelDropdown", f, "UIDropDownMenuTemplate")
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

    -- Checkbox: Debug Messages
    local chkDebug = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    -- MOVED DOWN: More spacing below Dropdown
    chkDebug:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -15) 
    chkDebug.text:SetText("Afficher les messages de Debug")
    chkDebug:SetChecked(JinareiDB.showDebug)
    chkDebug:SetScript("OnClick", function(self)
        JinareiDB.showDebug = self:GetChecked()
        DEBUG_MODE = JinareiDB.showDebug 
    end)

    -- Checkbox: Joke Mode
    local chkJoke = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    -- MOVED DOWN: More spacing between checkboses
    chkJoke:SetPoint("TOPLEFT", chkDebug, "BOTTOMLEFT", 0, 0)
    chkJoke.text:SetText("Sans Ouioui et JinareiMétacoptère")
    chkJoke:SetChecked(JinareiDB.jokeMode)
    chkJoke:SetScript("OnClick", function(self)
        JinareiDB.jokeMode = self:GetChecked()
    end)

    -- Test Button (Styled)
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOM", 0, 20)
    btn:SetSize(120, 25)
    btn:SetText("Tester le son")
    btn:SetScript("OnClick", function()
        PlaySynchronizedMusic(nil, true)
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
        if JinareiConfigFrame:IsShown() then
            JinareiConfigFrame:Hide()
        else
            JinareiConfigFrame:Show()
        end
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
        if JinareiDB.showDebug == nil then JinareiDB.showDebug = false end -- Default True first time
        if JinareiDB.jokeMode == nil then JinareiDB.jokeMode = false end

        -- Apply globals
        DEBUG_MODE = JinareiDB.showDebug

        print("|cFF00FF00Jinarei-Soundpack|r: Variables chargées.")
        
    elseif event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
        CreateConfigFrame()
        CreateMinimapButton()
        print("|cFF00FF00Jinarei-Soundpack|r: Prêt (v1.0.28).")
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellId = arg1, arg2, arg3
        if unit == "player" and BL_SPELL_IDS[spellId] then
            -- 1. Jouer pour soi
            PlaySynchronizedMusic("Joueur")
            -- 2. Envoyer aux autres
            if IsInGroup() then
                SendSyncMessage(spellId)
            end
        end
        
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        
        if prefix ~= ADDON_PREFIX then return end

        if DEBUG_MODE then
            print("|cFF00FFFF[DEBUG]|r RX Prefix:", prefix, "Msg:", message, "Sender:", sender)
        end
        
        -- Ignorer ses propres messages (déjà traités par UNIT_SPELLCAST_SUCCEEDED)
        local playerName = UnitName("player")
        local senderName = Ambiguate(sender, "none")
        
        -- On compare avec Ambiguate pour être sûr (gère "Name-Realm" vs "Name")
        if senderName == playerName then
            if DEBUG_MODE then print("|cFF00FFFF[DEBUG]|r Ignored own message.") end
            return
        end
        
        -- Vérifier si l'expéditeur est dans le groupe
        -- Note: UnitInParty/Raid fonctionne généralement mieux avec le nom court si même royaume, 
        -- ou nom complet si inter-serveur. On teste les deux par sécurité.
        if not (UnitInParty(sender) or UnitInRaid(sender) or UnitInParty(senderName) or UnitInRaid(senderName)) then
            if DEBUG_MODE then print("|cFF00FFFF[DEBUG]|r Sender not in group/raid:", sender) end
            return
        end
        
        -- Parser le message "BL:spellId:time"
        if message:match("^BL:") then
            if DEBUG_MODE then print("|cFF00FFFF[DEBUG]|r Valid BL message, playing sound.") end
            PlaySynchronizedMusic(senderName)
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
    elseif command == "sync" then
        if IsInGroup() then
            print("|cFF00FF00Jinarei-Soundpack|r: Envoi d'un signal de test au groupe...")
            SendSyncMessage(2825) -- Envoie un faux signal Bloodlust (ID 2825)
        else
            print("|cFF00FF00Jinarei-Soundpack|r: Erreur: Vous devez être en groupe pour tester la synchro.")
        end
    elseif command == "config" then
         msg = msg:match("^%s*(.-)%s*$") -- Trim whitespace
        if JinareiConfigFrame then 
            if JinareiConfigFrame:IsShown() then JinareiConfigFrame:Hide() else JinareiConfigFrame:Show() end
        end
    else
        print("|cFF00FF00Jinarei-Soundpack|r: Commandes disponibles:")
        print("  /jin test - Teste la musique localement")
        print("  /jin sync - Envoie un signal de test au groupe (nécessite d'être groupé)")
        print("  /jin config - Ouvre la fenêtre de configuration")
        print("  Debug Mode: " .. (DEBUG_MODE and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    end
end
