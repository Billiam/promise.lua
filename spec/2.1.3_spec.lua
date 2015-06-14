local Helper = require('spec.spec_helper')
local Promise = require('promise')
local dummy = { dummy = 'dummy' }

describe("2.1.3.1: When rejected, a promise: must not transition to any other state.", function()
  Helper.test_rejected(it, dummy, function(promise, done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    promise:next(fulfillment, rejection)

    Helper.timeout(0.2, function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end)
  end)

  it("trying to reject then immediately fulfill", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    p:reject(dummy)
    p:resolve(dummy)

    Helper.timeout(0.1, function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end)
  end)

  it("trying to reject then fulfill, delayed", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    Helper.timeout(0.05, function()
      p:reject(dummy)
      p:resolve(dummy)
    end)

    Helper.timeout(0.1, function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end)
  end)

  it("trying to reject immediately then fulfill delayed", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    p:reject(dummy)

    Helper.timeout(0.05, function()
      p:resolve(dummy)
    end)

    Helper.timeout(0.1, function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end)
  end)
end)