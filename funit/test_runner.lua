--- FUNIT - A simple test runner for Factorio mods
--- @class FUnit
local runner = {}

-- ============================================================================
-- Constants
-- ============================================================================

runner._log_prefix = "__FUNIT__"
runner._test_success = "__SUCCESS__"
runner._test_failure = "__FAILURE__"
runner._test_error = "__ERROR__"

-- Test stages
runner.BEGIN = 0
runner.BEFORE_EACH = 1
runner.TEST = 2
runner.AFTER_EACH = 3

-- ============================================================================
-- Public API
-- ============================================================================

--- Register a mod for testing. Must be called once before adding tests.
--- @param mod_name string The internal name of the mod (must be active)
runner.register = function(mod_name)
    runner._mod_name = mod_name
    runner._tests = {}
    runner._test_names = {}
    runner.before_each(nil)
    runner.after_each(nil)
    runner.assert(script.active_mods[mod_name] ~= nil, mod_name.." not active")
end

--- Set a function to run before each test.
--- @param func? fun() Function to run before each test (or nil to disable)
runner.before_each = function(func)
    runner.before_each_func = func
end

--- Set a function to run after each test.
--- @param func? fun() Function to run after each test (or nil to disable)
runner.after_each = function(func)
    runner.after_each_func = func
end

--- Register a test function.
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
--- @param ticks integer Must be > 0
--- @param action fun() The function to run after the delay
runner.after_n_ticks_do = function(ticks, action)
    runner.assert(runner._action == nil , "Multiple calls to 'after_n_ticks_do' within one test must be nested!")
    runner.assert(ticks > 0, "ticks must be > 0: "..tostring(ticks))
    runner._resume_on_tick = game.tick + ticks
    runner._action = action
    script.on_event(defines.events.on_tick, runner._resume_test)
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
        log(debug.traceback())
        error({is_test_runner_assert = true, message = message or ""})
    end
end

--- Log a message in the FUnit logging format.
--- @param message string The message to log
runner.log = function(message)
    log(runner._log_prefix..(runner._mod_name or "nil")..message)
end

-- ============================================================================
-- Private / Internal Implementation
-- ============================================================================

--- Log test success message in FUnit logging format.
--- @param message string The success message
runner._succeed = function(message)
    runner.log(runner._test_success..message)
end

--- Log test failure message in FUnit logging format.
--- @param message string The failure message
runner._fail = function(message)
    runner.log(runner._test_failure..message)
end

--- Log test error message in FUnit logging format.
--- @param message string The error message
runner._error = function(message)
    runner.log(runner._test_error..message)
end

--- Safely execute a function and handle success/failure.
--- @param func? fun() Function to execute
--- @param message string Message used when logging failure/error
runner._run_and_verify = function(func, message)
    if not func then
        runner._status = true
        return
    end

    local status, err = pcall(func)
    runner._status = status
    if status then
        return true
    end

    script.on_event(defines.events.on_tick, nil)
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
    runner._run_and_verify(action, runner._test_names[runner._test_idx].." (after_n_ticks_do)")
    runner._run_next_test()
end

--- Main test execution state machine
runner._run_next_test = function()
    local name = runner._test_names[runner._test_idx]
    local test = runner._tests[name]

    if runner._status == false then
        goto continue -- test failure or error
    end
    if runner._action ~= nil then
        return -- waiting for game tick
    end

    if runner._current_stage == runner.BEGIN then
        runner._current_stage = runner.BEFORE_EACH
        runner._run_and_verify(runner.before_each_func, name.." (before_each)")
        if not runner._status then
            goto continue
        end
        if runner._action ~= nil then
            return
        end
    end

    if runner._current_stage == runner.BEFORE_EACH then
        runner._current_stage = runner.TEST
        runner._run_and_verify(test, name)
        if not runner._status then
            goto continue
        end
        if runner._action ~= nil then
            return
        end
    end

    if runner._current_stage == runner.TEST then
        runner._current_stage = runner.AFTER_EACH
        runner._run_and_verify(runner.after_each_func, name.." (after_each)")
        if not runner._status then
            goto continue
        end
        if runner._action ~= nil then
            return
        end
    end

    runner._succeed(name)

    ::continue::
    if runner._test_idx == runner._tests_count then
        runner.log("====END====")
        return
    end

    runner._test_idx = runner._test_idx + 1
    runner._current_stage = runner.BEGIN
    runner._run_next_test()
end

--- Start the test suite. Automatically called on the first tick.
runner._run = function()
    runner.assert(runner._mod_name ~= nil, "No mod registered")
    runner._tests_count = table_size(runner._test_names)
    runner.assert(runner._tests_count > 0, "No tests")
    runner._test_idx = 1
    runner._current_stage = runner.BEGIN
    runner.log("====BEGIN "..tostring(runner._tests_count).." TESTS====")
    runner._run_next_test()
end

script.on_event(defines.events.on_tick, function()
    script.on_event(defines.events.on_tick, nil)
    runner._run()
end)

return runner