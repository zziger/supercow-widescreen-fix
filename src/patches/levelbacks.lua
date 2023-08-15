local ffi = require("ffi")

local levelbackProj = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? 8D 4D"):add(1)
local levelbacksWidth1 = memory.at("D9 05 ? ? ? ? D8 70"):add(2)
local levelbacksWidth2 = memory.at("68 ? ? ? ? 8B 4D ? 51 6A ? 8D 8D"):add(1)
local levelbacksWidth3 = memory.at("D9 05 ? ? ? ? D8 75 ? D8 45 ? 51 D9 1C 24 6A ? 8B 55"):add(2)
local levelbacksWidth4 = memory.at("D9 05 ? ? ? ? D8 75 ? D8 45 ? 51 D9 1C 24 D9 05"):add(2)
local levelbacksWidth5 = memory.at("68 ? ? ? ? 8B 45 ? 50 6A ? 8D 8D"):add(1)

local widthBuf = ffi.new("float[1]", { w })

return function()
    widthBuf[0] = w

    levelbackProj:writeFloat(w)
    levelbacksWidth1:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth2:writeFloat(w)
    levelbacksWidth3:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth4:writeInt(tonumber(ffi.cast("uintptr_t", widthBuf)))
    levelbacksWidth5:writeFloat(w)
end