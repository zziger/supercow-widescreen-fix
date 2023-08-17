local backup = {}

memory = require("memory").withBackup(backup)
local ffi = require("ffi")
local events = require("events")
local config = require("config")
local imgui = require("imgui")

events.on("_unload", function()
    memory.restoreBackups(backup)
end)

local applyGeneral = require("src.patches.general")

local applyCamera = require("src.patches.camera")
local applyCredits = require("src.patches.credits")
local applyDialogue = require("src.patches.dialogue")
local applyEditor = require("src.patches.editor")
local applyGame = require("src.patches.game")
local applyLevelBacks = require("src.patches.levelbacks")
local applyMainMenu = require("src.patches.mainMenu")
local applyMap = require("src.patches.map")
local applyMisc = require("src.patches.misc")
local applyTrophies = require("src.patches.trophies")

local function getConfigNumber(key, default)
    if config.mod:has(key) then
        return config.mod:getNumber(key)
    else
        return default
    end
end

local defaultOffsetX = 200
local defaultOffsetY = 150

offsetEnabledBuf = ffi.new("bool[1]", { config.mod:getBool('offset') })
offsetValueBuf = ffi.new("float[2]", { getConfigNumber('offsetX', defaultOffsetX), getConfigNumber('offsetY', defaultOffsetY) })

local defaultZoom = 1

zoomValueBuf = ffi.new("float[1]", { getConfigNumber('zoom', defaultZoom) })

cameraBoundsEnabledBuf = ffi.new("bool[1]", { config.mod:has("cameraBounds") and config.mod:getBool('cameraBounds') or true })

setRenderProjectionAddr = memory.at("55 8B EC 83 EC ? 8D 4D ? E8 ? ? ? ? 8B 45 ? 50 8B 4D ? 51 8B 55 ? 52 8B 45 ? 50 8D 4D ? E8 ? ? ? ? 8D 4D ? 51 6A ? 8B 15 ? ? ? ? 8B 02 8B 0D ? ? ? ? 51 FF 90 ? ? ? ? 8B E5 5D C3 CC CC CC CC CC CC CC CC CC CC CC 55")
setRenderProjection = setRenderProjectionAddr:getFunction("int (__cdecl *)(float a1, float a2, float a3, float a4)")
camZoom = memory.at("FF 15 ? ? ? ? D9 05"):add(6 + 2):readOffset()
currentScene = memory.at("81 3D ? ? ? ? ? ? ? ? 0F 95 C0"):add(2):readOffset()
editorScene = memory.at("68 ? ? ? ? 8B 4D ? E8 ? ? ? ? 8B 4D ? 8B 55"):add(1):readInt()

local vec = game.getRenderSize()
realW = vec.x
realH = vec.y
ratio = realW / realH
perfectRatio = 1920 / 1080

h = 600
w = 600 * ratio
perfectW = 600 * perfectRatio

inPerfectProjection = false

function bindToRight(orig)
    return w / 2 - 400 + orig
end

function bindToLeft(orig)
    return w / -2 + 400 + orig
end

function bindToRightStatic(orig)
    return perfectW / 2 - 400 + orig
end

function bindToLeftStatic(orig)
    return perfectW / -2 + 400 + orig
end

function rightOffset(orig, offset)
    return orig - (ratio / (800 / 600) - 1) * offset
end

function leftOffset(orig, offset)
    return orig + (ratio / (800 / 600) - 1) * offset
end

function zoomStatic(orig)
    return orig / (realH / 600)
end

function math.lerp(a, b, t)
    return a + (b - a) * t
end

function render()
    applyGeneral()
end

local function apply()
    applyCamera()
    applyCredits()
    applyDialogue()
    applyEditor()
    applyGame()
    applyLevelBacks()
    applyMainMenu()
    applyMap()
    applyMisc()
    applyTrophies()
end

apply()

events.on("resolutionChange", function(event)
    realW = event.x
    realH = event.y
    ratio = realW / realH
    h = 600
    w = 600 * ratio
    apply()
end)

function renderUi()
    imgui.SeparatorTextEx(0, "Динамический зум", nil, 25)
    imgui.SameLine()
    imgui.HelpMarker("Стандартный зум игры не дружит с разными разрешениями\nиз-за чего камера постоянно кажется дальше/ближе,\nчем она должна быть.\n\nДанный фикс даёт магическую возможность зуму\nподстраиваться под разрешение экрана.\nИ хоть это нельзя отключить, оно-то вам надо\nс такой удобной кастомизацией?")
    imgui.SliderFloat("###veryDynamicZoomSlider", zoomValueBuf, 0.5, 2)
    if imgui.Button("Применить") then
        config.mod:set('dynamicZoom', zoomValueBuf[0])
        config.save()
        apply()
    end
    imgui.SameLine()
    if imgui.Button("Сбросить зум") then
        zoomValueBuf[0] = defaultZoom
        config.mod:set('dynamicZoom', defaultZoom)
        config.save()
        apply()
    end

    imgui.Dummy(imgui.ImVec2(0,2.5))

    imgui.SeparatorTextEx(1, "Отступы HUD", nil, 25)
    imgui.SameLine()
    imgui.HelpMarker("Просто удобная фича, которая перемещает\nвнутриигровой интерфейс (и не только) ближе\nк середине окна, в зависимости от его разрешения.\n\nПримечательно, что она была...\nпозаимствована с Xbox версии игры.\nВключать её или нет - сугубо ваш выбор.")
    if imgui.Checkbox("Включить###hudOffset", offsetEnabledBuf) then
        config.mod:set('offset', offsetEnabledBuf[0])
        config.save()
        apply()
    end

    if offsetEnabledBuf[0] then
        imgui.Indent()
        imgui.Text("Отступы")
        if imgui.InputFloat2("###offsetsVector2", offsetValueBuf) then
            config.mod:set('offsetX', offsetValueBuf[0])
            config.mod:set('offsetY', offsetValueBuf[1])
            config.save()
            apply()
        end

        if imgui.Button("Сбросить отступы") then
            offsetValueBuf[0] = defaultOffsetX
            offsetValueBuf[1] = defaultOffsetY
            config.mod:set('offsetX', defaultOffsetX)
            config.mod:set('offsetY', defaultOffsetY)
            config.save()
            apply()
        end
        imgui.Unindent()
    end

    imgui.Dummy(imgui.ImVec2(0,2.5))

    imgui.SeparatorTextEx(2, "Границы камеры", nil, 25)
    imgui.SameLine()
    imgui.HelpMarker("В игре уже есть некое подобие границ для камеры,\nучитывающее самые дальние объекты уровня.\nЭтот фикс просто делает их чуть ближе\nи зависимыми от разрешения (как же без этого).\n\nОн тоже был взят из Xbox версии\nи вы также можете просто выключить его,\nно мы советуем его для более приятного\nигрового процесса.")
    if imgui.Checkbox("Включить###cameraBoundsToggle", cameraBoundsEnabledBuf) then
        config.mod:set('cameraBounds', cameraBoundsEnabledBuf[0])
        config.save()
        apply()
    end

    imgui.Dummy(imgui.ImVec2(0,50))
end