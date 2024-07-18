local frame = CreateFrame("Frame")  -- Создаем фрейм для отслеживания событий
frame:RegisterEvent("UNIT_HEALTH")  -- Регистрируем событие для отслеживания изменения здоровья
frame:RegisterEvent("PLAYER_DEAD")  -- Регистрируем событие для отслеживания смерти игрока

local soundPlayed = false
local waitingMode = false
local playingSound = false
local soundPathFull = "Interface\\AddOns\\MysterySound\\Sounds\\Full.ogg"
local soundPathStart = "Interface\\AddOns\\MysterySound\\Sounds\\Start.ogg"
local soundPathFinish = "Interface\\AddOns\\MysterySound\\Sounds\\Finish.ogg"

-- Функция для воспроизведения полного звукового файла
local function PlayFullSound()
    PlaySoundFile(soundPathFull, "Master")
end

-- Функция для воспроизведения финального звукового файла
local function PlayFinishSound()
    PlaySoundFile(soundPathFinish, "Master")
end

-- Функция для воспроизведения первых 3.5 секунд звукового файла
local function PlayStartSound()
    playingSound = true
    PlaySoundFile(soundPathStart, "Master")
    C_Timer.After(3.5, function()
        playingSound = false
        if UnitHealth("player") <= 0 then
            PlayFinishSound()
        else
            local healthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
            if healthPercent > 15 then
                waitingMode = false
                soundPlayed = false
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
            local healthPercent = (health / maxHealth) * 100  -- Вычисляем процент здоровья

            if health == 0 or UnitIsGhost("player") then
                return
            end

            if healthPercent <= 15 and not soundPlayed and not playingSound then
                PlayStartSound()
                soundPlayed = true
            elseif healthPercent > 15 and waitingMode then
                waitingMode = false
                soundPlayed = false
            end
        end
    elseif event == "PLAYER_DEAD" then
        if waitingMode then
            PlayFinishSound()
            waitingMode = false
            soundPlayed = false
        else
            if not playingSound then
                PlayFullSound()
                waitingMode = false
                soundPlayed = false
            end
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
