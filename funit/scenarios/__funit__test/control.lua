 require('__base__/script/freeplay/control.lua')
local runner = require("__funit__.test_runner")
runner.register("funit", "funit-test-scenario")

local mock = require("__funit__.mock")

runner.test("Test after_n_ticks_do", function()
    local tick = game.tick
    local nesting_level = 0
    runner.after_n_ticks_do(30, function()
        runner.after_n_ticks_do(30, function()
            nesting_level = nesting_level + 1
            runner.assert(nesting_level == 2, "nesting: "..tostring(nesting_level))
            runner.assert(game.tick == tick + 60, "[tick] expected: "..tostring(tick + 30).."; actual: "..tostring(game.tick))
            runner.log("Fully nested!")
        end)
        nesting_level = nesting_level + 1
        runner.assert(nesting_level == 1, "nesting: "..tostring(nesting_level))
    end)
    runner.assert(nesting_level == 0, "nesting: "..tostring(nesting_level))
end)

runner.test("Test on_event_do", function()
    local surface
    for _, s in pairs(game.surfaces) do
        surface = s
        break
    end
    runner.assert(surface, "No surface found")
    local entity0 = nil
    local entity1 = nil
    for _, entity in pairs(surface.find_entities()) do
        if entity.name_tag == "entity_0" then
            entity0 = entity
        elseif entity.name_tag == "entity_1" then
            entity1 = entity
        end
    end
    runner.assert(entity0 and entity0.valid, "Entity named 'entity_0' not found")
    runner.assert(entity1 and entity1.valid, "Entity named 'entity_1' not found")

    local nesting_level = 0
    runner.on_event_do(defines.events.script_raised_destroy, function()
        runner.on_event_do(defines.events.script_raised_destroy, function()
            nesting_level = nesting_level + 1
            runner.assert(nesting_level == 2, "nesting: "..tostring(nesting_level))
            runner.log("Fully nested!")
        end, nil, 60)
        nesting_level = nesting_level + 1
        runner.assert(nesting_level == 1, "nesting: "..tostring(nesting_level))
        entity1.destroy{raise_destroy = true}
    end, nil, 60)
    runner.assert(nesting_level == 0, "nesting: "..tostring(nesting_level))
    entity0.destroy{raise_destroy = true}
end)

runner.test("Test after_n_ticks_on_event_do", function()
    local surface
    for _, s in pairs(game.surfaces) do
        surface = s
        break
    end
    runner.assert(surface, "No surface found")
    local entity0 = nil
    local entity1 = nil
    for _, entity in pairs(surface.find_entities()) do
        if entity.name_tag == "entity_2" then
            entity0 = entity
        elseif entity.name_tag == "entity_3" then
            entity1 = entity
        end
    end
    runner.assert(entity0 and entity0.valid, "Entity named 'entity_2' not found")
    runner.assert(entity1 and entity1.valid, "Entity named 'entity_3' not found")

    local nesting_level = 0
    runner.after_n_ticks_do(30, function()
        runner.on_event_do(defines.events.script_raised_destroy, function()
            runner.after_n_ticks_do(30, function()
                runner.on_event_do(defines.events.script_raised_destroy, function()
                    nesting_level = nesting_level + 1
                    runner.assert(nesting_level == 4, "nesting: "..tostring(nesting_level))
                    runner.log("Fully nested!")
                end, nil, 120)
                nesting_level = nesting_level + 1
                runner.assert(nesting_level == 3, "nesting: "..tostring(nesting_level))
                entity0.destroy{raise_destroy = true}
            end)
            nesting_level = nesting_level + 1
            runner.assert(nesting_level == 2, "nesting: "..tostring(nesting_level))
        end, nil, 120)
        nesting_level = nesting_level + 1
        runner.assert(nesting_level == 1, "nesting: "..tostring(nesting_level))
        entity1.destroy{raise_destroy = true}
    end)
    runner.assert(nesting_level == 0, "nesting: "..tostring(nesting_level))
end)

runner.test("Test mock_event", function()
    runner.assert(mock.is_mod_registered("funit"), "funit not registered with mock!")
    local event_called_count_0 = remote.call("funit", "get_event_called_count")
    mock.mock_event({ name = defines.events.script_raised_built })
    local event_called_count_1 = remote.call("funit", "get_event_called_count")
    runner.assert(event_called_count_1 == event_called_count_0 + 1, tostring(event_called_count_0).." ~= "..tostring(event_called_count_1))
end)