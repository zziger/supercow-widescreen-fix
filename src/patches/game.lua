local ffi = require("ffi")

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
local gameScoreParticlesXAddr = memory.at("C7 45 ? ? ? ? ? D9 45 ? D8 1D ? ? ? ? DF E0 F6 C4 ? 7A ? DB 05"):add(3)
local gameScoreParticlesYAddr = memory.at("D8 05 ? ? ? ? 51 D9 1C 24 68 ? ? ? ? E8 ? ? ? ? 83 C4 ? D8 6D"):add(2)
local gameScoreParticlesYNew = ffi.new("float[1]", { -270 })

return function()
    local offsetX = 0
    local offsetY = 0

    if offsetEnabledBuf[0] then
        offsetX = offsetValueBuf[0]
        offsetY = offsetValueBuf[1]
    end

    gameScoreParticlesYNew[0] = leftOffset(-270, offsetY)

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

    gameScoreParticlesXAddr:writeFloat(bindToRight(rightOffset(380, offsetX)))
    gameScoreParticlesYAddr:writeInt(tonumber(ffi.cast("uintptr_t", gameScoreParticlesYNew)))

    gameLevelXAddr:writeFloat(bindToRight(rightOffset(350, offsetX)))
    gameLevelXAddr:add(7):writeFloat(rightOffset(281, offsetY)) -- Y value

    gameTaskBgXAddr:writeFloat(bindToLeft(leftOffset(-339, offsetX)))
    gameTaskIconXAddr:writeFloat(bindToLeft(leftOffset(-293, offsetX)))
    gameTaskTextXAddr:writeFloat(bindToLeft(leftOffset(-362, offsetX)))
    gameTaskYAddr:writeFloat(rightOffset(282, offsetY)) -- Y value
end