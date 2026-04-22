# FUnit

_Documentation is a work in progress!_

FUnit is a utility mod to help make testing and project automation easier for other Factorio mods. It does nothing on its own.

Examples from my other mods:

* [Planet Crucible](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/planet-crucible/scenarios)
* [Rigor Module](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/rigor-module/scenarios)

## FUnit Test Runner

Create a custom scenario, and in the scenario's `control.lua`, and add a `test_runner`. Then register the mod and its tests. All tests will run automatically when a new game is created from the scenario, or when a saved game of the scenario is loaded.

### Basic Functions

#### `register` and `test`

To use FUnit, you need to `register` a mod; FUnit will validate that this mod is active. You will also need to create at least one `test` to run:

```lua
local runner = require("__funit__.test_runner")
runner.register("my-mod") -- Uses internal mod name

runner.test(
    "My test", -- Test name
    function() -- Test function
        -- Put test logic here
    end
)
```

This is the minimum required for FUnit to run.

#### `before_each` and `after_each`

You can define hooks to run before/after each test:

```lua
local entities = {}

runner.before_each(
    function() -- Set up test entities
        table.insert(entities, game.get_surface(1).create_entity{
            -- name, position, ...
        })
    end
)

runner.after_each(
    function() -- Tear down test entities
        for _, entity in pairs(entities) do
            if entity.valid then entity.destroy() end
        end
        entities = {}
    end
)
```

### Utility Functions

#### `assert`

Tests that complete successfully will be reported as `SUCCESS`. Tests that fail will be reported as `FAILED`. Tests that raise an error will be reported as `ERROR`.

You can use Lua's built-in `assert` in FUnit tests, but they will be reported as `ERROR` instead of `FAILED`. For failures to be reported properly, use FUnit's `assert` instead:

```lua
runner.test(
    "My test",
    function()
        local surface = game.get_surface(1)
        runner.assert(surface, "Surface 1 not found!") -- Optionally include a message to be logged if assertion fails
    end
)
```

#### `log`

FUnit uses a specific logging format; use FUnit's `log` function to print a message in this format. Messages are logged both to the in-game console and to Factorio's log (i.e., stdout/factorio-current.log):

```lua
    runner.test(
        "My test",
        function()
            local surface = game.get_surface(1)
            runner.assert(surface, "Surface 1 not found!")
            runner.log("Using surface: "..surface.name)
        end
    )
```

### Advanced Functions

#### `after_n_ticks_do`

