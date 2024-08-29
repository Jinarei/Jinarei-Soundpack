SoundLibrary = {
    ["Son 1"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\mon_son1.mp3",
    ["Son 2"] = "Interface\\AddOns\\SoundLibrary\\Sounds\\mon_son2.mp3",
}

function GetSoundPath(soundName)
    return SoundLibrary[soundName]
end

print("Bibliothèque de Sons chargée. Utilisez les sons via leurs chemins d'accès.")
