--- FUNIT - A simple test runner for Factorio mods
--- @class FUnit
local runner = {}

-- ============================================================================
-- Constants
-- ============================================================================

runner._log_prefix = "__FUNIT__"
runner._test_success = "SUCCESS__"
runner._test_failure = "FAILURE__"
runner._test_error = "ERROR__"

-- Test stages
runner.BEGIN = 0
runner.BEFORE_EACH = 1
runner.TEST = 2
runner.AFTER_EACH = 3

-- ============================================================================
-- Public API
-- ============================================================================

--- Register a mod for testing. Must be called once before adding tests.
---
--- @param mod_name string The internal name of the mod (must be active)
--- @param testsuite_name string? The name of the testsuite, only used for test report
runner.register = function(mod_name, testsuite_name)
    runner._mod_name = mod_name
    runner._testsuite_name = testsuite_name or mod_name
    runner._tests = {}
    runner._test_names = {}
    runner._status = {}
    runner._registered_events = {}
    runner.before_each(nil)
    runner.after_each(nil)
    runner.assert(script.active_mods[mod_name] ~= nil, mod_name.." not active")
end

--- Set a function to run before each test.
---
--- @param func? fun() Function to run before each test (or nil to disable)
runner.before_each = function(func)
    runner.before_each_func = func
end

--- Set a function to run after each test.
---
--- @param func? fun() Function to run after each test (or nil to disable)
runner.after_each = function(func)
    runner.after_each_func = func
end

--- Register a test function.
---
--- @param name string Unique name for the test
--- @param test fun() The test function to execute
runner.test = function(name, test)
    runner._tests[name] = test
    table.insert(runner._test_names, name)
end

--- Schedule an action to run after a certain number of ticks.
--- Can be called from inside a test or before/after hooks.
--- To chain actions together, nest calls of this function.
--- Only one non-nested call is allowed per test stage.
---
--- @param ticks integer The number of ticks to wait; must be > 0
--- @param action fun() The function to run after the delay
runner.after_n_ticks_do = function(ticks, action)
    runner.assert(runner._action == nil , "Multiple calls to 'after_n_ticks_do' within one test must be nested!")
    runner.assert(ticks > 0, "ticks must be > 0: "..tostring(ticks))
    runner._resume_on_tick = game.tick + ticks
    runner._action = action
    script.on_event(defines.events.on_tick, runner._resume_test)
end

--- Perform an action upon an event being raised.
--- Can be called from inside a test or before/after hooks.
--- To chain actions together, nest calls of this function.
--- Non-nested invocations will overwrite each other.
---
--- @param event LuaEventType The event to invoke the handler on
--- @param action fun() The handler for the event
--- @param filters EventFilter? The filters for this event
--- @param timeout_ticks integer? Fail the test if event is not fired after this many ticks; must be > 0
runner.on_event_do = function(event, action, filters, timeout_ticks)
    runner.assert(event, "Cannot use on_event_do to unregister event handler")
    local event_id = script.get_event_id(event)
    runner.assert(event_id ~= defines.events.on_tick, "Cannot use 'defines.events.on_tick'; use after_n_ticks_do instead")
    runner.assert(not timeout_ticks or timeout_ticks > 0, "timeout_ticks must be > 0: "..tostring(timeout_ticks))
    runner._registered_events[event_id] = (timeout_ticks and game.tick + timeout_ticks) or 0 -- 0 means never timeout
    script.on_event(event, function()
        runner._registered_events[event_id] = nil
        script.on_event(event, nil)
        runner._run_and_verify(action(event), runner._test_names[runner._test_idx].." ("..event_id..")")
    end, filters)
end

--- TODO
---
--- @param timeout_ticks integer? Fail the test if condition not met after this many ticks; must be > 0
runner.after_condition_met_do = function(predicate, timeout_ticks)
    assert(false, "Not yet implemented!")
end

