
local runner = {}
runner.tests = {}
runner.test_success = "__SUCCESS__"
runner.test_failure = "__FAILURE__"
runner.test_error = "__ERROR__"

runner.register = function(mod_name)
    runner.log_prefix = "__FUNIT__"..mod_name
    if not script.active_mods[mod_name] then
        runner.error(mod_name.." not active")
    end

    runner.tests = {}
    runner.before_each(nil)
    runner.after_each(nil)
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

runner.succeed = function(message)
    log(runner.log_prefix..runner.test_success..message)
end

runner.fail = function(message)
    log(runner.log_prefix..runner.test_failure..message)
end

runner.error = function(message)
    log(runner.log_prefix..runner.test_error..message)
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
    if not runner.log_prefix then
        runner.log_prefix = "__FUNIT__nil"
        runner.error("No mod registered")
        runner.log_prefix = nil
        return
    end

    local tests_count = table_size(runner.tests)
    if tests_count == 0 then
        runner.error("No tests")
        return
    end

    log(runner.log_prefix.."====BEGIN "..tostring(tests_count).." TESTS====")

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

    log(runner.log_prefix.."====END====")
end

script.on_event(defines.events.on_game_created_from_scenario, runner.run)
return runner