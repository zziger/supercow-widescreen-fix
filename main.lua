---@diagnostic disable: param-type-mismatch, undefined-global, undefined-field, lowercase-global

local backup = {}

local memory = require("memory").withBackup(backup)
local ffi = require("ffi")
local events = require("events")
local config = require("config")
local imgui = require("imgui")

local defaultOffsetX = 200
local defaultOffsetY = 150

local function getConfigNumber(key, default)
    if config.mod:has(key) then
        return config.mod:getNumber(key)
    else
        return default
    end
end

local offsetEnabledBuf = ffi.new("bool[1]", { config.mod:getBool('offset') })
local offsetValueBuf = ffi.new("float[2]", { getConfigNumber('offsetX', defaultOffsetX), getConfigNumber('offsetY', defaultOffsetY) })

local setRenderProjectionAddr = memory.at("55 8B EC 83 EC ? 8D 4D ? E8 ? ? ? ? 8B 45 ? 50 8B 4D ? 51 8B 55 ? 52 8B 45 ? 50 8D 4D ? E8 ? ? ? ? 8D 4D ? 51 6A ? 8B 15 ? ? ? ? 8B 02 8B 0D ? ? ? ? 51 FF 90 ? ? ? ? 8B E5 5D C3 CC CC CC CC CC CC CC CC CC CC CC 55")
local setRenderProjection = setRenderProjectionAddr:getFunction("int (__cdecl *)(float a1, float a2, float a3, float a4)")
local camZoom = memory.at("FF 15 ? ? ? ? D9 05"):add(6 + 2):readOffset()

local vec = game.getRenderSize()
local realW = vec.x
local realH = vec.y
local ratio = realW / realH
local perfectRatio = 1920 / 1080

local h = 600
local w = 600 * ratio
local perfectW = 600 * perfectRatio

local function bindToRight(orig)
    return w / 2 - 400 + orig
end

local function bindToLeft(orig)
    return w / -2 + 400 + orig
end

local function bindToRightStatic(orig)
    return perfectW / 2 - 400 + orig
end

local function bindToLeftStatic(orig)
    return perfectW / -2 + 400 + orig
end

local function rightOffset(orig, offset)
    return orig - (ratio / (800 / 600) - 1) * offset
end

local function leftOffset(orig, offset)
    return orig + (ratio / (800 / 600) - 1) * offset
end

local function zoomStatic(orig)
    return orig / (realH / 600)
end

--#region General patches
local getCursorPosAddr = memory.at("55 8B EC 83 EC ? 8D 45 ? 50 8B 0D ? ? ? ? 51 FF 15 ? ? ? ? 8D 55 ? 52 A1 ? ? ? ? 50 FF 15 ? ? ? ? 8D 4D ? 51 FF 15 ? ? ? ? 8B 55 ? 2B 55 ? 89 55 ? 8B 45 ? 2B 45 ? 8B 4D ? 2B C8 89 4D ? DB 45")
local getCursorPosHook;
getCursorPosHook = getCursorPosAddr:hook("void(__cdecl *)(float*, float*)",
    function(x, y)
        getCursorPosHook.orig(x, y)
        x[0] = (x[0] + 400) / 800 * w - (w / 2)
    end, { jit = true })

local renderAnimBackAddr = memory.at("55 8B EC 83 EC ? D9 45 ? D8 25 ? ? ? ? D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 55 ? D9 E0 D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 55 ? D9 E0 D9 5D ? D9 45")
local renderAnimBackHook;
renderAnimBackHook = renderAnimBackAddr:hook("void __cdecl (*)(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, int a9)", 
    function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        renderAnimBackHook.orig(perfectW / -2 + 400, a2, perfectW, a4, a5, a6, 0.88, a8, a9)
    end)

local mapStartButtonCollisionXAddr = memory.at("B9 ? ? ? ? E8 ? ? ? ? 0F B6 C0 85 C0 74 ? D9 05"):add(1):readOffset()
local tipZoomModifierAddr = memory.at("68 ? ? ? ? 8D 45 ? 50 68"):add(1)