--- Assertion function for use inside tests and hooks.
--- If the condition is false, the test fails immediately with the given message.
---
--- This is the recommended way to write checks inside your tests.
---
--- @param bool boolean Condition that must be true
--- @param message? string Optional failure message
runner.assert = function(bool, message)
    if bool then
        return true
    else
        local traceback = debug.traceback("FUnit assertion failed: "..tostring(message), 2)
        error({is_test_runner_assert = true, message = tostring(message), traceback = traceback})
    end
end

--- Log a message in the FUnit logging format.
---
--- @param message string The message to log
runner.log = function(message)
    if runner._logs then
        table.insert(runner._logs, message)
    end
    game.print({"mod-message.funit-log", message}, {game_state = false})
    log(runner._log_prefix..(runner._mod_name or "nil").."__"..message)
end

-- ============================================================================
-- Private / Internal Implementation
-- ============================================================================

--- Record and log test success.
---
--- @param message string The success message
runner._succeed = function(message)
    if runner._testsuite then
        local testcase = {
            name = runner._test_names[runner._test_idx],
            classname = runner._mod_name,
            time = 0.0 -- TODO
        }
        table.insert(runner._testsuite.testcases, testcase)
    end

    runner.log(runner._test_success..message)
end

--- Record and log test failure.
---
--- @param message string The failure message
runner._fail = function(message)
    if runner._testsuite then
        runner._testsuite.failures = runner._testsuite.failures + 1
        local testcase = {
            name = runner._test_names[runner._test_idx],
            classname = runner._mod_name,
            time = 0.0, -- TODO
            failure = {
                message = message,
                type = "AssertionError"
            }
        }
        if #runner._logs == 1 then
            testcase.failure.content = runner._logs[1]
        elseif #runner._logs > 1 then
            local logs = runner._logs[1]
            for i = 2,#runner._logs do
                logs = logs.."\n"..runner._logs[i]
            end
            testcase.failure.content = logs
        end
        table.insert(runner._testsuite.testcases, testcase)
    end

    runner.log(runner._test_failure..message)
end

--- Record and log test error.
---
--- @param message string The error message
runner._error = function(message)
    if runner._testsuite then
        runner._testsuite.errors = runner._testsuite.errors + 1
        local testcase = {
            name = runner._test_names[runner._test_idx],
            classname = runner._mod_name,
            time = 0.0, -- TODO
            error = {
                message = message,
                type = "RuntimeError"
            }
        }
        if #runner._logs == 1 then
            testcase.error.content = runner._logs[1]
        elseif #runner._logs > 1 then
            local logs = runner._logs[1]
            for i = 2,#runner._logs do
                logs = logs.."\n"..runner._logs[i]
            end
            testcase.error.content = logs
        end
        table.insert(runner._testsuite.testcases, testcase)
    end

    runner.log(runner._test_error..message)
end

--- Timeout handler for `on_event_do`
runner._check_for_timeout = function()
    for event_id, timeout_tick in pairs(runner._registered_events) do
        if timeout_tick ~= 0 and timeout_tick < game.tick then
            runner._run_and_verify(function()
                runner.assert(false, "Timeout reached waiting for event "..tostring(event_id))
            end,runner._test_names[runner._test_idx])
            runner._run_next_test()
            return
        end
    end
end

--- Safely execute a function and handle success/failure.
---
--- @param func? fun() Function to execute
--- @param message string Message used when logging failure/error
runner._run_and_verify = function(func, message)
    if runner._status[runner._test_idx] == false then
        return false
    end

    if not func then
        runner._status[runner._test_idx] = true
        return true
    end

    local status, err = xpcall(func, function(error)
        log(debug.traceback())
        return error
    end)
    -- If a nested call fails, status will still be true but runner._status[runner._test_idx] will be false
    if runner._status[runner._test_idx] == false then
        return false
    end

    runner._status[runner._test_idx] = status
    if status then
        return true
    end

    script.on_event(defines.events.on_tick, nil)
    for event_id, _ in pairs(runner._registered_events) do
        script.on_event(event_id, nil)
    end
    runner._registered_events = {}
    if not err then
        runner._fail(message)
    elseif err.is_test_runner_assert then
        runner._fail(message.."__: "..err.message)
    else
        runner._error(message.."__: "..err)
    end
