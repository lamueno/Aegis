local mod = aegis
local me = {}
mod.libbuff = me

--[[
    `mod.my.buffed(buffname [, unit])` takes a localized buffname shown in the game client.
]]
me.buffed = function(buffname, unit)
    
    if not unit then unit = "player" end

    local tooltip = Aegis_Tooltip
    local headline = getglobal(tooltip:GetName().."TextLeft1")
    local slot

    -- Buff 
    for slot = 1, 32 do

        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetUnitBuff(unit, slot)
        local text = headline:GetText()
        tooltip:Hide()

        if text and strfind(text, buffname) then
            local _, count = UnitBuff(unit, slot)
            return "buff", slot, text, count
        elseif not text then
            break
        end
    end 

    -- Debuff
    for slot = 1, 32 do

        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetUnitDebuff(unit, slot)
        local text = headline:GetText()
        tooltip:Hide()

        if text and strfind(text, buffname) then
            local _, count, type = UnitDebuff(unit, slot)
            return "debuff", slot, text, count, type
        elseif not text then
            break
        end
    end 

    tooltip:Hide()
end