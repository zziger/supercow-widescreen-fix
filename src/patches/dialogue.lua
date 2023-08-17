local ffi = require("ffi")
local events = require("events")

local dialogueSetInnerProjection = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 6A ? 6A ? 8B 15 ? ? ? ? 8B 02 8B 0D ? ? ? ? 51 FF 90 ? ? ? ? 6A"):add(1)
local dialogueSkipDefaultXAddr = memory.at("68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9"):add(1)
local dialogueSkipXAddr = dialogueSkipDefaultXAddr:add(4 + 3 + 5 + 2):readOffset()
local dialogueRenderBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 50 ? 52 8B 00 50 E8 ? ? ? ? 83 C4 ? 6A"):add(1)
local happyEndRenderBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? D9 05"):add(1)
local happyEndRender1Bg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 50 ? 52 8B 00 50 E8 ? ? ? ? 83 C4 ? D9 45"):add(1)
local happyEndWhiteBg = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 4D ? E8 ? ? ? ? 8B 48 ? 51 8B 10 52 E8 ? ? ? ? 83 C4 ? 6A"):add(1)
local dialogueCowProjection = memory.at("E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? 6A ? 8B 0D")

local function setCowRenderProjection(a1, a2, a3, a4)
    setRenderProjection(12 * 0.3 * ratio, a2, a3, a4)
end
local setCowRenderProjectionCallback = ffi.cast("void (*)(float a1, float a2, float a3, float a4)", setCowRenderProjection)

events.on("_unload", function()
    setCowRenderProjectionCallback:free()
end)

return function()
    local offsetX = 0
    local offsetY = 0

    if offsetEnabledBuf[0] then
        offsetX = offsetValueBuf[0]
        offsetY = offsetValueBuf[1]
    end

    dialogueCowProjection:writeNearCall(tonumber(ffi.cast("uint32_t", setCowRenderProjectionCallback)) --[[@as number]])
    dialogueSetInnerProjection:writeFloat(w)
    dialogueSkipDefaultXAddr:writeFloat(bindToLeft(-320))
    dialogueSkipXAddr:writeFloat(bindToLeft(leftOffset(-400, offsetX)))
    dialogueSkipXAddr:add(4):writeFloat(rightOffset(295, offsetY))
    dialogueSkipXAddr:add(8):writeFloat(bindToLeft(leftOffset(-240, offsetX)))
    dialogueSkipXAddr:add(12):writeFloat(rightOffset(279, offsetY))
    dialogueRenderBg:writeFloat(w)
    happyEndRenderBg:writeFloat(w)
    happyEndRender1Bg:writeFloat(w)
    happyEndWhiteBg:writeFloat(w)
end