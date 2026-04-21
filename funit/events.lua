
local events = {}

--- TODO: doc
--- (does not respect filter!)
events.mock_event = function(event_data)
    -- TODO: validation
    events._setup_mocks()
    for interface, _ in pairs(events._mocks) do
        local handler = remote.call(interface, "get_event_handler", event_data.name)
        if not handler then
            goto continue
        end

        event_data.tick = event_data.tick or game.tick
        handler(event_data)
        ::continue::
    end
end

events._setup_mocks = function()
    if events._mocks then
        return
    end

    events._mocks = {}
    for interface, _ in pairs(remote.interfaces) do
        if interface:sub(1, 14) == "__funit_mock__" then
            events._mocks[interface] = true
        end
    end
end



return events