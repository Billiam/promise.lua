-- Port of https://github.com/rhysbrettbowen/promise_impl/blob/master/promise.js
-- and https://github.com/rhysbrettbowen/Aplus
--
local queue = {}

local State = {
  PENDING   = 'pending',
  FULFILLED = 'fulfilled',
  REJECTED  = 'rejected',
}

local passthrough = function(x) return x end
local errorthrough = function(x) error(x) end

local function callable_table(callback)
  local mt = getmetatable(callback)
  return type(mt) == 'table' and type(mt.__call) == 'function'
end

local is_nextable = function(value)
  local t = type(value)

  if t == 'function' then return true end
  if t ~= 'table' then return false end

  return type(value.next) == 'function'
    or callable_table(value)
end

local Promise = {
  is_promise = true,
  state = State.PENDING
}
Promise.mt = { __index = Promise }

local transition, resolve, run

function Promise.new(callback)
  local instance = {
    cache = {}
  }
  setmetatable(instance, Promise.mt)

  if callback then
    callback(
      function(value)
        resolve(instance, value)
      end,
      function(reason)
        transition(instance, State.REJECTED, reason)
      end
    )
  end

  return instance
end

local do_async = function(callback)
  if Promise.async then
    Promise.async(callback)
  else
    table.insert(queue, callback)
  end
end

transition = function(promise, state, value)
  if promise.state == state
    or promise.state ~= State.PENDING
    or ( state ~= State.FULFILLED and state ~= State.REJECTED )
    or value == nil
  then
    return
  end

  promise.state = state
  promise.value = value
  run(promise)
end

local reject = function(promise, reason)
  transition(promise, State.REJECTED, reason)
end

local fulfill = function(promise, value)
  transition(promise, State.FULFILLED, value)
end

resolve = function(promise, x)
  if promise == x then
    reject(promise, 'TypeError: cannot resolve a promise with itself')
    return
  end

  -- if x is not a table, fullfill promise with it
  if type(x) ~= 'table' or type(x.next) ~= 'function' then
    fulfill(promise, x)
    return
  end

  -- x is a promise in the current implementation
  if x.is_promise then
    -- if x is pending, use it to resolve this promise
    if x.state == State.PENDING then
      x:next(
        function(value)
          resolve(promise, value)
        end,
        function(reason)
          reject(promise, reason)
        end
      )
    else
      -- if x is already resolved, then take on its state and value
      transition(promise, x.state, x.value)
    end

    return
  end

  -- if x a non-implementation promise, aka then-able (next-able)
  local called = false
  -- Try to resolve promise with x.next
  local success, reason = pcall(
    x.next,
    x,
    function(y)
      if not called then
        called = true
        resolve(promise, y)
      end
    end,
    function(r)
      if not called then
        called = true
        reject(promise, r)
      end
    end
  )

  if not success then
    reject(promise, reason)
  end
end

run = function(promise)
  if promise.state == State.PENDING then return end

  do_async(function()
    while true do
      local obj = table.remove(promise.cache, 1)
      if not obj then
        break
      end

      local success, result = pcall(function()
        local success = obj.fulfill or passthrough
        local failure = obj.reject or errorthrough
        local callback = promise.state == State.FULFILLED and success or failure

        return callback(promise.value)
      end)

      if not success then
        reject(obj.promise, result)
      else
        resolve(obj.promise, result)
      end
    end
  end)
end

function Promise:catch(callback)
  return self:next(nil, callback)
end

function Promise:resolve(value)
  fulfill(self, value)
end

function Promise:reject(reason)
  reject(self, reason)
end

function Promise:next(on_fulfilled, on_rejected)
  local promise = Promise.new()

  table.insert(self.cache, {
    fulfill = is_nextable(on_fulfilled) and on_fulfilled or nil,
    reject = is_nextable(on_rejected) and on_rejected or nil,
    promise = promise
  })

  run(self)

  return promise
end

function Promise.update()
  while true do
    local async = table.remove(queue, 1)

    if not async then
      break
    end

    async()
  end
end

-- resolve when all promises complete
function Promise.all(...)
  local promises = {...}
  local results = {}
  local state = State.PENDING
  local remaining = #promises

  local promise = Promise.new()

  local check_finished = function()
    if remaining > 0 then
      return
    end

    transition(promise, state, results)
  end

  for i,p in ipairs(promises) do
    p:next(
      function(value)
        results[i] = value
        remaining = remaining - 1
        check_finished()
      end,
      function(value)
        results[i] = value
        remaining = remaining - 1
        state = State.REJECTED
        check_finished()
      end
    )
  end

  return promise
end

-- resolve with first promise to complete
function Promise.race(...)
  local promises = {...}
  local promise = Promise.new()

  Promise.all(...):next(nil, function(value)
    reject(promise, value)
  end)

  local success = function(value)
    fulfill(promise, value)
  end

  for _,p in ipairs(promises) do
    p:next(success)
  end

  return promise
end

return Promise