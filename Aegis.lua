--[[
Managing your Variables / Methods

--> Initialise static data anywhere in your code file
--> Initialise variables that depend on other module's static data in your onload() method
--> Initialise variables that depend on other module's variables in your onloadcomplete() method
]]--

-- initialize table
aegis = {}
local me = aegis
me.frame = nil  -- set at runtime


-- Addon Version
me.release = 0
me.revision = 0
me.build = 5

me.events = {}
me.isloaded = false
me.isenabled = true

-- onload
me.onload = function()

    --  find frame
    me.frame = AegisFrame

    --  initialize all submodules
    for key, subtable in me do
        if type(subtable) == "table" and subtable.onload and subtable.isenabled ~= "false" and subtable.isloaded ~= true then
            subtable.onload()
        end
    end

    me.isloaded = true

    -- register events. Strictly after all modules have been loaded.
    for key, subtable in me do
        if type(subtable) == "table" and subtable.myevents then
            
            me.events[key] = {}

            for _, event in subtable.myevents do
                me.frame:RegisterEvent(event)
                me.events[key][event] = true
            end
        end
    end

    -- onloadcomplete
    for key, subtable in me do
        if type(subtable) == "table" and subtable.onloadcomplete and subtable.isenabled ~= "false" then
            subtable.onloadcomplete()
        end
    end

end

-- onupdate
me.onupdate = function()

	-- only call when everything has been loaded
	if me.isloaded ~= true then
		return
	end
	
	-- don't call if the entire addon is disabled
	if me.isenabled == false then
		return
	end
	
	for key, subtable in me do
		if type(subtable) == "table" and subtable.onupdate and subtable.isenabled ~= "false" then
            subtable.onupdate()
            me.diag.logmethodcall(key, "onupdate")
		end
	end
end

-- onevent
me.onevent = function()

    -- don't call if the entire addon is disabled
    if me.isenabled == false then
        return
    end

    for key, subtable in me do
        -- 1) The subtable is a valid module - is a table and has a .onevent property.
		-- 2) The subtable is not disabled
		-- 3) The subtable has registered the event
		if type(subtable) == "table" and subtable.onevent and subtable.isenabled ~= "false" and me.events[key][event] then
            me.diag.logmethodcall(key, "onevent")
            -- subtable.onevent()
		end
    end

end

