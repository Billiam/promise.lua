local Helper = require('spec.helper.helper')
local Promise = require('promise')
local dummy = { dummy = 'dummy' }
local sentinel = { sentinel = 'sentinel' }

describe("2.2.2: If `onRejected` is a function,", function()
  describe("2.2.2.1: it must be called after `promise` is rejected, with `promise`’s rejection reason as its first argument.", function()
    Helper.test_rejected(it, sentinel, function(promise, done)
      async()

      promise:next(nil, function(value)
        assert.are_equals(value, sentinel)
        done()
      end)
    end)
  end)

  describe("2.2.3.2: it must not be called before `promise` is rejected", function()
    it("rejected after a delay", function(done)
      async()

      local p = Promise.new()
      local rejection = spy.new(function() end)

      p:next(nil, rejection)

      Helper.timeout(0.05, function()
        p:reject(dummy)
      end)

      Helper.timeout(0.1, function()
        assert.spy(rejection).was_called(1)
        done()
      end)
    end)

    it("never rejected", function(done)
      async()

      local p = Promise.new()
      local rejection = spy.new(function() end)

      p:next(nil, rejection)

      Helper.timeout(0.15, function()
        assert.spy(rejection).was_not_called()
        done()
      end)
    end)
  end)

  describe("2.2.3.3: it must not be called more than once.", function()
    it("already-rejected", function(done)
      async()

      local callback = spy.new(function() end)
      Helper.rejected(dummy):next(nil, callback)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to reject a pending promise more than once, immediately", function(done)
      async()

      local p = Promise.new()

      local callback = spy.new(function() end)
      p:next(nil, callback)

      p:reject(dummy)
      p:reject(dummy)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to reject a pending promise more than once, delayed", function(done)
      async()

      local p = Promise.new()
      local callback = spy.new(function() end)

      p:next(nil, callback)

      Helper.timeout(0.05, function()
        p:reject(dummy)
        p:reject(dummy)
      end)

      Helper.timeout(0.1, function()
        assert.spy(callback).was_called(1)
        done()
      end)
    end)

    it("trying to reject a pending promise more than once, immediately then delayed", function(done)
      async()

      local p = Promise.new()

      local callback = spy.new(function() end)
      p:next(nil, callback)

      p:reject(dummy)

      Helper.timeout(0.05, function()
        p:reject(dummy)
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

      p:next(nil, callback_1)

      Helper.timeout(0.05, function()
        p:next(nil, callback_2)
      end)

      Helper.timeout(0.1, function()
        p:next(nil, callback_3)
      end)

      Helper.timeout(0.15, function()
        p:reject(dummy)
      end)

      Helper.timeout(0.2, function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        assert.spy(callback_3).was_called(1)
        done()
      end)
    end)

    it("when `next` is interleaved with rejection", function(done)
      async()

      local p = Promise.new()
      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)

      p:next(nil, callback_1)
      p:reject(dummy)
      p:next(nil, callback_2)

      Helper.timeout(0.1, function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        done()
      end)
    end)
  end)
end)