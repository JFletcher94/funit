 require('__base__/script/freeplay/control.lua')
local runner = require("__funit__.test_runner")

runner.register("funit")
runner.test(
    "Self-test",
    function()
        runner.assert(true, "runner.assert")
    end
)
runner.test(
    "Test after_n_ticks_do",
    function()
        local tick = game.tick
        runner.after_n_ticks_do(30, function()
            runner.assert(game.tick == tick + 30, "[tick] expected: "..tostring(tick + 30).."; actual: "..tostring(game.tick))
        end)
    end
)
