local ffi = require("ffi")
local events = require("events")

local creditsDogProjectionAddr = memory.at("FF 92 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 68"):add(6 + 2 + 5 + 3 + 2 + 5 + 3 + 5 + 5 + 5 + 1)
local creditsDogMainProjectionAddr = memory.at("D9 05 ? ? ? ? D8 4D ? 51 D9 1C 24 E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? 6A ? A1")
local hiscoreRenderLevelbackAddr = memory.at("E8 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? D9 05 ? ? ? ? D8 25")
local creditsRenderLevelbackAddr = memory.at("E8 ? ? ? ? 6A ? E8 ? ? ? ? 83 C4 ? 8B 45 ? A3")
local happyEndCreditsBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 50 ? 52 8B 00 50 E8 ? ? ? ? 83 C4 ? D9 05"):add(1)
local happyEndCredits1Bg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? D9 45"):add(1)
local happyEndWhiteCreditsBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 8D ? ? ? ? E8 ? ? ? ? 8B 50"):add(1)

local renderLevelbackAddr = memory.at("55 8B EC 81 EC ? ? ? ? D9 05 ? ? ? ? D8 05 ? ? ? ? D9 1D ? ? ? ? 8D 4D ? E8 ? ? ? ? B9")
local renderLevelback = renderLevelbackAddr:getFunction("void (*)()")

local function setLevelBackRenderProjection()
    renderLevelback()
    setRenderProjection(w, h, 1, 500)
    return 0
end
local setLevelBackRenderProjectionCallback = ffi.cast("void (*)()", setLevelBackRenderProjection)

events.on("_unload", function ()
    setLevelBackRenderProjectionCallback:free()
end)

return function()
    creditsDogProjectionAddr:writeFloat(w)
    creditsDogMainProjectionAddr:writeChar(0x68);
    creditsDogMainProjectionAddr:add(1):writeFloat(w * 0.03125);
    creditsDogMainProjectionAddr:add(5):writeNop(8)
    hiscoreRenderLevelbackAddr:writeNearCall(tonumber(ffi.cast("uint32_t", setLevelBackRenderProjectionCallback)) --[[@as number]])
    creditsRenderLevelbackAddr:writeNearCall(tonumber(ffi.cast("uint32_t", setLevelBackRenderProjectionCallback)) --[[@as number]])
    happyEndCreditsBg:writeFloat(w)
    happyEndCredits1Bg:writeFloat(w)
    happyEndWhiteCreditsBg:writeFloat(w)
end