function render()
    tipZoomModifierAddr:writeFloat(32 / (realH / 600) / camZoom:readFloat())
    mapStartButtonCollisionXAddr:writeFloat(bindToRightStatic(130))
    mapStartButtonCollisionXAddr:add(8):writeFloat(bindToRightStatic(386))
end
--#endregion

--#region Camera
local replacement = memory.at("D9 1D ? ? ? ? C6 05 ? ? ? ? ? C6 05"):add(6)
local camWorldWidth = memory.at("D9 05 ? ? ? ? D8 25 ? ? ? ? 51 D9 1C 24 8B 45"):add(2):readOffset()
local maxWorldBorderX = memory.at("C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? C7 45 ? ? ? ? ? EB ? 8B 4D"):add(2)
local minWorldBorderX = maxWorldBorderX:add(10):readOffset()
local deathToggle = replacement:add(2):readOffset()
local updateCamPos = memory.at("55 8B EC 83 EC ? C7 45 ? ? ? ? ? 83 3D"):getFunction("void(*)()")
local loadGameScene = memory.at("55 8B EC 51 89 4D ? A1")

local loadLevelHook
loadLevelHook = loadGameScene:hook("void(__cdecl *)(int)",
    function(a1)
        loadLevelHook.orig(a1)
        updateCamPos()
    end)

local function setCamPos()
    local camWorldW = camWorldWidth:readFloat()
    local maxXOffset = maxWorldBorderX:readOffset()
    local maxX, minX = maxXOffset:readFloat(), minWorldBorderX:readFloat()
    maxXOffset:writeFloat(maxX + camWorldW * 0.5)
    minWorldBorderX:writeFloat(minX - camWorldW * 0.5)
    deathToggle:writeByte(0)
end
local setCamPosCallback = ffi.cast("void (*)()", setCamPos)

local defaultZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? C6 05 ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? E8"):add(6)
local cheatkeyDefaultZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? E9 ? ? ? ? 83 7D ? ? 75 ? 0F B6 0D"):add(6)
local editorKeyDefaultZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? E9 ? ? ? ? 83 7D ? ? 75 ? 6A"):add(6)
local editorUIDefaultZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? B8 ? ? ? ? E9"):add(6)
local postEditorDefaultZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? 8B E5 5D C3 CC CC 55"):add(6)
local cheatkeyMinZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? EB ? D9 45"):add(6)
local cheatkeyMaxZoomAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? EB ? 8B 55 ? 89 15"):add(6)

local defaultZoomInAnimAddr = memory.at("D8 2D ? ? ? ? D9 1D ? ? ? ? E9 ? ? ? ? D9 05 ? ? ? ? D8 4D ? D8 2D"):add(2)
local maxLevelAnimAddr = memory.at("D9 05 ? ? ? ? D8 4D ? D8 2D ? ? ? ? D9 1D ? ? ? ? E9"):add(2)
local maxBossAnimAddr = memory.at("D9 05 ? ? ? ? D8 4D ? D8 2D ? ? ? ? D9 1D ? ? ? ? 8B 4D"):add(2)
local defaultLevelAnimAddr = maxLevelAnimAddr:add(9)
local defaultBossAnimAddr = maxBossAnimAddr:add(9)

local zoomOne = ffi.new("float[1]", { 1 })
local zoomHalf = ffi.new("float[1]", { 0.5 })
local zoomOneSixth = ffi.new("float[1]", { 0.6 })
local function applyZoom()
    zoomOne[0] = zoomStatic(1)
    zoomHalf[0] = zoomStatic(0.5)
    zoomOneSixth[0] = zoomStatic(0.6)

    replacement:writeNearCall(tonumber(ffi.cast("uint32_t", setCamPosCallback)))
    replacement:add(5):writeInt16(0x9066)

    camZoom:writeFloat(zoomStatic(1))
    defaultZoomAddr:writeFloat(zoomStatic(1))
    cheatkeyDefaultZoomAddr:writeFloat(zoomStatic(1))
    editorKeyDefaultZoomAddr:writeFloat(zoomStatic(1))
    editorUIDefaultZoomAddr:writeFloat(zoomStatic(1))
    postEditorDefaultZoomAddr:writeFloat(zoomStatic(1))
    cheatkeyMinZoomAddr:writeFloat(zoomStatic(0.5))
    cheatkeyMaxZoomAddr:writeFloat(zoomStatic(5))

    defaultZoomInAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
    maxLevelAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomHalf)))
    maxBossAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOneSixth)))
    defaultLevelAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
    defaultBossAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
