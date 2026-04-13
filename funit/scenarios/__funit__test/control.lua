 require('__base__/script/freeplay/control.lua')
local runner = require("__funit__.test_runner")

runner.register("funit")
runner.test(
    "Test after_n_ticks_do",
    function()
        local tick = game.tick
        local nesting_level = 0
        runner.after_n_ticks_do(30, function()
            runner.after_n_ticks_do(30, function()
                nesting_level = nesting_level + 1
                runner.assert(nesting_level == 2, "nesting: "..tostring(nesting_level))
                runner.assert(game.tick == tick + 60, "[tick] expected: "..tostring(tick + 30).."; actual: "..tostring(game.tick))
                runner.log(" Fully nested!")
            end)
            nesting_level = nesting_level + 1
            runner.assert(nesting_level == 1, "nesting: "..tostring(nesting_level))
        end)
        runner.assert(nesting_level == 0, "nesting: "..tostring(nesting_level))
    end
)