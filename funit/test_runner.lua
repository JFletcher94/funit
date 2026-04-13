
local runner = {}
runner.log_prefix = "__FUNIT__"
runner.test_success = "__SUCCESS__"
runner.test_failure = "__FAILURE__"
runner.test_error = "__ERROR__"
-- Test stages
runner.BEGIN = 0
runner.BEFORE_EACH = 1
runner.TEST = 2
runner.AFTER_EACH = 3

runner.register = function(mod_name)
    runner.mod_name = mod_name
    runner.tests = {}
    runner.test_names = {}
    runner.before_each(nil)
    runner.after_each(nil)
    runner.assert(script.active_mods[mod_name] ~= nil, mod_name.." not active")
end

runner.before_each = function(func)
    runner.before_each_func = func
end

runner.after_each = function(func)
    runner.after_each_func = func
end

runner.test = function(name, test)
    runner.tests[name] = test
    table.insert(runner.test_names, name)
end

runner.log = function(message)
    log(runner.log_prefix..(runner.mod_name or "nil")..message)
end

runner.succeed = function(message)
    runner.log(runner.test_success..message)
end

runner.fail = function(message)
    runner.log(runner.test_failure..message)
end

runner.error = function(message)
    runner.log(runner.test_error..message)
end

runner.assert = function(bool, message)
    if bool then
        return true
    else
        log(debug.traceback())
        error({is_test_runner_assert = true, message = message or ""})
    end
end

runner.after_n_ticks_do = function(ticks, action)
    runner.assert(runner.action == nil , "Multiple calls to 'after_n_ticks_do' within one test must be nested!")
    runner.assert(ticks > 0, "ticks must be > 0: "..tostring(ticks))
    runner.resume_on_tick = game.tick + ticks
    runner.action = action
    script.on_event(defines.events.on_tick, runner.resume_test)
end

runner.run_and_verify = function(func, message)
    if not func then
        runner.status = true
        return
    end

    local status, err = pcall(func)
    runner.status = status
    if status then
        return true
    end

    script.on_event(defines.events.on_tick, nil)
    if not err then
        runner.fail(message)
    elseif err.is_test_runner_assert then
        runner.fail(message.."__: "..err.message)
    else
        runner.error(message.."__: "..err)
    end
end

runner.resume_test = function()
    runner.assert(runner.current_stage ~= runner.BEGIN and runner.action ~= nil, "Nothing to resume!")
    if game.tick < runner.resume_on_tick then
        return
    end

    local action = runner.action
    runner.resume_on_tick = nil
    runner.action = nil
    script.on_event(defines.events.on_tick, nil)
    runner.run_and_verify(action, runner.test_names[runner.test_idx].." (after_n_ticks_do)")
    runner.run_next_test()
end

runner.run_next_test = function()
    local name = runner.test_names[runner.test_idx]
    local test = runner.tests[name]

    if runner.status == false then
        goto continue
    end
    if runner.action ~= nil then
        return
    end

    if runner.current_stage == runner.BEGIN then
        runner.current_stage = runner.BEFORE_EACH
        runner.run_and_verify(runner.before_each_func, name.." (before_each)")
        if not runner.status then
            goto continue
        end
        if runner.action ~= nil then
            return
        end
    end

    if runner.current_stage == runner.BEFORE_EACH then
        runner.current_stage = runner.TEST
        runner.run_and_verify(test, name)
        if not runner.status then
            goto continue
        end
        if runner.action ~= nil then
            return
        end
    end

    if runner.current_stage == runner.TEST then
        runner.current_stage = runner.AFTER_EACH
        runner.run_and_verify(runner.after_each_func, name.." (after_each)")
        if not runner.status then
            goto continue
        end
        if runner.action ~= nil then
            return
        end
    end

    runner.succeed(name)

    ::continue::
    if runner.test_idx == runner.tests_count then
        runner.log("====END====")
        return
    end

    runner.test_idx = runner.test_idx + 1
    runner.current_stage = runner.BEGIN
    runner.run_next_test()
end

runner.run = function()
    runner.assert(runner.mod_name ~= nil, "No mod registered")
    runner.tests_count = table_size(runner.test_names)
    runner.assert(runner.tests_count > 0, "No tests")
    runner.test_idx = 1
    runner.current_stage = runner.BEGIN
    runner.log("====BEGIN "..tostring(runner.tests_count).." TESTS====")
    runner.run_next_test()
end

script.on_event(defines.events.on_tick, function()
    script.on_event(defines.events.on_tick, nil)
    runner.run()
end)
return runner