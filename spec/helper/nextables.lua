local Helper = require('spec.helper.helper')
local Promise = require('promise')
local other = { other = "other" } -- a value we don't want to be strict equal to

local Nextable = {}

Nextable.fulfilled = {
  ["a synchronously-fulfilled custom nextable"] = function(value)
    return {
      next = function(instance, onFulfilled)
        onFulfilled(value)
      end
    }
  end,

  ["an asynchronously-fulfilled custom nextable"] = function(value)
    return {
      next = function(instance, onFulfilled)
        Helper.timeout(0.0, function()
          onFulfilled(value)
        end)
      end
    }
  end,

  ["a synchronously-fulfilled one-time nextable"] = function (value)
    local numberOfTimesNextRetrieved = 0

    local x = {}
    local mt = {
      __index = function(table, key)
        if key == 'next' then
          if numberOfTimesNextRetrieved == 0 then
            numberOfTimesNextRetrieved = numberOfTimesNextRetrieved + 1
            return function(instance, onFulfilled)
              onFulfilled(value)
            end
          end
        end
      end
    }
    return setmetatable(x, mt)
  end,

  ["a nextable that tries to fulfill twice"] = function (value)
    return {
      next = function(instance, onFulfilled)
        onFulfilled(value)
        onFulfilled(other)
      end
    }
  end,

  ["a nextable that fulfills but then throws"] = function(value)
    return {
      next = function(instance, onFulfilled)
        onFulfilled(value)
        error(other)
      end
    }
  end,

  ["an already-fulfilled promise"] = function(value)
    return Helper.resolved(value)
  end,

  ["an eventually-fulfilled promise"] = function(value)
    local p = Promise.new()
    Helper.timeout(0.05, function()
      p:resolve(value)
    end)
    return p
  end
}

Nextable.rejected = {
  ["a synchronously-rejected custom nextable"] = function(reason)
    return {
      next = function(instance, onFulfilled, onRejected)
        onRejected(reason)
      end
    }
  end,

  ["an asynchronously-rejected custom nextable"] = function(reason)
    return {
      next = function(instance, onFulfilled, onRejected)
        Helper.timeout(0.0, function()
          onRejected(reason)
        end)
      end
    }
  end,

  ["a synchronously-fulfilled one-time nextable"] = function (value)
    local numberOfTimesNextRetrieved = 0

    local x = {}
    local mt = {
      __index = function(table, key)
        if key == 'next' then
          if numberOfTimesNextRetrieved == 0 then
            numberOfTimesNextRetrieved = numberOfTimesNextRetrieved + 1
            return function(instance, onFulfilled, onRejected)
              onRejected(value)
            end
          end
        end
      end
    }
    return setmetatable(x, mt)
  end,
  ["a nextable that immediately throws in `next`"] = function (reason)
    return {
      next = function()
        error(reason)
      end
    }
  end,
  ["an object with a throwing `then` accessor"] = function (reason)
    local x = {}
    local mt = {
      __index = function(table, key)
        if key == 'next' then
          error(reason)
        end
      end
    }
    return setmetatable(x, mt)
  end,

  ["an already-rejected promise"] = function(reason)
    return Helper.rejected(reason)
  end,

  ["an eventually-rejected promise"] = function (reason)
    local p = Promise.new()
    Helper.timeout(0.05, function()
      p:reject(reason)
    end)
    return p
  end
}

return Nextable