end
--#endregion

--#region Main menu
local mainMenuXAddr = memory.at("C7 45 ? ? ? ? ? D9 05 ? ? ? ? D8 05 ? ? ? ? D9 5D ? C7 45"):add(3)
local mainHelloXAddr = memory.at("C7 45 ? ? ? ? ? C7 45 ? ? ? ? ? 8D 4D ? E8 ? ? ? ? 68 ? ? ? ? 8B 55"):add(3)
local mainTrophiesXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? C7 45 ? ? ? ? ? C7 45 ? ? ? ? ? 8D 4D"):add(1)
local mainTipXAddr = memory.at("68 ? ? ? ? 8D 8D ? ? ? ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? 8B 4D"):add(1)
local mainCowProjectionAddr = memory.at("D9 1C 24 E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? 6A"):add(3)
local mainParticlesProjectionAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? E8 ? ? ? ? E8 ? ? ? ? E8"):add(1)
local mainProjectionAddr = memory.at("FF 92 ? ? ? ? 68 ? ? ? ? 68"):add(6 + 5 + 5 + 5 + 1)
local mainBgAddr = memory.at("68 ? ? ? ? 6A ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? C7 45"):add(1)
local cowResetProjectionAddr = memory.at("83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 8B E5"):add(3 + 2 + 5 + 3 + 2 + 5 + 3 + 5 + 5 + 5 + 1)

local function setCowRenderProjection(a1, a2, a3, a4)
    setRenderProjection(12 * ratio, 12, 1, 300)
end
local setCowRenderProjectionCallback = ffi.cast("void (*)(float a1, float a2, float a3, float a4)", setCowRenderProjection)

local function applyMainMenu()
    mainMenuXAddr:writeFloat(bindToRight(250))
    mainHelloXAddr:writeFloat(bindToLeft(-240))
    mainTrophiesXAddr:writeFloat(bindToRight(320))
    mainTipXAddr:writeFloat(bindToRight(170))
    mainCowProjectionAddr:writeNearCall(tonumber(ffi.cast("uint32_t", setCowRenderProjectionCallback)) --[[@as number]])
    mainParticlesProjectionAddr:writeFloat(w)
    mainProjectionAddr:writeFloat(perfectW)
    mainBgAddr:writeFloat(perfectW)
    cowResetProjectionAddr:writeFloat(w)
end
--#endregion

--#region Map
local mapProjectionAddr = memory.at("FF 91 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68"):add(6 + 5 + 5 + 5 + 1)
local mapRenderBackAddr = memory.at("50 68 ? ? ? ? 68 ? ? ? ? 6A ? 6A ? E8 ? ? ? ? 83 C4 ? 6A"):add(1 + 5 + 1)
local mapStatsOriginAddr = memory.at("83 C4 ? 6A ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D"):add(3 + 2 + 5 + 1)
local mapAnimXAddr = memory.at("50 6A ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 8B 48"):add(1 + 2 + 5 + 1)
local mapDiaryXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 83 7D ? ? 7E"):add(1)
local mapStartButtonXAddr = memory.at("C7 45 ? ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D"):add(6 + 1 + 5 + 1)
local mapBackButtonXAddr = memory.at("68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 45"):add(1)
local mapClipPlaneAddr = memory.at("B9 ? ? ? ? E8 ? ? ? ? 8B C8 E8 ? ? ? ? 8B C8 E8 ? ? ? ? 8B C8"):add(1):readOffset()
local mapDefaultClipPlaneAddr = memory.at("A3 ? ? ? ? 68 ? ? ? ? FF 15 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68"):add(5 + 5 + 6 + 5 + 1)

