local Helper = require('spec.spec_helper')
local Promise = require('promise')
local dummy = { dummy = 'dummy' }

describe("2.1.2.1: When fulfilled, a promise: must not transition to any other state.", function()
  Helper.test_fulfilled(it, dummy, function(promise, done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    promise:next(fulfillment, rejection)

    Helper.timeout(0.2, function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end)
  end)

  it("trying to fulfill then immediately reject", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    p:resolve(dummy)
    p:reject(dummy)

    Helper.timeout(0.1, function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end)
  end)

  it("trying to fulfill then reject, delayed", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    Helper.timeout(0.05, function()
      p:resolve(dummy)
      p:reject(dummy)
    end)

    Helper.timeout(0.1, function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end)
  end)

  it("trying to fulfill immediately then reject delayed", function(done)
    async()

    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local p = Promise.new()

    p:next(fulfillment, rejection)

    p:resolve(dummy)

    Helper.timeout(0.05, function()
      p:reject(dummy)
    end)

    Helper.timeout(0.1, function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end)
  end)
end)