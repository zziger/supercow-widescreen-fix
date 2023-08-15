local ffi = require("ffi")
local events = require("events")

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

events.on("_unload", function()
    setCowRenderProjectionCallback:free()
end)

return function()
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