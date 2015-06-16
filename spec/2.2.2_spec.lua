local Helper = require('spec.helper.helper')
local Promise = require('promise')
local dummy = { dummy = 'dummy' }
local sentinel = { sentinel = 'sentinel' }

describe("2.2.2: If `onFulfilled` is a function,", function()
  describe("2.2.2.1: it must be called after `promise` is fulfilled, with `promise`’s fulfillment value as its first argument.", function()
    Helper.test_fulfilled(it, sentinel, function(promise, done)
      async()

      promise:next(function(value)
        assert.are_equals(value, sentinel)
        done()
      end)
    end)
  end)

  describe("2.2.2.2: it must not be called before `promise` is fulfilled", function()
    it("fulfilled after a delay", function(done)
      async()

      local p = Promise.new()
      local fulfillment = spy.new(function() end)

      p:next(fulfillment)

      Helper.timeout(0.05, function()
        p:resolve(dummy)
      end)

      Helper.timeout(0.1, function()
        assert.spy(fulfillment).was_called(1)
        done()
      end)
    end)

    it("never fulfilled", function(done)
      async()

      local p = Promise.new()
      local fulfillment = spy.new(function() end)

      p:next(fulfillment)

      Helper.timeout(0.15, function()
        assert.spy(fulfillment).was_not_called()
        done()
      end)
    end)
  end)

  describe("2.2.2.3: it must not be called more than once.", function()
    it("already-fulfilled", function(done)
      async()

      local callback = spy.new(function() end)
      Helper.resolved(dummy):next(callback)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to fulfill a pending promise more than once, immediately", function(done)
      async()

      local p = Promise.new()

      local callback = spy.new(function() end)
      p:next(callback)

      p:resolve(dummy)
      p:resolve(dummy)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to fulfill a pending promise more than once, delayed", function(done)
      async()

      local p = Promise.new()
      local callback = spy.new(function() end)

      p:next(callback)

      Helper.timeout(0.05, function()
        p:resolve(dummy)
        p:resolve(dummy)
      end)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to fulfill a pending promise more than once, immediately then delayed", function(done)
      async()

      local p = Promise.new()

      local callback = spy.new(function() end)
      p:next(callback)

      p:resolve(dummy)

      Helper.timeout(0.05, function()
        p:resolve(dummy)
      end)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("when multiple `next` calls are made, spaced apart in time", function(done)
      async()

      local p = Promise.new()

      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)
      local callback_3 = spy.new(function() end)

      p:next(callback_1)

      Helper.timeout(0.05, function()
        p:next(callback_2)
      end)

      Helper.timeout(0.1, function()
        p:next(callback_3)
      end)

      Helper.timeout(0.15, function()
        p:resolve(dummy)
      end)

      Helper.timeout(0.2, function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        assert.spy(callback_3).was_called(1)
        done()
      end)
    end)

    it("when `next` is interleaved with fulfillment", function(done)
      async()

      local p = Promise.new()
      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)

      p:next(callback_1)
      p:resolve(dummy)
      p:next(callback_2)

      Helper.timeout(0.1, function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        done()
      end)
    end)
  end)
end)