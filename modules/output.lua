-- Add the module to the tree
local mod = aegis
local me = {}
mod.output = me


me.onload = function()

	-- optional debug specification
	
	me.setprintstatus("boss", nil, "info", true)
	me.setprintstatus("boss", "target", "info", false)
	me.setprintstatus("netin", "message", "info", true)

end
--[[
--------------------------------------------------------------------------
-- Trace Printing for Debugging or Extra Information
--------------------------------------------------------------------------

	The idea of this section is to provide a detailed method to evaluate whether a specific trace message should be printed. We have a few data structures that are print options of the form "if the print is <x>, do / dont print it".
	The more specific a print option is, the higher the priority it has. So the defaults, which just say "always print on <error>" or "never print on <info>" are the least specific and will be overridden by <me.setprintstatus>.
	For a release version, it is sufficient to set "error" = true, and the rest = "false", but for a debug version, you might only want to focus on specific sections of code for trace prints.

]]

-- These are default printing options. For a release version, error only. For a debug version, maybe warnings too.
me.default = 
{
	info = true,
	warning = true,
	error = true,
}


--[[  
Suppose the following method calls were made:
	me.setprintstatus("boss", nil, "warning", true)
	me.setprintstatus("boss", "event", "info", true)
	
Then me.override would look like
me.override = 
{
	boss = 
	{
		warning = true
		error = true
		sections = 
		{
			event = 
			{
				info = true
				warning = true
				error = true
			}
		}
	}
}

See <me.setprintstatus> for more information
]]
me.override = { }

--[[
me.setprintstatus(modulename, sectionname, messagetype, value)

Overrides the default print option for a specific trace print.
<modulename> is a string, the source of the print, e.g. "out" for this module.
<sectionname> is a string, a feature in the source module. e.g. "trace" for this section.
<messagetype> is either "info" or "warning" or "error".
<value> is a boolean, true to enable the print, false to disable it.

<sectionname> is an optional parameter. If it is nil, the override will apply to the whole module, but it is now less specific, so an individual section inside that module may be overriden again.
<messagetype> will automatically cascade. "error" is assumed to be more important than "warning", which is more important than "info". So if you turn "warning" off, it will turn "info off as well"; if you turn "info" on, "warning" and "error" will be turned on too.
]]
me.setprintstatus = function(modulename, sectionname, messagetype, value)

    -- Initialize module tree in override table
    if me.override[modulename] == nil then
        me.override[modulename] = {}
    end

    local printdata = me.override[modulename]

    -- check for sectionname
    if sectionname then
    
        -- Initialize section tree in override table
        if printdata.sections == nil then
            printdata.sections = {}
        end

        printdata = printdata.sections

        -- check whether this section has been defined in the sections list
        if printdata[sectionname] == nil then
            printdata[sectionname] = {}
        end

        printdata = printdata[sectionname]
    end

    -- set
    printdata[messagetype] = value

	-- cascade
	if value == true then
		if messagetype == "info" then
			printdata.warning = true
			messagetype = "warning"
		end
		
		if messagetype == "warning" then
			printdata.error = true
		end
	
	elseif value == false then
		if messagetype == "error" then
			printdata.warning = false
			messagetype = "warning"
		end
		
		if messagetype == "warning" then
			printdata.info = false
		end
	end

end


--[[
This is a reverse lookup of the top level of the list <mod>. <mod> has keys that are strings like "out", and values that are modules (lists), like <me>. <me.modulelookup> reverses this, giving us the name of a module from a reference to it.
Calls to <me.checktrace> supply a module reference and we might like to name the module. However we wouldn't want to search for the module name every time that method is called, since we want it in particular to be fast. 
We don't fill me.modulelookup at runtime, but each time <me.checktrace> is called with a <module> parameter that is not a key to <me.modulelookup>, we will search to find that module.
]]
me.modulelookup = { }

--[[
me.getmodulename(module)
Given a reference to a module (subtree of <local mod>), returns the name, which is the key in <mod> of the module.
]]
me.getmodulename = function(module)
	
	-- have we already found this module before?
	local try = me.modulelookup[module]
	if try then
		return try
	end
	
	-- manual search
	local key, value
	
	for key, value in mod do
		if value == module then
			me.modulelookup[module] = key
			return key
		end
	end
	
	return "unknown"
	
end


me.trace = function(messagetype, module, sectionname, message)
    if me.checktrace(messagetype,module,sectionname) then
        me.printtrace(message)
    end
end

