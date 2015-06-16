local Helper = require('spec.helper.helper')
local Promise = require('promise')
local dummy = { dummy = 'dummy' }

describe("2.2.4: `onFulfilled` or `onRejected` must not be called until the execution context stack contains only platform code.", function()
    describe("`next` returns before the promise becomes fulfilled or rejected", function()
      Helper.test_fulfilled(it, dummy, function (promise, done)
        async()

        local thenHasReturned = false

        promise:next(function()
          assert.is_true(thenHasReturned)
          done()
        end)

        thenHasReturned = true
      end)

      Helper.test_rejected(it, dummy, function (promise, done)
        async()

        local thenHasReturned = false

        promise:next(nil, function()
          assert.is_true(thenHasReturned)
          done()
        end)

        thenHasReturned = true
      end)
    end)

    describe("Clean-stack execution ordering tests (fulfillment case)", function()
      it("when `onFulfilled` is added immediately before the promise is fulfilled", function()
        local p = Promise.new()
        local onFulfilledCalled = false

        p:next(function()
          onFulfilledCalled = true
        end)

        p:resolve(dummy)

        assert.is_false(onFulfilledCalled)
      end)

      it("when `onFulfilled` is added immediately after the promise is fulfilled", function()
        local p = Promise.new()
        local onFulfilledCalled = false

        p:resolve(dummy)

        p:next(function()
          onFulfilledCalled = true
        end)

        assert.is_false(onFulfilledCalled)
      end)

      it("when one `onFulfilled` is added inside another `onFulfilled`", function (done)
        async()

        local promise = Helper.resolved(dummy)
        local firstOnFulfilledFinished = false

        promise:next(function()
          promise:next(function()
            assert.is_true(firstOnFulfilledFinished)
            done()
          end)
          firstOnFulfilledFinished = true
        end)
      end)

      it("when `onFulfilled` is added inside an `onRejected`", function (done)
        async()

        local promise = Helper.rejected(dummy)
        local promise2 = Helper.resolved(dummy)
        local firstOnRejectedFinished = false

        promise:next(nil, function()
          promise2:next(function()
            assert.is_true(firstOnRejectedFinished)
            done()
          end)
          firstOnRejectedFinished = true
        end)
      end)

      it("when the promise is fulfilled asynchronously", function (done)
        async()

        local p = Promise.new()
        local firstStackFinished = false

        Helper.timeout(0, function()
          p:resolve(dummy)
          firstStackFinished = true
        end)

        p:next(function()
          assert.is_true(firstStackFinished)
          done()
        end)
      end)
    end)

    describe("Clean-stack execution ordering tests (rejection case)", function()
      it("when `onRejected` is added immediately before the promise is rejected", function()
        local p = Promise.new()
        local onRejectedCalled = false

        p:next(nil, function()
          onRejectedCalled = true
        end)

        p:reject(dummy)

        assert.is_false(onRejectedCalled)
      end)

      it("when `onRejected` is added immediately after the promise is rejected", function()
        local p = Promise.new()
        local onRejectedCalled = false

        p:reject(dummy)

        p:next(nil, function()
          onRejectedCalled = true
        end)

        assert.is_false(onRejectedCalled)
      end)

      it("when `onRejected` is added inside an `onFulfilled`", function (done)
        async()

        local promise = Helper.resolved(dummy)
        local promise2 = Helper.rejected(dummy)
        local firstOnFulfilledFinished = false

        promise:next(function()
          promise2:next(nil, function()
            assert.is_true(firstOnFulfilledFinished)
            done()
          end)
          firstOnFulfilledFinished = true
        end)
      end)

      it("when one `onRejected` is added inside another `onRejected`", function (done)
        async()

        local promise = Helper.rejected(dummy)
        local firstOnRejectedFinished = false

        promise:next(nil, function()
          promise:next(nil, function()
            assert.is_true(firstOnRejectedFinished)
            done()
          end)
          firstOnRejectedFinished = true
        end)
      end)

      it("when the promise is rejected asynchronously", function (done)
        async()

        local p = Promise.new()
        local firstStackFinished = false

        Helper.timeout(0.0, function()
          p:reject(dummy)
          firstStackFinished = true
        end)

        p:next(nil, function()
          assert.is_true(firstStackFinished)
          done()
        end)
      end)
    end)
  end)