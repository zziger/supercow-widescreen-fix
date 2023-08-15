local ffi = require("ffi")
local events = require("events")

local replacement = memory.at("D9 1D ? ? ? ? C6 05 ? ? ? ? ? C6 05"):add(6)
local camWorldWidth = memory.at("D9 05 ? ? ? ? D8 25 ? ? ? ? 51 D9 1C 24 8B 45"):add(2):readOffset()
local maxWorldBorderX = memory.at("C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? C7 45 ? ? ? ? ? EB ? 8B 4D"):add(2)
local minWorldBorderX = maxWorldBorderX:add(10):readOffset()
local deathToggle = replacement:add(2):readOffset()
local updateCamPos = memory.at("55 8B EC 83 EC ? C7 45 ? ? ? ? ? 83 3D"):getFunction("void(*)()")
local loadGameScene = memory.at("55 8B EC 51 89 4D ? A1")
local performCamAnim = memory.at("55 8B EC 83 EC ? D9 05 ? ? ? ? D8 1D ? ? ? ? DF E0 F6 C4 ? 7A ? E9 ? ? ? ? D9 05")
local camPosX = memory.at("89 15 ? ? ? ? A3 ? ? ? ? D9 05 ? ? ? ? D8 05"):add(2):readOffset()
local camAnimType = memory.at("A1 ? ? ? ? 89 45 ? 83 7D ? ? 0F 87"):add(1):readOffset()
local camAnimTime = memory.at("D9 05 ? ? ? ? D8 35 ? ? ? ? D9 5D ? A1"):add(2):readOffset()
local camAnimDuration = memory.at("D8 35 ? ? ? ? D9 5D ? A1 ? ? ? ? 89 45"):add(2):readOffset()
local cowPosX = memory.at("B9 ? ? ? ? E8 ? ? ? ? C7 45 ? ? ? ? ? EB ? 8B 4D ? 83 C1 ? 89 4D ? 8B 55 ? 3B 15 ? ? ? ? 0F 8D"):add(1):readOffset():add(0x24)

local loadLevelHook
loadLevelHook = loadGameScene:hook("void(__cdecl *)(int)",
    function(a1)
        loadLevelHook.orig(a1)
        updateCamPos()
    end)

local camAnimHook
camAnimHook = performCamAnim:hook("void(*)()",
    function()
        if camAnimType:readInt() == 1 then
            local time = camAnimTime:readFloat() / camAnimDuration:readFloat()
            camPosX:writeFloat(lerp(camPosX:readFloat(), -cowPosX:readFloat(), time))
        end
        camAnimHook.orig()
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
local baseSceneZoomIfMin = memory.at("D8 1D ? ? ? ? DF E0 F6 C4 ? 7A ? C7 05 ? ? ? ? ? ? ? ? EB ? D9 45"):add(2)
local baseSceneZoomIfMax = memory.at("D8 1D ? ? ? ? DF E0 F6 C4 ? 75 ? C7 05 ? ? ? ? ? ? ? ? EB ? 8B 55"):add(2)
local editorZoomPercentsAddr = memory.at("D8 0D ? ? ? ? 83 EC"):add(2)

local levelDoneAnimDuration = memory.at("C7 05 ? ? ? ? ? ? ? ? EB ? C7 05 ? ? ? ? ? ? ? ? EB ? C7 05 ? ? ? ? ? ? ? ? 8B E5"):add(6)
local defaultZoomInAnimAddr = memory.at("D8 2D ? ? ? ? D9 1D ? ? ? ? E9 ? ? ? ? D9 05 ? ? ? ? D8 4D ? D8 2D"):add(2)
local maxLevelAnimAddr = memory.at("D9 05 ? ? ? ? D8 4D ? D8 2D ? ? ? ? D9 1D ? ? ? ? E9"):add(2)
local maxBossAnimAddr = memory.at("D9 05 ? ? ? ? D8 4D ? D8 2D ? ? ? ? D9 1D ? ? ? ? 8B 4D"):add(2)
local defaultLevelAnimAddr = maxLevelAnimAddr:add(9)
local defaultBossAnimAddr = maxBossAnimAddr:add(9)

local zoomOne = ffi.new("float[1]", { 1 })
local zoomHalf = ffi.new("float[1]", { 0.5 })
local zoomOneSixth = ffi.new("float[1]", { 0.6 })
local zoomMax = ffi.new("float[1]", { 5 })
local editorZoomPercents = ffi.new("float[1]", { 100 })
local lastDefaultZoom = 1

events.on("_unload", function()
    setCamPosCallback:free()
end)

return function()
    print("yay")
    zoomOne[0] = zoomStatic(1)
    zoomHalf[0] = zoomStatic(0.5)
    zoomOneSixth[0] = zoomStatic(0.6)
    zoomMax[0] = zoomStatic(5)
    editorZoomPercents[0] = 100 / zoomOne[0]
    local zoomHalfAddr = tonumber(ffi.cast("uintptr_t", zoomHalf))

    replacement:writeNearCall(tonumber(ffi.cast("uint32_t", setCamPosCallback)))
    replacement:add(5):writeInt16(0x9066)

    camZoom:writeFloat(camZoom:readFloat() / lastDefaultZoom * zoomOne[0])
    editorZoomPercentsAddr:writeInt(tonumber(ffi.cast("uintptr_t", editorZoomPercents)))
    defaultZoomAddr:writeFloat(zoomOne[0])
    cheatkeyDefaultZoomAddr:writeFloat(zoomOne[0])
    editorKeyDefaultZoomAddr:writeFloat(zoomOne[0])
    editorUIDefaultZoomAddr:writeFloat(zoomOne[0])
    postEditorDefaultZoomAddr:writeFloat(zoomOne[0])
    cheatkeyMinZoomAddr:writeFloat(zoomHalf[0])
    cheatkeyMaxZoomAddr:writeFloat(zoomMax[0])
    baseSceneZoomIfMin:writeInt(zoomHalfAddr)
    baseSceneZoomIfMax:writeInt(tonumber(ffi.cast("uintptr_t", zoomMax)))
    lastDefaultZoom = zoomOne[0]

    defaultZoomInAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
    maxLevelAnimAddr:writeInt(zoomHalfAddr)
    maxBossAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOneSixth)))
    defaultLevelAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
    defaultBossAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOne)))
    levelDoneAnimDuration:writeFloat(5500) -- prevents camera from clamping to level right border on level end anim
end