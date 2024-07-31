local frame = CreateFrame("Frame")  -- Создаем фрейм для отслеживания событий
frame:RegisterEvent("UNIT_HEALTH")  -- Регистрируем событие для отслеживания изменения здоровья
frame:RegisterEvent("PLAYER_DEAD")  -- Регистрируем событие для отслеживания смерти игрока

local LOW_HP = 20
local soundPlayed = false
local waitingMode = false
local playingSound = false
local currentSoundFolder = nil

-- Папки с мемами
local soundFolders = {
    "Interface\\AddOns\\MysterySound\\Sounds\\ToBeContinued",
    "Interface\\AddOns\\MysterySound\\Sounds\\NeverGonnaGive",
    "Interface\\AddOns\\MysterySound\\Sounds\\Sandstorm",
    "Interface\\AddOns\\MysterySound\\Sounds\\Somebody",
    "Interface\\AddOns\\MysterySound\\Sounds\\BeforeYouGoGo"
}

-- Функция для выбора случайной папки
local function GetRandomSoundFolder()
    return soundFolders[math.random(#soundFolders)]
end

-- Функция для приглушения звуков игры
local function MuteGameSounds()
    SetCVar("Sound_SFXVolume", 0.05)
    SetCVar("Sound_MusicVolume", 0.05)
    SetCVar("Sound_AmbienceVolume", 0.05)
end

-- Функция для плавного восстановления громкости звуков игры
local function GraduallyUnmuteGameSounds()
    local currentVolume = 0.05
    local step = 0.05
    local function IncreaseVolume()
        currentVolume = currentVolume + step
        SetCVar("Sound_SFXVolume", currentVolume)
        SetCVar("Sound_MusicVolume", currentVolume)
        SetCVar("Sound_AmbienceVolume", currentVolume)
        if currentVolume < 1 then
            C_Timer.After(0.1, IncreaseVolume)
        end
    end
    IncreaseVolume()
end

-- Функция для воспроизведения полного звукового файла
local function PlayFullSound(folder)
    PlaySoundFile(folder .. "\\Full.ogg", "Master")
end

-- Функция для воспроизведения финального звукового файла
local function PlayFinishSound(folder)
    PlaySoundFile(folder .. "\\Finish.ogg", "Master")
    C_Timer.After(5, GraduallyUnmuteGameSounds)  -- 5 секунд до начала восстановления звуков
end

-- Функция для воспроизведения первых 3.5 секунд звукового файла
local function PlayStartSound(folder)
    currentSoundFolder = folder
    playingSound = true
    MuteGameSounds()
    PlaySoundFile(folder .. "\\Start.ogg", "Master")
    C_Timer.After(3.5, function()
        playingSound = false
        if UnitHealth("player") <= 0 then
            PlayFinishSound(currentSoundFolder)
        else
            local healthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
            if healthPercent > LOW_HP then
                waitingMode = false
                soundPlayed = false
                currentSoundFolder = nil
                C_Timer.After(5, GraduallyUnmuteGameSounds)  -- 5 секунд до начала восстановления звуков
            else
                waitingMode = true
            end
        end
    end)
end

-- Основная функция для обработки событий
local function OnEvent(self, event, ...)
    if event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            local healthPercent = (health / maxHealth) * 100

            if health == 0 or UnitIsGhost("player") then
                return
            end

            if healthPercent <= LOW_HP and not soundPlayed and not playingSound then
                local folder = GetRandomSoundFolder()
                PlayStartSound(folder)
                soundPlayed = true
            elseif healthPercent > LOW_HP and waitingMode then
                waitingMode = false
                soundPlayed = false
                currentSoundFolder = nil
                C_Timer.After(5, GraduallyUnmuteGameSounds)  -- 5 секунд до начала восстановления звуков
            end
        end
    elseif event == "PLAYER_DEAD" then
        if waitingMode and currentSoundFolder then
            MuteGameSounds()  -- Приглушаем звуки при смерти
            PlayFinishSound(currentSoundFolder)
            waitingMode = false
            soundPlayed = false
            currentSoundFolder = nil
        else
            if not playingSound then
                local folder = GetRandomSoundFolder()
                MuteGameSounds()  -- Приглушаем звуки при смерти
                PlayFullSound(folder)
                waitingMode = false
                soundPlayed = false
                currentSoundFolder = nil
                C_Timer.After(5, GraduallyUnmuteGameSounds)  -- 5 секунд до начала восстановления звуков
            end
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
