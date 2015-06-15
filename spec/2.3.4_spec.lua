local Helper = require('spec.spec_helper')

local dummy = { dummy = 'dummy' } -- we fulfill or reject with this when we don't intend to test against it

describe("2.3.4: If `x` is not an object or function, fulfill `promise` with `x`", function()

  local function testValue(expectedValue, stringRepresentation)
    describe("The value is " .. stringRepresentation, function()
      Helper.test_fulfilled(it, dummy, function(promise1, done)
        async()

        local promise2 = promise1:next(function()
          return expectedValue
        end)

        promise2:next(function(actualValue)
          assert.are_equals(actualValue, expectedValue)
          done()
        end)
      end)

      Helper.test_rejected(it, dummy, function (promise1, done)
        async()

        local promise2 = promise1:next(nil, function()
          return expectedValue
        end)

        promise2:next(function(actualValue)
          assert.are_equals(actualValue, expectedValue)
          done()
        end)
      end)
    end)
  end

  testValue(false, "`false`")
  testValue(true, "`true`")
  testValue(0, "`0`")
end)