-- Add the module to the tree
local mod = aegis
local me = {}
mod.gui = me


me.rage = CreateFrame("Frame", "AegisRage", UIParent)
me.rage:SetWidth(80)
me.rage:SetHeight(30)
me.rage:SetPoint("CENTER", 0, 0)
me.rage:SetMovable(true)
me.rage:EnableMouse(true)

me.rage:SetScript("OnMouseDown", function() this:StartMoving() end)
me.rage:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
me.rage:SetScript("OnUpdate", function()
    Aegis_RGRA5_Text:SetText(string.format("秒均获得怒气(RA5): %.1f", mod.my.rage.gps_5))
    Aegis_RGRA15_Text:SetText(string.format("秒均获得怒气(RA15): %.1f", mod.my.rage.gps_15))
end)

-- text
me.rage.text = me.rage:CreateFontString("Aegis_RGRA5_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("TOPLEFT", me.rage, 0, 0)

me.rage.text = me.rage:CreateFontString("Aegis_RGRA15_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("BOTTOMLEFT", me.rage, 0, 0)