end

--- Handler for `after_n_ticks_do`
runner._resume_test = function()
    runner.assert(runner._current_stage ~= runner.BEGIN and runner._action ~= nil, "Nothing to resume!")
    if game.tick < runner._resume_on_tick then
        return
    end

    local action = runner._action
    runner._resume_on_tick = nil
    runner._action = nil
    script.on_event(defines.events.on_tick, nil)
    runner._run_and_verify(action, runner._test_names[runner._test_idx])
    runner._run_next_test()
end

--- Main test execution state machine
runner._run_next_test = function()
    local name = runner._test_names[runner._test_idx]
    local test = runner._tests[name]

    if runner._status[runner._test_idx] == false then
        goto continue -- test failure or error
    end
    if runner._action ~= nil or table_size(runner._registered_events) > 0 then
        return -- waiting for game tick or event
    end

    if runner._current_stage == runner.BEGIN then
        runner._current_stage = runner.BEFORE_EACH
        runner._run_and_verify(runner.before_each_func, name.." (before_each)")
        if not runner._status[runner._test_idx] then
            goto continue
        end
        if runner._action ~= nil or table_size(runner._registered_events) > 0 then
            return
        end
    end

    if runner._current_stage == runner.BEFORE_EACH then
        runner._current_stage = runner.TEST
        runner._run_and_verify(test, name)
        if not runner._status[runner._test_idx] then
            goto continue
        end
        if runner._action ~= nil or table_size(runner._registered_events) > 0 then
            return
        end
    end

    if runner._current_stage == runner.TEST then
        runner._current_stage = runner.AFTER_EACH
        runner._run_and_verify(runner.after_each_func, name.." (after_each)")
        if not runner._status[runner._test_idx] then
            goto continue
        end
        if runner._action ~= nil or table_size(runner._registered_events) > 0 then
            return
        end
    end

    runner._succeed(name)

    ::continue::
    script.on_event(defines.events.on_tick, nil)
    for event_id, _ in pairs(runner._registered_events) do
        script.on_event(event_id, nil)
    end
    if runner._test_idx == runner._tests_count then
        helpers.write_file(
            "funit-report-"..runner._testsuite_name..".json",
            helpers.table_to_json(runner._testsuite)
        )
        log("funit-report-"..runner._testsuite_name..".json")
        log(helpers.table_to_json(runner._testsuite)) -- TODO: TEMP
        script.on_nth_tick(1, nil)
        runner.log("====END====")
        return
    end

    runner._action = nil
    runner._registered_events = {}
    runner._test_idx = runner._test_idx + 1
    runner._current_stage = runner.BEGIN
    runner._logs = {}
    runner._run_next_test()
end

--- Start the test suite. Automatically called on the first tick.
runner._run = function()
    runner.assert(runner._mod_name ~= nil, "No mod registered")
    runner._tests_count = table_size(runner._test_names)
    runner.assert(runner._tests_count > 0, "No tests")
    runner._test_idx = 1
    runner._current_stage = runner.BEGIN
    script.on_nth_tick(1, runner._check_for_timeout)
    runner.log("====BEGIN "..tostring(runner._tests_count).." TESTS====")
    runner._testsuite = {
        name = runner._testsuite_name,
        tests = runner._tests_count,
        failures = 0,
        errors = 0,
        skipped = 0,
        testcases = {}
    }
    runner._logs = {}
    runner._run_next_test()
end

script.on_event(defines.events.on_tick, function()
    script.on_event(defines.events.on_tick, nil)
    runner._run()
end)

return runner