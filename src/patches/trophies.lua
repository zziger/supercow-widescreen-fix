local trophiesRenderBackAddr = memory.at("50 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 8D 4D ? E8 ? ? ? ? 50 E8 ? ? ? ? 83 C4 ? 6A ? E8 ? ? ? ? 83 C4 ? D9 05"):add(1 + 5 + 1)
local trophiesProjectionAddr = memory.at("83 C4 ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? E8 ? ? ? ? 83 C4 ? B9"):add(3 + 5 + 5 + 5 + 1)

local trophiesRenderAddr = memory.at("55 8B EC 51 89 4D ? D9 05 ? ? ? ? D8 05")
local trophiesRenderHook
trophiesRenderHook = trophiesRenderAddr:hook("void(__thiscall *)(void*)", function(this)
    inPerfectProjection = true
    trophiesRenderHook.orig(this)
    inPerfectProjection = false
end)

return function()
    trophiesRenderBackAddr:writeFloat(perfectW / 2)
    trophiesRenderBackAddr:add(4 + 5 + 1):writeFloat(perfectW / -2)
    trophiesProjectionAddr:writeFloat(perfectW)
end