if game.active_mods["funit"] then
    local mock = require("__funit__.mock")
    mock.register_mod("funit")
end

local event_called_count = 0

local get_event_called_count = function()
    return event_called_count
end

remote.add_interface("funit", {
    get_event_called_count = get_event_called_count
})

script.on_event(defines.events.script_raised_built, function()
    event_called_count = event_called_count + 1
end)