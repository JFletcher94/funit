--- Mock - A utility for mocking events that cannot be easily raised in tests
--- @class Mock
local mock = {}

-- ============================================================================
-- Constants
-- ============================================================================

mock.PREFIX = "__funit_mock_event__"

-- ============================================================================
-- Public API
-- ============================================================================

--- Register a mod to handle mocked events.
--- The mod from the environment this is called in is registered.
--- This allows event handlers to be called in the right environment.
mock.register = function()
    if mock.is_mod_registered(script.mod_name) then
        return
    end
    
    remote.add_interface(mock.PREFIX..script.mod_name, {
        call_event_handler = function(event_data)
            local handler = script.get_event_handler(event_data.name)
            if handler then
                handler(event_data)
            end
        end
    })
end

--- Check if a mod has registered itself.
---
--- @param mod_name string Name of the mod to check
mock.is_mod_registered = function(mod_name)
    return remote.interfaces[mock.PREFIX..tostring(mod_name)] ~= nil
end

--- Mock raising an event with the mods that have registered themselves.
---
--- DOES NOT actually raise an event: only calls (registered) event handlers.
--- DOES NOT respect filters: all registered event handlers will be called.
---
--- @param event_data EventData Mocked event data for the mocked event
mock.mock_event = function(event_data)
    assert(event_data.name and script.get_event_id(event_data.name), "Invalid event_data: "..serpent.block(event_data))
    for name, interfaces in pairs(remote.interfaces) do
        if not name:sub(1, #mock.PREFIX) == mock.PREFIX or not interfaces["call_event_handler"] then
            goto continue
        end

        event_data.tick = event_data.tick or game.tick
        remote.call(name, "call_event_handler", event_data)
        ::continue::
    end
end

return mock