local function applyMap()
    mapProjectionAddr:writeFloat(perfectW)
    mapRenderBackAddr:writeFloat(perfectW)
    mapStatsOriginAddr:writeFloat(bindToRightStatic(248))
    mapAnimXAddr:writeFloat(bindToRightStatic(257))
    mapDiaryXAddr:writeFloat(bindToRightStatic(160))
    mapStartButtonXAddr:writeFloat(bindToRightStatic(258))
    mapBackButtonXAddr:writeFloat(bindToLeftStatic(-364))
    mapClipPlaneAddr:writeFloat(bindToLeftStatic(-384))
    mapClipPlaneAddr:add(8):writeFloat(bindToRightStatic(112))
    mapDefaultClipPlaneAddr:writeFloat(bindToRightStatic(112))
    mapDefaultClipPlaneAddr:add(4 + 5 + 1):writeFloat(bindToLeftStatic(-384))
end
--#endregion

--#region Trophies
local trophiesRenderBackAddr = memory.at("50 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? D9 05"):add(1 + 5 + 1)
local trophiesProjectionAddr = memory.at("83 C4 ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? E8 ? ? ? ? 83 C4 ? B9"):add(3 + 5 + 5 + 5 + 1)

local function applyTrophies()
    trophiesRenderBackAddr:writeFloat(perfectW / 2)
    trophiesRenderBackAddr:add(4 + 5 + 1):writeFloat(perfectW / -2)
    trophiesProjectionAddr:writeFloat(perfectW)
end
--#endregion

--#region Game UI
local gameHealthBarPosAddr = memory.at("68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 8D ? ? ? ? E8 ? ? ? ? 50 E8"):add(1)
local gameHeartAnimXAddr = memory.at("68 ? ? ? ? 8D 8D ? ? ? ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 B9"):add(1)
local gameHealthBarFillXAddr = memory.at("68 ? ? ? ? 8D 8D ? ? ? ? E8 ? ? ? ? 50 8D 4D ? E8 ? ? ? ? D9 05"):add(1)
local gameHealthCountXAddr = memory.at("C7 45 ? ? ? ? ? D9 05 ? ? ? ? D8 35"):add(3)
local gameScoreXAddr = memory.at("C7 45 ? ? ? ? ? C7 45 ? ? ? ? ? 8B 0D ? ? ? ? 51 68"):add(3)
local gameLevelXAddr = memory.at("C7 45 ? ? ? ? ? C7 45 ? ? ? ? ? 8B 0D ? ? ? ? 51 E8 ? ? ? ? 83 C4 ? 6A"):add(3)
local gameTaskBgXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? A1 ? ? ? ? 8B 0C 85 ? ? ? ? 51 E8 ? ? ? ? 83 C4 ? 6A"):add(1)
local gameTaskIconXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 8B 4D ? 51 8B 55"):add(1)
local gameTaskTextXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 0F B6 05 ? ? ? ? 85 C0 0F 85"):add(1)
local gameTaskYAddr = memory.at("C7 45 ? ? ? ? ? 83 3D ? ? ? ? ? 0F 8E"):add(3)

