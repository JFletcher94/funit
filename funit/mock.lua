
local mock = {}

--- TODO: doc
--- (needed because the mod itself needs to call function)
mock.register = function()
    if mock.is_mod_registered(script.mod_name) then
        return
    end
    
    mock._mods = mock._mods or {}
    mock._mods[script.mod_name] = true
    remote.add_interface("__funit_mock_event__"..script.mod_name, {
        call_event_handler = function(event_data)
            local handler = script.get_event_handler(event_data.name)
            if handler then
                handler(event_data)
            end
        end
    })
end

--- TODO: doc
mock.is_mod_registered = function(mod_name)
    return mock._mods and mock._mods[mod_name]
end

--- TODO: doc
--- (does not respect filter!)
mock.mock_event = function(event_data)
    assert(event_data.name and script.get_event_id(event_data.name), "Invalid event_data: "..serpent.block(event_data))
    for name, interfaces in pairs(remote.interfaces) do
        if not name:sub(1, 20) == "__funit_mock_event__" or not interfaces["call_event_handler"] then
            goto continue
        end

        event_data.tick = event_data.tick or game.tick
        remote.call(name, "call_event_handler", event_data)
        ::continue::
    end
end

return mock