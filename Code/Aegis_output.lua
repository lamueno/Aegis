-- Add the module to the tree
local mod = aegis
local me = {}
mod.output = me

me.default = {
    info = false,
    warning = true,
    error = true
}

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

me.debug = function(message, chatframeindex)

    if AegisDB["debug"] then
        me.print(message,chatframeindex)
    end
end