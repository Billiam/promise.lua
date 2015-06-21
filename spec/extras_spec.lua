local Helper = require('spec.helper.helper')
local Promise = require('promise')

local dummy = { dummy = 'dummy' } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = 'sentinel' }
local other = { other = 'other' }

describe('.all', function()
  it("returns results for each promise", function(done)
    async()

    local result1 = { result = 1 }
    local result2 = { result = 2 }
    local result3 = { result = 3 }

    local promise1 = Promise.new()
    local promise2 = Promise.new()
    local promise3 = Promise.new()

    Helper.timeout(0.1, function()
      promise1:resolve(result1)
    end)

    Helper.timeout(0.15, function()
      promise2:resolve(result2)
    end)

    Helper.timeout(0.2, function()
      promise3:resolve(result3)
    end)

    Promise.all(promise1, promise2, promise3):next(function(results)
      assert.are_same({result1, result2, result3}, results)
      done()
    end)
  end)

  it("is rejected when any promises are rejected", function(done)
    async()

    local result1 = { result = 1 }
    local result2 = { result = 2 }

    local promise1 = Promise.new()
    local promise2 = Promise.new()

    Helper.timeout(0.1, function()
      promise1:resolve(result1)
    end)

    Helper.timeout(0.15, function()
      promise2:reject(result2)
    end)

    Promise.all(promise1, promise2, promise3):next(
      nil,
      function(results)
        done()
      end
    )
  end)

  it("is fulfilled when no promises are provided", function(done)
    async()
    
    Promise.all():next(function()
      done()
    end)
  end)
end)

describe(".race", function()
  it("returns the first resolved promise", function(done)
    async()

    local promise1 = Promise.new()
    local promise2 = Promise.new()
    local promise3 = Promise.new()

    Helper.timeout(0.1, function()
      promise1:resolve(other)
    end)

    Helper.timeout(0.15, function()
      promise2:resolve(other)
    end)

    Helper.timeout(0.05, function()
      promise3:resolve(sentinel)
    end)

    Promise.race(promise1, promise2, promise3):next(function(result)
      assert.are_equals(sentinel, result)
      done()
    end)
  end)

  it("is resolved when any callbacks are resolved", function(done)
    async()

    local promise1 = Promise.new()
    local promise2 = Promise.new()

    Helper.timeout(0.1, function()
      promise1:reject(other)
    end)

    Helper.timeout(0.2, function()
      promise2:resolve(sentinel)
    end)

    Promise.race(promise1, promise2):next(function(result)
      assert.are_equals(sentinel, result)
      done()
    end)
  end)

  it("is rejected when all promises are rejected", function(done)
    async()

    settimeout(0.3)
    local result1 = { result = 1 }
    local result2 = { result = 2 }
    local result3 = { result = 3 }

    local promise1 = Promise.new()
    local promise2 = Promise.new()
    local promise3 = Promise.new()

    Helper.timeout(0.2, function()
      promise1:reject(result1)
    end)

    Helper.timeout(0.15, function()
      promise2:reject(result2)
    end)

    Helper.timeout(0.1, function()
      promise3:reject(result3)
    end)

    Promise.race(promise1, promise2, promise3):next(
      function()
      end,
      function(results)
        assert.are_same({result1, result2, result3}, results)
        done()
      end
    )
  end)
end)