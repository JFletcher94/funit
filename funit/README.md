## FUnit

_Documentation is a work in progress!_

FUnit is a utility mod to help make testing and project automation easier for other Factorio mods. It does nothing on its own.

### How to Use [`test_runner.lua`](test_runner.lua)

Create a custom scenario, and in the custom scenario's `control.lua`, add a `test_runner`, register your mod, and add tests:

```lua
local runner = require("__funit__.test_runner")
runner.register("my-mod") -- FUnit will validate that this mod is active

runner.test(
    "my_test", -- Test name
    function() -- Test function
        runner.assert(true, "message") -- A failed assertion will fail the test
    end
)
```

All registered tests will run automatically when a new game is created from the scenario.

Examples from my other mods:

* [Planet Crucible](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/planet-crucible/scenarios)
* [Rigor Module](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/rigor-module/scenarios)

#### WIP Features

* Support for delayed invocation (e.g. waiting for N ticks, or for an event, during a test)
* Better stack traces
