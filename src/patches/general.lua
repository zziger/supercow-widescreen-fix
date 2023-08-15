local getCursorPosAddr = memory.at("55 8B EC 83 EC ? 8D 45 ? 50 8B 0D ? ? ? ? 51 FF 15 ? ? ? ? 8D 55 ? 52 A1 ? ? ? ? 50 FF 15 ? ? ? ? 8D 4D ? 51 FF 15 ? ? ? ? 8B 55 ? 2B 55 ? 89 55 ? 8B 45 ? 2B 45 ? 8B 4D ? 2B C8 89 4D ? DB 45")
local getCursorPosHook;
getCursorPosHook = getCursorPosAddr:hook("void(__cdecl *)(float*, float*)",
    function(x, y)
        getCursorPosHook.orig(x, y)
        if inPerfectProjection then
            x[0] = (x[0] + 400) / 800 * perfectW - (perfectW / 2)
        else
            x[0] = (x[0] + 400) / 800 * w - (w / 2)
        end
    end, { jit = true })

local renderAnimBackAddr = memory.at("55 8B EC 83 EC ? D9 45 ? D8 25 ? ? ? ? D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 55 ? D9 E0 D9 5D ? D9 45 ? D8 25 ? ? ? ? D9 55 ? D9 E0 D9 5D ? D9 45")
local renderAnimBackHook;
renderAnimBackHook = renderAnimBackAddr:hook("void (__cdecl *)(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, int a9)", 
    function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        renderAnimBackHook.orig(perfectW / -2 + 400, a2, perfectW, a4, a5, a6, 0.88, a8, a9)
    end)

local mapStartButtonCollisionXAddr = memory.at("B9 ? ? ? ? E8 ? ? ? ? 0F B6 C0 85 C0 74 ? D9 05"):add(1):readOffset()
local tipZoomModifierAddr = memory.at("68 ? ? ? ? 8D 45 ? 50 68"):add(1)

return function()
    tipZoomModifierAddr:writeFloat(32 / (realH / 600) / camZoom:readFloat())
    mapStartButtonCollisionXAddr:writeFloat(bindToRightStatic(130))
    mapStartButtonCollisionXAddr:add(8):writeFloat(bindToRightStatic(386))
end