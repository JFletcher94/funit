
local mock = {}

--- TODO: doc
--- (needed because the mod itself needs to call function)
mock.register_mod = function(mod_name)
    -- TODO: validation
    remote.add_interface("__funit_mock__"..mod_name, {
        get_event_handler = script.get_event_handler
    })
end



return mock