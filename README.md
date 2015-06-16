# promise.lua

[![Circle CI](https://img.shields.io/circleci/project/Billiam/promise.lua.svg)](https://circleci.com/gh/Billiam/promise.lua/tree/master)
[![Coverage Status](https://img.shields.io/coveralls/Billiam/promise.lua.svg)](https://coveralls.io/r/Billiam/promise.lua)

## Documentation

_Soon_

## Differences from the Promises/A+ Spec

* [1.2](https://promisesaplus.com/#point-7) `then` is a reserved word in Lua. `next` is used instead in this library.
* [1.3](https://promisesaplus.com/#point-8) Valid value types
  * Promises cannot be resolved with null (`nil`). Lua does not distinguish between 
```lua
function()
    return nil
end
```
  and
```lua
function()
    return
end
```
  * Lua does not have an `undefined` type.
* [2.2.5](https://promisesaplus.com/#point-35) Lua method calls do not have a `this` equivalent. The `self` syntactic sugar for `self` is determined my method arguments.
* [2.3.1](https://promisesaplus.com/#point-48) Lua does not have an error type. Specifications calling for `TypeError` will receive a string message beginning with `TypeError:`

### Related projects:

* [promise](https://github.com/Olivine-Labs/promise)
* [lua_promise](https://github.com/friesencr/lua_promise)
* [AndThen](https://github.com/ppissanetzky/AndThen)
* [lua-promise](https://github.com/dmccuskey/lua-promise)
* [next.lua](https://github.com/pmachowski/next-lua)

Not seeing a library here? Send a pull request!