local function applyGame()
    local offsetX = 0
    local offsetY = 0

    if offsetEnabledBuf[0] then
        offsetX = offsetValueBuf[0]
        offsetY = offsetValueBuf[1]
    end

    gameHealthBarPosAddr:add(4 + 5 + 1):writeFloat(bindToLeft(leftOffset(-400, offsetX)))
    gameHealthBarPosAddr:writeFloat(bindToLeft(leftOffset(-144, offsetX)))
    gameHealthBarPosAddr:add(-5):writeFloat(leftOffset(-300, offsetY)) -- Y value
    gameHealthBarPosAddr:add(4 + 1):writeFloat(leftOffset(-172, offsetY)) -- Y value

    gameHeartAnimXAddr:writeFloat(bindToLeft(leftOffset(-293, offsetX)))

    gameHealthBarFillXAddr:writeFloat(bindToLeft(leftOffset(-258, offsetX)))
    gameHealthBarFillXAddr:add(-5):writeFloat(leftOffset(-288, offsetY)) -- Y value

    gameHealthCountXAddr:writeFloat(bindToLeft(leftOffset(-330, offsetX)))
    gameHealthCountXAddr:add(-7):writeFloat(leftOffset(-270, offsetY)) -- Y value

    gameScoreXAddr:writeFloat(bindToRight(rightOffset(370, offsetX)))
    gameScoreXAddr:add(7):writeFloat(leftOffset(-284, offsetY)) -- Y value

    gameLevelXAddr:writeFloat(bindToRight(rightOffset(350, offsetX)))
    gameLevelXAddr:add(7):writeFloat(rightOffset(281, offsetY)) -- Y value

    gameTaskBgXAddr:writeFloat(bindToLeft(leftOffset(-339, offsetX)))
    gameTaskIconXAddr:writeFloat(bindToLeft(leftOffset(-293, offsetX)))
    gameTaskTextXAddr:writeFloat(bindToLeft(leftOffset(-362, offsetX)))
    gameTaskYAddr:writeFloat(rightOffset(282, offsetY)) -- Y value
end
--#endregion

--#region Dialogue
local dialogueSetInnerProjection = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 6A ? 6A ? 8B 15 ? ? ? ? 8B 02 8B 0D ? ? ? ? 51 FF 90 ? ? ? ? 6A"):add(1)
local dialogueSkipDefaultXAddr = memory.at("68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9"):add(1)
local dialogueSkipXAddr = memory.at("68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9"):add(5 + 3 + 5 + 2):readOffset()
local dialogueRenderBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 50 ? 52 8B 00 50 E8 ? ? ? ? 83 C4 ? 6A"):add(1)
local happyEndRenderBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? D9 05"):add(1)
local happyEndRender1Bg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 50 ? 52 8B 00 50 E8 ? ? ? ? 83 C4 ? D9 45"):add(1)
local happyEndWhiteBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? 6A"):add(1)

local function applyDialogue()
    dialogueSetInnerProjection:writeFloat(w)
    dialogueSkipDefaultXAddr:writeFloat(bindToLeft(-320))
    dialogueSkipXAddr:writeFloat(bindToLeft(-400))
    dialogueSkipXAddr:add(8):writeFloat(bindToLeft(-280))
    dialogueRenderBg:writeFloat(w)
    happyEndRenderBg:writeFloat(w)
    happyEndRender1Bg:writeFloat(w)
    happyEndWhiteBg:writeFloat(w)
end
--#endregion

--#region Credits
local creditsDogProjectionAddr = memory.at("FF 92 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 68"):add(6 + 2 + 5 + 3 + 2 + 5 + 3 + 5 + 5 + 5 + 1)
local creditsDogMainProjectionAddr = memory.at("D9 05 ? ? ? ? D8 4D ? 51 D9 1C 24 E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? 6A ? A1")
local hiscoreRenderLevelbackAddr = memory.at("E8 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? D9 05 ? ? ? ? D8 25")
local creditsRenderLevelbackAddr = memory.at("E8 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? 8B 45 ? A3")

local renderLevelbackAddr = memory.at("55 8B EC 81 EC ? ? ? ? D9 05 ? ? ? ? D8 05 ? ? ? ? D9 1D ? ? ? ? 8D 4D ? E8 ? ? ? ? B9")
local renderLevelback = renderLevelbackAddr:getFunction("void (*)()")

local function setLevelBackRenderProjection()
    renderLevelback()
    setRenderProjection(w, h, 1, 500)
    return 0
end
local setLevelBackRenderProjectionCallback = ffi.cast("void (*)()", setLevelBackRenderProjection)

