local mod = aegis
local me = {}
mod.libitem = me


------------------------------------------------------------------------------
-- Inventory and Item functions
------------------------------------------------------------------------------
me.find = function(item)
    --[[
        Copied from SuperMacro.

        Find an item in your container bags or inventory. 
        If found in inventory, returns slot, nil, texture, count.
        If found in bags, returns bag, slot, texture, total count in all bags.
        Also works with item links. Alt-click on item to insert item link into macro.
        Ex. local bag,slot,texture,count = FindItem("Lesser Magic Essence");

    ]]
    if ( not item ) then return; end
    
    item = string.lower(ItemLinkToName(item))
    
    local link
    
    -- Look for equipments
    for i = 1,23 do
        link = GetInventoryItemLink("player",i)
        if link then
            if item == string.lower(ItemLinkToName(link)) then
                return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i)
            end
        end
    end
    
    -- Look for bags
    local count, bag, slot, texture
    local totalcount = 0
    
    for i = 0, 4 do
        for j = 1, GetContainerNumSlots(i) do
            link = GetContainerItemLink(i, j)
            if link then
                if item == string.lower(ItemLinkToName(link)) then
                    bag, slot = i, j
                    texture, count = GetContainerItemInfo(i, j)
                    totalcount = totalcount + count
                end
            end
        end
    end
    return bag, slot, texture, totalcount
end
    
me.linkToName = function(link)
    -- Copied from SuperMarco.
    if link then
            return gsub(link,"^.*%[(.*)%].*$","%1");
    end
end

me.use = function(item)
    local bag,slot = me.find(item)
    if ( not bag ) then return; end
    if ( slot ) then
        UseContainerItem(bag,slot) -- use, equip item in bag
        return bag, slot
    else
        UseInventoryItem(bag) -- use equipped item
        return bag
    end
end