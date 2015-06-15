local Helper = require('spec.spec_helper')
local dummy = { dummy = 'dummy' }
local other = { other = 'other' }

local sentinel = { sentinel = 'sentinel' } -- a sentinel fulfillment value to test for with strict equality
local sentinel2 = { sentinel2 = 'sentinel2' }
local sentinel3 = { sentinel3 = 'sentinel3' }

local function callbackAggregator(times, ultimateCallback)
  local soFar = 0
  return function()
    soFar = soFar + 1

    if soFar == times then
      ultimateCallback()
    end
  end
end

describe("2.2.6: `next` may be called multiple times on the same promise.", function()
  describe("2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled` callbacks must execute in the order of their originating calls to `next`.", function()
    describe("multiple boring fulfillment handlers", function()
      Helper.test_fulfilled(it, sentinel, function (promise, done)
        async()

        local handler1 = spy.new(function() return other end)
        local handler2 = spy.new(function() return other end)
        local handler3 = spy.new(function() return other end)

        local rejected_spy = spy.new(function() end)
        promise:next(handler1, rejected_spy)
        promise:next(handler2, rejected_spy)
        promise:next(handler3, rejected_spy)

        promise:next(function(value)
          assert.are.equal(value, sentinel)

          assert.spy(handler1).was_called_with(sentinel)
          assert.spy(handler2).was_called_with(sentinel)
          assert.spy(handler3).was_called_with(sentinel)

          assert.spy(rejected_spy).was_not_called()

          done()
        end)
      end)
    end)

    describe("multiple fulfillment handlers, one of which throws", function()
      Helper.test_fulfilled(it, sentinel, function (promise, done)
        async()

        local handler1 = spy.new(function() return other end)
        local handler2 = spy.new(function() error(other) end)
        local handler3 = spy.new(function() return other end)

        local rejected_spy = spy.new(function() end)
        promise:next(handler1, spy)
        promise:next(handler2, spy)
        promise:next(handler3, spy)

        promise:next(function (value)
          assert.are.equal(value, sentinel)

          assert.spy(handler1).was_called_with(sentinel)
          assert.spy(handler2).was_called_with(sentinel)
          assert.spy(handler3).was_called_with(sentinel)

          assert.spy(rejected_spy).was_not_called()

          done()
        end)
      end)
    end)

    describe("results in multiple branching chains with their own fulfillment values", function()
      Helper.test_fulfilled(it, dummy, function(promise, done)
        async()

        local semiDone = callbackAggregator(3, done)

        promise:next(function()
          return sentinel
        end):next(function(value)
          assert.are.equals(value, sentinel)

          semiDone()
        end)

        promise:next(function()
          error(sentinel2)
        end):next(nil, function (reason)
          assert.are.equals(reason, sentinel2)

          semiDone()
        end)

        promise:next(function()
          return sentinel3
        end):next(function (value)
          assert.are.equals(value, sentinel3)

          semiDone()
        end)
      end)
    end)

    describe("`onFulfilled` handlers are called in the original order", function()
      Helper.test_fulfilled(it, dummy, function (promise, done)
        async()

        local content = {}
        local ordered_callback = function(value)
          return function()
            table.insert(content, value)
          end
        end

        local handler1 = ordered_callback(1)
        local handler2 = ordered_callback(2)
        local handler3 = ordered_callback(3)

        promise:next(handler1)
        promise:next(handler2)
        promise:next(handler3)

        promise:next(function()
          assert.are.same(content, {1, 2, 3})
          done()
        end)
      end)

      describe("even when one handler is added inside another handler", function()
        Helper.test_fulfilled(it, dummy, function (promise, done)
          async()

          local content = {}
          local ordered_callback = function(value)
            return function()
              table.insert(content, value)
            end
          end

          local handler1 = ordered_callback(1)
          local handler2 = ordered_callback(2)
          local handler3 = ordered_callback(3)

          promise:next(function()
            handler1()
            promise:next(handler3)
          end)
          promise:next(handler2)

          promise:next(function()
            -- Give implementations a bit of extra time to flush their internal queue, if necessary.
            Helper.timeout(0.015, function()
              assert.are.same(content, {1, 2, 3})
              done()
            end)
          end)
        end)
      end)
    end)
  end)

  describe("2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `next`.", function()
    describe("multiple boring rejection handlers", function()
      Helper.test_rejected(it, sentinel, function(promise, done)
        async()

        local handler1 = spy.new(function() return other end)
        local handler2 = spy.new(function() return other end)
        local handler3 = spy.new(function() return other end)

        local fulfill_spy = spy.new(function() end)

        promise:next(fulfill_spy, handler1)
        promise:next(fulfill_spy, handler2)
        promise:next(fulfill_spy, handler3)

        promise:next(nil, function (reason)
          assert.are.equals(reason, sentinel)

          assert.spy(handler1).called_with(sentinel)
          assert.spy(handler2).called_with(sentinel)
          assert.spy(handler3).called_with(sentinel)
          assert.spy(fulfill_spy).was_not_called()

          done()
        end)
      end)
    end)

    describe("multiple rejection handlers, one of which throws", function()
      Helper.test_rejected(it, sentinel, function(promise, done)
        async()

        local handler1 = spy.new(function() return other end)
        local handler2 = spy.new(function() error(other) end)
        local handler3 = spy.new(function() return other end)

        local fulfill_spy = spy.new(function() end)
        promise:next(fulfill_spy, handler1)
        promise:next(fulfill_spy, handler2)
        promise:next(fulfill_spy, handler3)

        promise:next(nil, function (reason)
          assert.are.equals(reason, sentinel)

          assert.spy(handler1).called_with(sentinel)
          assert.spy(handler2).called_with(sentinel)
          assert.spy(handler3).called_with(sentinel)
          assert.spy(fulfill_spy).was_not_called()

          done()
        end)
      end)
    end)

    describe("results in multiple branching chains with their own fulfillment values", function()
      Helper.test_rejected(it, sentinel, function (promise, done)
        async()

        local semiDone = callbackAggregator(3, done)

        promise:next(nil, function()
          return sentinel
        end):next(function (value)
          assert.are.equals(value, sentinel)
          semiDone()
        end)

        promise:next(nil, function()
          error(sentinel2)
        end):next(nil, function (reason)
          assert.are.equals(reason, sentinel2)
          semiDone()
        end)

        promise:next(nil, function()
          return sentinel3
        end):next(function (value)
          assert.are.equals(value, sentinel3)
          semiDone()
        end)
      end)
    end)

    describe("`onRejected` handlers are called in the original order", function()
      Helper.test_rejected(it, dummy, function (promise, done)
        async()

        local content = {}
        local ordered_callback = function(value)
          return function()
            table.insert(content, value)
          end
        end

        local handler1 = ordered_callback(1)
        local handler2 = ordered_callback(2)
        local handler3 = ordered_callback(3)

        promise:next(nil, handler1)
        promise:next(nil, handler2)
        promise:next(nil, handler3)

        promise:next(nil, function()
          assert.are.same(content, {1, 2, 3})
          done()
        end)
      end)

      describe("even when one handler is added inside another handler", function()
        Helper.test_rejected(it, dummy, function (promise, done)
          async()

          local content = {}
          local ordered_callback = function(value)
            return function()
              table.insert(content, value)
            end
          end

          local handler1 = ordered_callback(1)
          local handler2 = ordered_callback(2)
          local handler3 = ordered_callback(3)

          promise:next(nil, function()
            handler1()
            promise:next(nil, handler3)
          end)
          promise:next(nil, handler2)

          promise:next(nil, function()
            -- Give implementations a bit of extra time to flush their internal queue, if necessary.
            Helper.timeout(0.015, function()
              assert.are.same(content, {1, 2, 3})
              done()
            end)
          end)
        end)
      end)
    end)
  end)
end)