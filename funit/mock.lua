
local mock = {}

--- TODO: doc
--- (needed because the mod itself needs to call function)
mock.register_mod = function(mod_name)
    -- TODO: validation
    remote.add_interface("__funit_mock__"..mod_name, {
        call_event_handler = function(event_data)
            local handler = script.get_event_handler(event_data.name)
            if handler then
                handler(event_data)
            end
        end
    })
end



return mock