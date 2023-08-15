local editorUiX = memory.at("C7 45 ? ? ? ? ? C7 45 ? ? ? ? ? 8B 0D ? ? ? ? 83 C1"):add(3)

return function()
    local offsetX = 0
    local offsetY = 0

    if offsetEnabledBuf[0] then
        offsetX = offsetValueBuf[0]
        offsetY = offsetValueBuf[1]
    end

    editorUiX:writeFloat(bindToRight(rightOffset(290, offsetX)))
    editorUiX:add(7):writeFloat(leftOffset(-240, offsetY))
end