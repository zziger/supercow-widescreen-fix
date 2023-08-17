local ffi = require("ffi")

local camWorldWidth = memory.at("D9 05 ? ? ? ? D8 25 ? ? ? ? 51 D9 1C 24 8B 45"):add(2):readOffset()
local worldBorderAddr = memory.at("C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? C7 45 ? ? ? ? ? EB ? 8B 4D"):add(2)
local maxWorldBorderX = worldBorderAddr:add(4 + 4 + 2):readOffset()
local minWorldBorderX = worldBorderAddr:readOffset()
local updateCamPos = memory.at("55 8B EC 83 EC ? C7 45 ? ? ? ? ? 83 3D"):getFunction("void(*)()")
local loadGameScene = memory.at("55 8B EC 51 89 4D ? A1")
local performCamAnim = memory.at("55 8B EC 83 EC ? D9 05 ? ? ? ? D8 1D ? ? ? ? DF E0 F6 C4 ? 7A ? E9 ? ? ? ? D9 05")
local camPosX = memory.at("89 15 ? ? ? ? A3 ? ? ? ? D9 05 ? ? ? ? D8 05"):add(2):readOffset()
local camAnimType = memory.at("A1 ? ? ? ? 89 45 ? 83 7D ? ? 0F 87"):add(1):readOffset()
local camAnimTime = memory.at("D9 05 ? ? ? ? D8 35 ? ? ? ? D9 5D ? A1"):add(2):readOffset()
local camAnimDuration = memory.at("D8 35 ? ? ? ? D9 5D ? A1 ? ? ? ? 89 45"):add(2):readOffset()
local cowPosX = memory.at("B9 ? ? ? ? E8 ? ? ? ? C7 45 ? ? ? ? ? EB ? 8B 4D ? 83 C1 ? 89 4D ? 8B 55 ? 3B 15 ? ? ? ? 0F 8D"):add(1):readOffset():add(0x24)
camUpdateAddr = memory.at("55 8B EC 83 EC ? C7 45 ? ? ? ? ? 83 3D")

local loadLevelHook
loadLevelHook = loadGameScene:hook("void(__cdecl *)(int)", function(a1)
    loadLevelHook.orig(a1)
    updateCamPos()
end)

local camAnimHook
camAnimHook = performCamAnim:hook("void(*)()", function()
    if camAnimType:readInt() == 1 then
        local time = camAnimTime:readFloat() / camAnimDuration:readFloat()
        camPosX:writeFloat(math.lerp(camPosX:readFloat(), -cowPosX:readFloat(), time))
    end
    camAnimHook.orig()
end)

local camUpdateHook = nil
local camUpdateHookFunc = function()
    camUpdateHook.orig()
    local x = -camPosX:readFloat()
    local hw = camWorldWidth:readFloat() * 0.5

    local min = minWorldBorderX:readFloat() + hw
    local max = maxWorldBorderX:readFloat() - hw
    camPosX:writeFloat(-math.clamp(x, min, max))
end

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
local editorZoomOrigGovnofix = memory.at("8B 15 ? ? ? ? 89 15 ? ? ? ? A0 ? ? ? ? A2 ? ? ? ? 8B 0D")
local editorOldZoom = memory.at("89 15 ? ? ? ? A0 ? ? ? ? A2 ? ? ? ? 8B 0D"):add(2):readOffset()

local kostilEbaniy = true

--#region Ззёгра, если ты это читаешь, всё это (кроме булева для костыля ебаного)
-- это фикс зума редактора между игровыми сессиями, про который я тебе рассказывал в дискорде.
-- По возможности, занеси его в спермод
local editorLeaveFullscreen = memory.at("55 8B EC 83 EC ? 56 C7 05")
local editorEnterFullscreen = memory.at("55 8B EC C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? 68 ? ? ? ? 6A ? A1")

local editorOldZoomHook1
editorOldZoomHook1 = editorLeaveFullscreen:hook("bool(*)()", function()
    kostilEbaniy = false
    editorOldZoom:writeFloat(camZoom:readFloat())
    return editorOldZoomHook1.orig()
end)

local editorOldZoomHook2
editorOldZoomHook2 = editorEnterFullscreen:hook("int(*)()", function()
    kostilEbaniy = false
    editorOldZoom:writeFloat(camZoom:readFloat())
    return editorOldZoomHook2.orig()
end)
--#endregion

local leaveEditorFullscreen = memory.at("55 8B EC C7 05 ? ? ? ? ? ? ? ? C7 05 ? ? ? ? ? ? ? ? 68 ? ? ? ? 6A") -- yeah, that's another one, but slightly different

local editorZoomKostilEbaniy
editorZoomKostilEbaniy = leaveEditorFullscreen:hook("long(*)()", function()
    kostilEbaniy = true
    return editorZoomKostilEbaniy.orig()
end)

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
local lastEditorDefaultZoom = 1

return function()
    local zoom = zoomValueBuf[0]

    if cameraBoundsEnabledBuf[0] then
        if camUpdateHook and not camUpdateHook.destroyed then goto nahoy end
        camUpdateHook = camUpdateAddr:hook("void(*)()", camUpdateHookFunc)
        ::nahoy::
    else
        if camUpdateHook and camUpdateHook.destroyed then goto nahy end
        camUpdateHook.destroy()
        ::nahy::
    end

    zoomOne[0] = zoomStatic(zoom)
    zoomHalf[0] = zoomStatic(zoom * 0.5)
    zoomOneSixth[0] = zoomStatic(zoom * 0.6)
    zoomMax[0] = zoomStatic(zoom * 5)
    editorZoomPercents[0] = 100 / zoomOne[0]
    local zoomHalfAddr = tonumber(ffi.cast("uintptr_t", zoomHalf))
    local zoomOneAddr = tonumber(ffi.cast("uintptr_t", zoomOne))

    editorZoomOrigGovnofix:writeNop(12)

    if currentScene:readInt() == editorScene then
        if not kostilEbaniy then goto nahooy end
        camZoom:writeFloat(camZoom:readFloat() / lastEditorDefaultZoom * zoomOne[0])
        lastEditorDefaultZoom = zoomOne[0]
        ::nahooy::
    else
        camZoom:writeFloat(camZoom:readFloat() / lastDefaultZoom * zoomOne[0])
        lastDefaultZoom = zoomOne[0]
    end

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

    defaultZoomInAnimAddr:writeInt(zoomOneAddr)
    maxLevelAnimAddr:writeInt(zoomHalfAddr)
    maxBossAnimAddr:writeInt(tonumber(ffi.cast("uintptr_t", zoomOneSixth)))
    defaultLevelAnimAddr:writeInt(zoomOneAddr)
    defaultBossAnimAddr:writeInt(zoomOneAddr)
    levelDoneAnimDuration:writeFloat(5500) -- prevents camera from clamping to level right border on level end anim
end