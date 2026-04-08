 require('__base__/script/freeplay/control.lua')
local runner = require("__funit__.test_runner")

runner.register("funit")
runner.test(
    "self-test",
    function()
        runner.assert(true, "runner.assert")
    end
)