me.tracespellcast = function(spellname, dance)
    local messagetype = "info"
    local module = mod.combat
    local sectionname = "cast"
    local message = string.format("[%s] ", mod.my.rage)

    if dance then
        message = message .. string.format("%s ==> %s", mod.string.get("spell", dance), mod.string.get("spell", spellname))
    else
        message = message .. mod.string.get("spell", spellname)
    end
end

--[[ 
mod.out.checktrace(messagetype, module, sectionname)
Checks whether a debug print with the given properties should be printed.
Return: non-nil iff the message should be printed.
<messagetype> must be one of "error", "warning" or "info"
<module> should always be <me> in the calling context
<sectionname> is a description of the feature in <module> that the message concerns.
]]
--! This variable is referenced by these modules: boss, combat, combatparser, diag, my, netin, regex, table, gui, guiopt, guiraid, guiself, guititle, string, 
me.checktrace = function(messagetype, module, sectionname)
	
	-- start with default print value
	local value = me.default[messagetype]
	me.printargs.overridelevel = "default"
	
	-- convert module reference to name
	local modulename = me.getmodulename(module)
	
	-- are there any overrides for that module?
	local printdata = me.override[modulename]
	
	if printdata then
		if printdata[messagetype] then
			value = printdata[messagetype]
			me.printargs.overridelevel = "module"
		end
		
		-- are there overrides for this section of the module?		
		if printdata.sections and printdata.sections[sectionname] and (printdata.sections[sectionname][messagetype] ~= nil) then
			value = printdata.sections[sectionname][messagetype]
			me.printargs.overridelevel = "section"
		end
	end
	
	-- pre-return: load arguments for me.printtrace
	me.printargs.modulename = modulename
	me.printargs.sectionname = sectionname
	me.printargs.messagetype = messagetype
	
	-- return: nil or non-nil
	if value == true then
		return true
	end
	
end

-- This stores the options supplied to <me.checktrace>, which will slightly affect the printout.
me.printargs = 
{
	messagetype = "",
	modulename = "",
	sectionname = "",
	overridelevel = "",
}

--[[
mod.out.printtrace(message)
Prints a message that has been OK'd by <me.checktrace>.
]]
--! This variable is referenced by these modules: boss, combat, combatparser, diag, my, netin, regex, table, gui, guiopt, guiraid, guiself, guititle, string, 
me.printtrace = function(message)

	-- setup the colour. Error = red, warning = yellow, info = blue. Lightish colours.
	local header = ""
	
	if me.printargs.messagetype == "info" then
		header = "|cff8888ff"
	
	elseif me.printargs.messagetype == "warning" then
		header = "|cffffff44"
	
	elseif me.printargs.messagetype == "error" then
		header = "|cffff8888"
	end
	
	header = header .. "<" .. me.printargs.modulename .. "." .. me.printargs.sectionname .. "> "
	
	-- print!
	me.print(header .. message)
	
end


--[[ 
----------------------------------------------------------------------
			Normal Printing to the Console
----------------------------------------------------------------------
]]

--[[ 
mod.out.print(message, [chatframeindex, noheader])
Prints out <message> to chat.
To print to ChatFrame3, set <chatframeindex> to 3, etc.
Adds a header "KTM: " to the message, unless <noheader> is non-nil.
]]
--! This variable is referenced by these modules: alert, boss, console, data, diag, my, net, netin, regex, guititle, string, 
me.print = function(message, chatframeindex)

    -- Get a Frame to write to 
    local chatframe

    if chatframeindex == nil then
        chatframe = DEFAULT_CHAT_FRAME
    else
        chatframe = getglobal("ChatFrame" .. chatframeindex)

        if chatframe == nil then
            chatframe = DEFAULT_CHAT_FRAME
        end
    end

    -- touch up message
    message = message or "<nil>"
    message = "Aegis: " .. message

    -- write
    chatframe:AddMessage(message)

end

--[[
mod.out.booltostring(boolean)
Converts a Boolean value (true or false) to a string representation.
true -> "true", false -> "false", nil -> "nil"
]]
--! This variable is referenced by these modules: console, my, 
me.booltostring = function(boolean)
	
	if boolean == true then
		return "true"
	elseif boolean == false then
		return "false"
	else
		return "nil"
	end
	
end

--[[ 
mod.out.announce(message)
Sends a chat message to Raid if possible, or Party if possible, or finally Say.
]]
--! This variable is referenced by these modules: alert, 
me.announce = function(message)
		
	local channel = "SAY"

	if GetNumRaidMembers() > 0 then
		channel = "RAID"

	elseif GetNumPartyMembers() > 0 then
		channel = "PARTY"
	end

	SendChatMessage(message, channel)

end