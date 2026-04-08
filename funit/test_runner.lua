
local runner = {}
runner.tests = {}
runner.log_prefix = "__FUNIT__"
runner.test_success = "__SUCCESS__"
runner.test_failure = "__FAILURE__"
runner.test_error = "__ERROR__"

runner.register = function(mod_name)
    runner.mod_name = mod_name
    runner.tests = {}
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

runner.run_and_verify = function(func, message)
    if not func then
        return true
    end

    local status, err = pcall(func)
    if status then
        return true
    end

    if not err then
        runner.fail(message)
    elseif err.is_test_runner_assert then
        runner.fail(message.."__: "..err.message)
    else
        runner.error(message.."__: "..err)
    end
end

runner.run = function()
    runner.assert(runner.mod_name ~= nil, "No mod registered")

    local tests_count = table_size(runner.tests)
    runner.assert(tests_count > 0, "No tests")

    runner.log("====BEGIN "..tostring(tests_count).." TESTS====")

    for name, test in pairs(runner.tests) do
        local status = runner.run_and_verify(runner.before_each_func, name.." (before_each)")
        if not status then
            goto continue
        end

        status = runner.run_and_verify(test, name)
        if not status then
            goto continue
        end

        status = runner.run_and_verify(runner.after_each_func, name.." (after_each)")
        if not status then
            goto continue
        end

        runner.succeed(name)
        ::continue::
    end

    runner.log("====END====")
end

script.on_event(defines.events.on_game_created_from_scenario, runner.run)
return runner