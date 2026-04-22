# FUnit

FUnit is a utility mod to help make testing and project automation easier for other Factorio mods. It does nothing on its own.

Examples from my mods:

* [FUnit's own tests](https://gitlab.com/jfletcher94/funit/-/blob/master/funit/scenarios/__funit__test/control.lua)
* [Planet Crucible](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/planet-crucible/scenarios)
* [Rigor Module](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/rigor-module/scenarios)

## FUnit Test Runner

Create a custom scenario, and in the scenario's `control.lua`, and add a `test_runner`. Then register the mod and its tests. All tests will run automatically when a new game is created from the scenario, or when a saved game of the scenario is loaded. Also see [`test_runner.lua`](https://gitlab.com/jfletcher94/funit/-/blob/master/funit/test_runner.lua) for more.

_All code examples in this section are placed in a test scenario's `control.lua`._

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

Sometimes test logic might require letting the game run, and waiting for a certain condition to be met before continuing test logic execution. FUnit includes several functions for this purpose.

#### `after_n_ticks_do`

To wait a fixed number of game ticks then execute some test logic, use `after_n_ticks_do`:

```lua
runner.test(
    "My test",
    function()
        for _, entity in pairs(entities) do
            runner.assert(entity.valid, "Entity invalid!")
            entity.order_deconstruction("player")
        end
        runner.after_n_ticks_do(600, function()
            for _, entity in pairs(entities) do
                runner.assert(not entity.valid, "Entity not deconstructed!")
            end
        end)
    end
)
```

#### `on_event_do`

To wait until an event is raised then execute some test logic, use `on_event_do`:

```lua
runner.test(
    "My test",
    function()
        entity.order_deconstruction("player")
        runner.on_event_do(
            defines.event.on_robot_mined_entity, -- Event
            function(event) -- Continued test logic
                runner.assert(event.robot.name == "my-bot", "Wrong robot!")
            end,
            nil -- (Optional) event filter
            600 -- (Optional) timeout: fail test if event not raised within this many ticks
        )
    end
)
```

#### Chaining Calls

FUnit does not support multiple simultaneous delayed invocations of the same type. Calling `after_n_ticks_do` a second time, while the first is still running, will result in an error; calling `on_event_do` a second time (_for the same event type_) will overwrite the first.

To implement test logic that requires multiple of the same delayed invocation, they need to be chained together (nested):

```lua
runner.test(
    "My test",
    function()
        local tick = game.tick
        runner.after_n_ticks_do(60, function()
            runner.after_n_ticks_do(60, function()
                runner.assert(game.tick == tick + 120)
            end)
            runner.assert(game.tick == tick + 60)
        end)
        runner.assert(game.tick == tick)
    end
)
```

## FUnit Event Mocking

Event handlers can be important to test, but it's not always feasible to get real events to be fired in a contrived testing environment; for example, events that are trigger by player actions (especially in a headless CI environment). To help test event handlers in such cases, FUnit includes a `mock` utility for mocking events.

**NOTE:**

* Mocking an event does not fire an actual event; it is always preferable to use real events when possible.
* Mocked events only trigger event handlers for _mods that have explicitly registered themselves_ (more below).
* Mocked events _do not respect_ event filters.
* FUnit validates that the mocked event's event type exists, but does not validate the event data in any other way.

### Register a Mod

In order for a mod's event handlers to be trigger by FUnit's mocked events, **it must register itself with the event mocker** in its `control.lua`:

_This is in the **mod's** `control.lua`, **not the scenario's**._

```lua
    if script.active_mods["funit"] then -- Make sure FUnit is active
        local mock = require("__funit__.mock")
        mock.register()
    end
```

This is all that's required for a mod to register itself with the event mocker. Each mocked event will now trigger the mod's appropriate event handler. Note that the event mocker retrieves event handlers on the fly, so conditional event handlers are always automatically up-to-date.

### Mock an Event

To mock an event, simply provide the event mocker with event data:

_This is in the scenario's `control.lua`._

```lua
local mock = require("__funit__.mock")

runner.test(
    "My test",
    function()
        mock.mock_event({
            name = defines.event.on_player_died, -- Only field required my event mocker
            player_index = 1 -- Fields besides 'name' can have fake values
        })
    end
)
```

An easy way to get fake event data is to copy it from a real event, e.g. by temporarily adding `log(serpent.block(event))` to an event handler and manually doing whatever in-game action will result in the event being fired. You can then copy the logged event data, with some caveats:

* Remove the `tick` field (if absent, the event mocker populates it with the correct game tick).
* Lua objects (e.g. `LuaEntity`) cannot be copied; if they're needed in the event data, they need to be provided another way (e.g. with `surface.find_entities()`).

## Tips for Using FUnit

[designed for headless CI]

[use remote instead of importing mod's stateful files]