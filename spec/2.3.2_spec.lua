local Helper = require('spec.spec_helper')
local Promise = require('promise')

local dummy = { dummy = 'dummy' } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = 'sentinel' } -- a sentinel fulfillment value to test for with strict equality

local function testPromiseResolution(it, xFactory, test)
  it("via return from a fulfilled promise", function (done)
    local promise = Helper.resolved(dummy):next(function()
      return xFactory()
    end)

    test(promise, done)
  end)

  it("via return from a rejected promise", function(done)
    local promise = Helper.rejected(dummy):next(nil, function()
      return xFactory()
    end)

    test(promise, done)
  end)
end

describe("2.3.2: If `x` is a promise, adopt its state", function()
  describe("2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.", function()
    local function xFactory()
      return Promise.new()
    end

    testPromiseResolution(it, xFactory, function (promise, done)
      async()

      local fulfillment = spy.new(function() end)
      local rejection = spy.new(function() end)

      promise:next(fulfillment, rejection)

      Helper.timeout(0.1, function()
        assert.spy(fulfillment).was_not_called()
        assert.spy(rejection).was_not_called()
        done()
      end)
    end)
  end)

  describe("2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.", function()
    describe("`x` is already-fulfilled", function()
      local function xFactory()
        return Helper.resolved(sentinel)
      end

      testPromiseResolution(xFactory, function (promise, done)
        async()

        promise:next(function(value)
          assert.are.equals(value, sentinel)
          done()
        end)
      end)
    end)

    describe("`x` is eventually-fulfilled", function()
      local function xFactory()
        local p = Promise.new()

        Helper.timeout(0.05, function()
          p:resolve(sentinel)
        end)

        return p
      end

      testPromiseResolution(it, xFactory, function(promise, done)
        async()

        promise:next(function(value)
          assert.are_equals(value, sentinel)
          done()
        end)
      end)
    end)
  end)

  describe("2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason.", function()
    describe("`x` is already-rejected", function()
      local function xFactory()
        return Helper.rejected(sentinel)
      end

      testPromiseResolution(it, xFactory, function(promise, done)
        promise:next(nil, function(reason)
          assert.are_equals(reason, sentinel)
          done()
        end)
      end)
    end)

    describe("`x` is eventually-rejected", function()
      local function xFactory()
        local p = Promise.new()

        Helper.timeout(0.05, function()
          p:reject(sentinel)
        end)

        return p
      end

      testPromiseResolution(it, xFactory, function(promise, done)
        promise:next(nil, function(reason)
          assert.are_equals(reason, sentinel)
          done()
        end)
      end)
    end)
  end)
end)