local function applyCredits()  
    creditsDogProjectionAddr:writeFloat(w)
    creditsDogMainProjectionAddr:writeChar(0x68);
    creditsDogMainProjectionAddr:add(1):writeFloat(w * 0.03125);
    creditsDogMainProjectionAddr:add(5):writeNop(8)
    hiscoreRenderLevelbackAddr:writeNearCall(tonumber(ffi.cast("uint32_t", setLevelBackRenderProjectionCallback)) --[[@as number]])
    creditsRenderLevelbackAddr:writeNearCall(tonumber(ffi.cast("uint32_t", setLevelBackRenderProjectionCallback)) --[[@as number]])
end
--#endregion

--#region Levelbacks
local widthBuf = ffi.new("float[1]", { w })

local levelbackProj = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 8D 4D"):add(1)
local levelbacksWidth1 = memory.at("D9 05 ? ? ? ? D8 70"):add(2)
local levelbacksWidth2 = memory.at("68 ? ? ? ? 8B 4D ? 51 6A ? 8D 8D"):add(1)
local levelbacksWidth3 = memory.at("D9 05 ? ? ? ? D8 75 ? D8 45 ? 51 D9 1C 24 6A ? 8B 55"):add(2)
local levelbacksWidth4 = memory.at("D9 05 ? ? ? ? D8 75 ? D8 45 ? 51 D9 1C 24 D9 05"):add(2)
local levelbacksWidth5 = memory.at("68 ? ? ? ? 8B 45 ? 50 6A ? 8D 8D"):add(1)

local function applyLevelBacks()
    widthBuf[0] = w

    levelbackProj:writeFloat(w)
    levelbacksWidth1:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth2:writeFloat(w)
    levelbacksWidth3:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth4:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth5:writeFloat(w)
end

--#region Misc
local resetProjectionAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 5D C3 CC 55"):add(1)
local introBgWidthAddr = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 8D ? ? ? ? E8 ? ? ? ? 8B 48"):add(1)
local loadScreenSizeAddr = memory.at("68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 E8 ? ? ? ? 83 C4 ? DB 05"):add(5 + 1)
local splashSizeAddr = memory.at("68 ? ? ? ? 8B ? FC ? 68 00 00 16 3F 68 00 00 48 3F 6A 00 6A 00 8D 4D ? E8 ? ? ? ? 50 68 00 00 96 C3"):add(5 + 3 + 1 + 5 + 5 + 2 + 2 + 3 + 5 + 1):add(5 + 1)
local defaultMenuXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 5D C3 CC CC CC 55 8B EC 83 EC"):add(1)

local function applyMisc()
    resetProjectionAddr:writeFloat(w)
    introBgWidthAddr:writeFloat(w)
    loadScreenSizeAddr:writeFloat(bindToRightStatic(400))
    loadScreenSizeAddr:add(4 + 5 + 1):writeFloat(bindToLeftStatic(-400))
    splashSizeAddr:writeFloat(bindToRight(400))
    splashSizeAddr:add(4 + 5 + 1):writeFloat(bindToLeft(-400))
    defaultMenuXAddr:writeFloat(bindToRight(230))
end
--#endregion

local function apply()
    applyMainMenu()
    applyMap()
    applyTrophies()
    applyGame()
    applyDialogue()
    applyCredits()
    applyMisc()
    applyLevelBacks()
    applyZoom()
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

events.on("_unload", function()
    memory.restoreBackups(backup)
    setCowRenderProjectionCallback:free()
    setLevelBackRenderProjectionCallback:free()
    setCamPosCallback:free()
end)

function renderUi()
    if imgui.Checkbox("Включить отступы HUD", offsetEnabledBuf) then
        config.mod:set('offset', offsetEnabledBuf[0])
        apply()
    end

    if offsetEnabledBuf[0] then
        if imgui.InputFloat2("Отступы", offsetValueBuf) then
            config.mod:set('offsetX', offsetValueBuf[0])
            config.mod:set('offsetY', offsetValueBuf[1])
            apply()
        end

        if imgui.Button("Сбросить отступы") then
            offsetValueBuf[0] = defaultOffsetX
            offsetValueBuf[1] = defaultOffsetY
            config.mod:set('offsetX', defaultOffsetX)
            config.mod:set('offsetY', defaultOffsetY)
            apply()
        end
    end
end
