SoundLibrary = {
    ["bloodlust"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust.mp3",
    ["bloodlust2"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust2.mp3",
    ["bloodlust3"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust3.mp3",
    ["bloodlust4"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust4.mp3",
    ["bloodlust5"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust5.mp3",
    ["bloodlust6"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust6.mp3",
    ["bloodlust7"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust7.mp3",
    ["bloodlust8"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\bloodlust8.mp3",
}

function GetSoundPath(soundName)
    return SoundLibrary[soundName]
end

print("Bibliothèque de Sons chargée. Utilisez les sons via leurs chemins d'accès.")
