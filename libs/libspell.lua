
local mod = aegis
local me = {}
mod.libspell = me

--[[
Given a spell name, SpellReadyIn returns the cooldown time left for it.
If the spell name does not exist in spellbook 
]] 
me.SpellReadyIn = function(name)
    
    local spellid = mod.my.reversespellbook[name]
    if not spellid then
        mod.output.trace("error", me, "SpellReadyIn", string.format("invalid name %s passed", tostring(name)))
        return nil
    end 

    -- GCD also affects the result of `GetSpellCooldown`
    local start, duration = GetSpellCooldown(spellid, BOOKTYPE_SPELL)
    local cd
    if duration == 0 then
        cd = 0
    else
        cd = start + duration - GetTime()
    end
    return cd
end

me.SpellCanCast = function(name, forcedance)

    if not forcedance then 
        forcedance = false
    end
    
    local local_name = mod.string.get("spell", name)

    -- Spellbook check
    if not mod.my.reversespellbook[name] then
        mod.output.trace("warning", me, "SpellReadyIn", string.format("%s has not learnt.", tostring(local_name)))
        return false
    end

    -- Settings check
    if mod.db.settings.disabledspell[name] == true then
        mod.output.trace("warning", me, "SpellReadyIn", string.format("%s is disabled.", tostring(local_name)))
        return false
    end

    -- Meta Check
    local meta = mod.db.spell[name]
    
    if meta then
        -- Cost
        if meta.cost then
            if mod.my.rage < meta.cost then
                mod.output.trace("warning", me, "SpellReadyIn", string.format("Not enough rage to cast %s.", tostring(local_name)))
                return false
            end
        end
    
        -- Distance
        if meta.distance then
            if mod.my.distance() < meta.distance.min or mod.my.distance() > meta.distance.max then
                mod.output.trace("warning", me, "SpellReadyIn", string.format("Out of range to cast %s, your distance is %s", tostring(local_name), mod.my.distance()))
                return false
            end
        end
    
        -- Stance
        if meta.stance then
            if not (meta.stance[mod.my.activestance()] or mod.my.dansable() or forcedance) then
                mod.output.trace("warning", me, "SpellReadyIn", string.format("In wrong stance to cast %s.", tostring(local_name)))
                return false
            end 
        end
    
        -- Shielded
        if meta.shielded then
            if not mod.my.shielded() then
                mod.output.trace("warning", me, "SpellReadyIn", string.format("Shield is needed for %s.", tostring(local_name)))
                return false
            end
        end
    
        -- Weaponed
        if meta.weaponed then
            if not mod.my.weaponed() then
                mod.output.trace("warning", me, "SpellReadyIn", string.format("Weapon is needed for %s.", tostring(local_name)))
                return false
            end
        end    
    
    else 
        mod.output.trace("error", me, "spell", string.format("No spell meta for %s.", name))
        return false
    end

    return true
end