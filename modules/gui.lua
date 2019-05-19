-- Add the module to the tree
local mod = aegis
local me = {}
mod.gui = me


me.rage = CreateFrame("Frame", "AegisRage", UIParent)
me.rage:SetWidth(80)
me.rage:SetHeight(56)
me.rage:SetPoint("CENTER", 0, 0)
me.rage:SetMovable(true)
me.rage:EnableMouse(true)

me.rage:SetScript("OnMouseDown", function() this:StartMoving() end)
me.rage:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
me.rage:SetScript("OnUpdate", function()
    Aegis_RG_Text:SetText(string.format("怒气: %.1f / 最大%.1f", mod.my.rage.gps, mod.my.rage.gps_max))
    Aegis_HL_Text:SetText(string.format("失血: %.1f / 最大%.1f", mod.my.health.lps, mod.my.health.lps_max))
    Aegis_HG_Text:SetText(string.format("治疗: %.1f / 最大%.1f", mod.my.health.gps, mod.my.health.gps_max))
    Aegis_Prediction_Text:SetText(mod.combat.prediction.text())

end)

-- text
me.rage.text = me.rage:CreateFontString("Aegis_RG_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("TOPLEFT", me.rage, 0, 0)

-- me.rage.text = me.rage:CreateFontString("Aegis_RGRA15_Text", nil, "GameFontNormal")
-- me.rage.text:SetPoint("TOPLEFT", me.rage, 0, 14)

me.rage.text = me.rage:CreateFontString("Aegis_HL_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("TOPLEFT", me.rage, 0, -14)

me.rage.text = me.rage:CreateFontString("Aegis_HG_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("TOPLEFT", me.rage, 0, -28)

me.rage.text = me.rage:CreateFontString("Aegis_Prediction_Text", nil, "GameFontNormal")
me.rage.text:SetPoint("TOPLEFT", me.rage, 0, -42)



