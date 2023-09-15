local ffi = require("ffi")
local events = require("events")

local mapProjectionAddr = memory.at("FF 91 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68"):add(6 + 5 + 5 + 5 + 1)
local mapRenderBackAddr = memory.at("50 68 ? ? ? ? 68 ? ? ? ? 6A ? 6A ? E8 ? ? ? ? 83 C4 ? 6A"):add(1 + 5 + 1)
local mapStatsOriginAddr = memory.at("83 C4 ? 6A ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D"):add(3 + 2 + 5 + 1)
local mapAnimXAddr = memory.at("50 6A ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 8B 48"):add(1 + 2 + 5 + 1)
local mapDiaryXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 83 7D ? ? 7E"):add(1)
local mapStartButtonXAddr = memory.at("C7 45 ? ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D"):add(6 + 1 + 5 + 1)
local mapBackButtonXAddr = memory.at("68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 45"):add(1)
local mapClipPlaneAddr = memory.at("B9 ? ? ? ? E8 ? ? ? ? 8B C8 E8 ? ? ? ? 8B C8 E8 ? ? ? ? 8B C8"):add(1):readOffset()
local mapDefaultClipPlaneAddr = memory.at("A3 ? ? ? ? 68 ? ? ? ? FF 15 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68"):add(5 + 5 + 6 + 5 + 1)
local mapPos = memory.at("B9 ? ? ? ? E8 ? ? ? ? D8 0D ? ? ? ? D8 6D ? D8 9D"):add(1):readOffset()

local setMapBoundaryLeft = memory.at("E8 ? ? ? ? 8D 4D ? E8 ? ? ? ? 68 ? ? ? ? 8D 85")
local setMapBoundaryRight = memory.at("E8 ? ? ? ? D9 45 ? E8 ? ? ? ? 89 85 ? ? ? ? DB 85 ? ? ? ? D8 5D")

local function mapApplyLeftBoundary(this_, x, y)
    local mapWidth = math.abs(mapPos:readFloat() - mapPos:add(8):readFloat())
    this_[0] = bindToLeftStatic(-384) + mapWidth / 2
    this_[1] = y
end
local mapApplyLeftBoundaryCallback = ffi.cast("void (__thiscall *)(float*, float, float)", mapApplyLeftBoundary)

local function mapApplyRightBoundary(this_, x, y)
    local mapWidth = math.abs(mapPos:readFloat() - mapPos:add(8):readFloat())
    this_[0] = bindToRightStatic(112) - mapWidth / 2
    this_[1] = y
end
local mapApplyRightBoundaryCallback = ffi.cast("void (__thiscall *)(float*, float, float)", mapApplyRightBoundary)

-- This image is a representation of data in the Z axis of rendered sprite position
-- ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣠⣤⣤⣀⠀⠀
-- ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
-- ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
-- ⠀⠀⠀⠀⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
-- ⠀⠀⠀⠀⢀⣀⢾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢋⣭⡍⣿⣿⣿⣿⣿⣿⠀
-- ⠀⢀⣴⣶⣶⣝⢷⡝⢿⣿⣿⣿⠿⠛⠉⠀⠀⣰⣿⣿⢣⣿⣿⣿⣿⣿⣿⡇
-- ⢀⣾⣿⣿⣿⣿⣧⠻⡌⠿⠋⠁⠀⠀⠀⠀⢰⣿⣿⡏⣸⣿⣿⣿⣿⣿⣿⣿
-- ⣼⣿⣿⣿⣿⣿⣿⡇⠁⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⠇⢻⣿⣿⣿⣿⣿⣿⡟
-- ⠙⢹⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⣿⡿⠟⠁
-- ⠀⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
local convertVector2Addr = memory.at("E8 ? ? ? ? 50 8D 4D ? E8 ? ? ? ? 50 E8")
local function convertVector2(vec)
    vec[2] = 0
    return vec
end
local convertVector2Cb = ffi.cast("float* (__thiscall *)(float*)", convertVector2);

local mapRenderAddr = memory.at("55 8B EC 51 89 4D ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? 6A")
local mapRenderHook
mapRenderHook = mapRenderAddr:hook("void(__thiscall *)(void*)", function(this)
    inPerfectProjection = true
    mapRenderHook.orig(this)
    inPerfectProjection = false
end)

events.on("_unload", function ()
    mapApplyLeftBoundaryCallback:free()
    mapApplyRightBoundaryCallback:free()
    convertVector2Cb:free()
    mapClipPlaneAddr:writeFloat(-384)
    mapClipPlaneAddr:add(8):writeFloat(112)
end)

return function()
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
    convertVector2Addr:writeNearCall(tonumber(ffi.cast("uintptr_t", convertVector2Cb)))
    setMapBoundaryLeft:writeNearCall(tonumber(ffi.cast("uint32_t", mapApplyRightBoundaryCallback)) --[[@as number]])
    setMapBoundaryRight:writeNearCall(tonumber(ffi.cast("uint32_t", mapApplyLeftBoundaryCallback)) --[[@as number]])
end