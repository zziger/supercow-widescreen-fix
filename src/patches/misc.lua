local resetProjectionAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 5D C3 CC 55"):add(1)
local introBgWidthAddr = memory.at("68 ? ? ? ? 6A ? 6A ? 8D 8D ? ? ? ? E8 ? ? ? ? 8B 48"):add(1)
local loadScreenSizeAddr = memory.at("68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 E8 ? ? ? ? 83 C4 ? DB 05"):add(5 + 1)
local splashSizeAddr = memory.at("68 ? ? ? ? 8B ? FC ? 68 00 00 16 3F 68 00 00 48 3F 6A 00 6A 00 8D 4D ? E8 ? ? ? ? 50 68 00 00 96 C3"):add(5 + 3 + 1 + 5 + 5 + 2 + 2 + 3 + 5 + 1):add(5 + 1)
local defaultMenuXAddr = memory.at("68 ? ? ? ? E8 ? ? ? ? 83 C4 ? 5D C3 CC CC CC 55 8B EC 83 EC"):add(1)
local cursorMinXJnpAddr = memory.at("7B ? D9 45 ? D8 1D ? ? ? ? DF E0 F6 C4 ? 74")
local cursorMaxXJnpAddr = memory.at("74 ? D9 45 ? D8 1D ? ? ? ? DF E0 F6 C4 ? 74")

return function()
    cursorMinXJnpAddr:writeNop(2)
    cursorMaxXJnpAddr:writeNop(2)
    resetProjectionAddr:writeFloat(w)
    introBgWidthAddr:writeFloat(w)
    loadScreenSizeAddr:writeFloat(bindToRightStatic(400))
    loadScreenSizeAddr:add(4 + 5 + 1):writeFloat(bindToLeftStatic(-400))
    splashSizeAddr:writeFloat(bindToRight(400))
    splashSizeAddr:add(4 + 5 + 1):writeFloat(bindToLeft(-400))
    defaultMenuXAddr:writeFloat(bindToRight(230))
end