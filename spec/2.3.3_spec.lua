local Helper = require('spec.helper.helper')
local Promise = require('promise')

local reasons = require('spec.helper.reasons')
local nextables = require('spec.helper.nextables')

local dummy = { dummy = 'dummy' } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = 'sentinel' } -- a sentinel fulfillment value to test for with strict equality
local other = { other = 'other' } -- a value we don't want to be strict equal to
local sentinelArray = {sentinel} -- a sentinel fulfillment value to test when we need an array

local function testPromiseResolution(it, xFactory, test)
  it("via return from a fulfilled promise", function(done)
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

local function testCallingResolvePromise(yFactory, stringRepresentation, test)
  describe("`y` is " .. stringRepresentation, function()
    describe("`next` calls `resolvePromise` synchronously", function()
      local function xFactory()
        return {
          type = 'synchronous resolution',
          next = function(instance, resolvePromise)
            resolvePromise(yFactory())
          end
        }
      end

      testPromiseResolution(it, xFactory, test)
    end)

    describe("`next` calls `resolvePromise` asynchronously", function()
      local function xFactory()
        return {
          type = 'asynchronous resolution',
          next = function(instance, resolvePromise)
            Helper.timeout(0.0, function()
              resolvePromise(yFactory())
            end)
          end
        }
      end

      testPromiseResolution(it, xFactory, test)
    end)
  end)
end

local function testCallingRejectPromise(r, stringRepresentation, test)
  describe("`r` is " .. stringRepresentation, function()
    describe("`next` calls `rejectPromise` synchronously", function()
      local function xFactory()
        return {
          next = function(instance, resolvePromise, rejectPromise)
            rejectPromise(r)
          end
        }
      end

      testPromiseResolution(it, xFactory, test)
    end)

    describe("`next` calls `rejectPromise` asynchronously", function()
      local function xFactory()
        return {
          next = function(instance, resolvePromise, rejectPromise)
            Helper.timeout(0.0, function()
              rejectPromise(r)
            end)
          end
        }
      end

      testPromiseResolution(it, xFactory, test)
    end)
  end)
end

local function testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, fulfillmentValue)
  testCallingResolvePromise(yFactory, stringRepresentation, function(promise, done)
    async()
    settimeout(0.1)

    promise:next(function(value) 
      assert.are_equals(fulfillmentValue, value)
      done()
    end)
  end)
end

local function testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, rejectionReason)
  testCallingResolvePromise(yFactory, stringRepresentation, function(promise, done)
    async()
    settimeout(0.1)
    promise:next(nil, function(reason)
      assert.are_equals(reason, rejectionReason)
      done()
    end)
  end)
end

local function testCallingRejectPromiseRejectsWith(reason, stringRepresentation)
  testCallingRejectPromise(reason, stringRepresentation, function(promise, done)
    async()
    settimeout(0.1)
    promise:next(nil, function(rejectionReason)
      assert.are_equals(rejectionReason, reason)
      done()
    end)
  end)
end

describe("2.3.3: Otherwise, if `x` is an object or function,", function()
  describe("2.3.3.1: Let `next` be `x.next`", function()
    describe("`x` is a table", function()
      local numberOfTimesNextWasRetrieved
      
      before_each(function() 
        numberOfTimesNextWasRetrieved = 0
      end)
      
      local function xFactory() 
        local x = {}
        
        local mt = {
          __index = function(table, key)
            if key == 'next' then
              numberOfTimesNextWasRetrieved = numberOfTimesNextWasRetrieved + 1
              return function(instance, onFulfilled)
                onFulfilled(dummy)
              end
            end
          end
        }
        setmetatable(x, mt)
        
        return x
      end

      testPromiseResolution(it, xFactory, function(promise, done)
        async()
        settimeout(0.1)

        promise:next(function()
          assert.are_equals(1, numberOfTimesNextWasRetrieved)
          done()
        end)
      end)
    end)
  end)

  describe("2.3.3.2: If retrieving the property `x.next` results in a thrown exception `e`, reject `promise` with `e` as the reason.", function()
    local function testRejectionViaThrowingGetter(e, stringRepresentation)
      local function xFactory()
        local x = {}
        local mt = {
          __index = function(table, key)
            if key == 'next' then
              error(e)
            end
          end
        }
        setmetatable(x, mt)

        return x
      end

      describe("`e` is " .. stringRepresentation, function()
        testPromiseResolution(it, xFactory, function(promise, done)
          async()

          promise:next(nil, function(reason)
            assert.are_equals(reason, e)
            done()
          end)
        end)
      end)
    end

    for stringRepresentation, reason in pairs(reasons) do
      testRejectionViaThrowingGetter(reason, stringRepresentation)
    end
  end)

  describe("2.3.3.3: If `next` is a function, call it with first argument `x`, second argument `resolvePromise`, and third argument `rejectPromise`", function()
    describe("Calls with `x` as first argument followed by two function arguments", function()
      local function xFactory()
        local x
        x = {
          line = 200,
          next = function(p, onFulfilled, onRejected)
            assert.are_equals(p, x)
            assert.are_equals(type(onFulfilled), "function")
            assert.are_equals(type(onRejected), "function")
            onFulfilled(dummy)
          end
        }

        return x
      end

      testPromiseResolution(it, xFactory, function(promise, done)
        async()
        settimeout(0.1)
        
        promise:next(function()
          done()
        end)
      end)
    end)

    describe("2.3.3.3.1: If/when `resolvePromise` is called with value `y`, run `[[Resolve]](promise, y)`", function()
      describe("`y` is not a nextable", function()
        testCallingResolvePromiseFulfillsWith(function() return false end, "`false`", false)
        testCallingResolvePromiseFulfillsWith(function() return 5 end, "`5`", 5)
        testCallingResolvePromiseFulfillsWith(function() return sentinel end, "an object", sentinel)
        testCallingResolvePromiseFulfillsWith(function() return sentinelArray end, "an array", sentinelArray)
      end)

      describe("`y` is a nextable", function()
        it('test', function()  end)

        for stringRepresentation, nextable in pairs(nextables.fulfilled) do
          local yFactory = function()
            return nextable(sentinel)
          end

          testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, sentinel)
        end

        for stringRepresentation, nextable in pairs(nextables.rejected) do
          local yFactory = function()
            return nextable(sentinel)
          end

          testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, sentinel)
        end
      end)
  
      pending("`y` is a nextable for a nextable", function()
        for outerStringRepresentation, outerNextableFactory in pairs(nextables.fulfilled) do
          for innerStringRepresentation,  innerNextableFactory in pairs(nextables.fulfilled) do 
            local stringRepresentation = outerStringRepresentation .. " for " .. innerStringRepresentation
            
            local function yFactory()
              return outerNextableFactory(innerNextableFactory(sentinel))
            end
            
            testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, sentinel)
          end
          
          for innerStringRepresentation, innerNextableFactory in pairs(nextables.rejected) do 
            local stringRepresentation = outerStringRepresentation .. " for " .. innerStringRepresentation

            local function yFactory()
              return outerNextableFactory(innerNextableFactory(sentinel))
            end

            testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, sentinel)
          end
        end
      end)
    end)

    describe("2.3.3.3.2: If/when `rejectPromise` is called with reason `r`, reject `promise` with `r`", function()
      for stringRepresentation, reason in pairs(reasons) do
        testCallingRejectPromiseRejectsWith(reason, stringRepresentation)
      end
    end)
    
    describe("2.3.3.3.3: If both `resolvePromise` and `rejectPromise` are called, or multiple calls to the same argument are made, the first call takes precedence, and any further calls are ignored.",
      function()
        describe("calling `resolvePromise` then `rejectPromise`, both synchronously", function()
          local function xFactory()
            return { 
              next = function(instance, resolvePromise, rejectPromise)
                resolvePromise(sentinel)
                rejectPromise(other)
              end
            }
          end
  
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(function(value)
              assert.are_equals(value, sentinel)
              done()
            end)
          end)
        end)
  
        describe("calling `resolvePromise` synchronously then `rejectPromise` asynchronously", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise, rejectPromise)
                resolvePromise(sentinel)
  
                Helper.timeout(0.0, function()
                  rejectPromise(other)
                end)
              end
            }
          end
  
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
  
            promise:next(function(value)
              assert.are_equals(value, sentinel)
              done()
            end)
          end)
        end)
  
      describe("calling `resolvePromise` then `rejectPromise`, both asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              Helper.timeout(0.05, function()
                resolvePromise(sentinel)
              end)
      
              Helper.timeout(0.1, function()
                rejectPromise(other)
              end)
            end
          }
        end
  
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(value, sentinel)
            done()
          end)
        end)
      end)
  
      describe("calling `resolvePromise` with an asynchronously-fulfilled promise, then calling `rejectPromise`, both synchronously", function()
        local function xFactory()
          local p = Promise.new()
          Helper.timeout(0.05, function()
            p:resolve(sentinel)
          end)
  
          return {
            next = function(instance, resolvePromise, rejectPromise)
              resolvePromise(p)
              rejectPromise(other)
            end
          }
        end
  
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(value, sentinel)
            done()
          end)
        end)
      end)
  
      describe("calling `resolvePromise` with an asynchronously-rejected promise, then calling `rejectPromise`, both synchronously", function()
        local function xFactory()
          local p = Promise.new()
          Helper.timeout(0.05, function()
            p:reject(sentinel)
          end)
    
          return {
            next = function(instance, resolvePromise, rejectPromise)
              resolvePromise(p)
              rejectPromise(other)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `rejectPromise` then `resolvePromise`, both synchronously", function()
        local function xFactory()
          return { 
            next = function(instance, resolvePromise, rejectPromise)
              rejectPromise(sentinel)
              resolvePromise(other)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `rejectPromise` synchronously then `resolvePromise` asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              rejectPromise(sentinel)
        
              Helper.timeout(0.001, function()
                resolvePromise(other)
              end)
            end
          }
        end
        
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
      
      describe("calling `rejectPromise` then `resolvePromise`, both asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              Helper.timeout(0.05, function()
                rejectPromise(sentinel)
              end)
      
              Helper.timeout(0.1, function()
                resolvePromise(other)
              end)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `resolvePromise` twice synchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise)
              resolvePromise(sentinel)
              resolvePromise(other)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(value, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `resolvePromise` twice, first synchronously then asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise)
              resolvePromise(sentinel)
          
              Helper.timeout(0.001, function()
                resolvePromise(other)
              end)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(value, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `resolvePromise` twice, both times asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise)
              Helper.timeout(0.01, function()
                resolvePromise(sentinel)
              end, 0)
          
              Helper.timeout(0.015, function()
                resolvePromise(other)
              end)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(sentinel, value)
            done()
          end)
        end)
      end)
    
      describe("calling `resolvePromise` with an asynchronously-fulfilled promise, then calling it again, both times synchronously", function()
        local function xFactory()
          local p = Promise.new()
          
          Helper.timeout(0.01, function()
            p:resolve(sentinel)
          end)
    
          return {
            next = function(instance, resolvePromise)
              resolvePromise(p)
              resolvePromise(other)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(function(value)
            assert.are_equals(value, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `resolvePromise` with an asynchronously-rejected promise, then calling it again, both times synchronously #broke", function()
        local function xFactory()
          local p = Promise.new()
          
          Helper.timeout(0.05, function()
            p:reject(sentinel)
          end)
    
          return {
            next = function(instance, resolvePromise)
              resolvePromise(p)
              resolvePromise(other)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
      
      describe("calling `rejectPromise` twice synchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              rejectPromise(sentinel)
              rejectPromise(other)
            end
          }
        end
      
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
      
      describe("calling `rejectPromise` twice, first synchronously then asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              rejectPromise(sentinel)
    
              Helper.timeout(0.0, function()
                rejectPromise(other)
              end)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
    
      describe("calling `rejectPromise` twice, both times asynchronously", function()
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              Helper.timeout(0.01, function()
                rejectPromise(sentinel)
              end)
    
              Helper.timeout(0.02, function()
                rejectPromise(other)
              end)
            end
          }
        end
    
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          promise:next(nil, function(reason)
            assert.are_equals(reason, sentinel)
            done()
          end)
        end)
      end)
    
      describe("saving and abusing `resolvePromise` and `rejectPromise`", function()
        local savedResolvePromise, savedRejectPromise
      
        local function xFactory()
          return {
            next = function(instance, resolvePromise, rejectPromise)
              savedResolvePromise = resolvePromise
              savedRejectPromise = rejectPromise
            end
          }
        end
      
        before_each(function()
          savedResolvePromise = nil
          savedRejectPromise = nil
        end)
      
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          
          local timesFulfilled = 0
          local timesRejected = 0
      
          promise:next(
            function()
              timesFulfilled = timesFulfilled + 1
            end,
            function()
              timesRejected = timesRejected + 1
            end
          )
      
          if savedResolvePromise and savedRejectPromise then
            savedResolvePromise(dummy)
            savedResolvePromise(dummy)
            savedRejectPromise(dummy)
            savedRejectPromise(dummy)
          end
      
          Helper.timeout(0.05, function()
            savedResolvePromise(dummy)
            savedResolvePromise(dummy)
            savedRejectPromise(dummy)
            savedRejectPromise(dummy)
          end)
      
          Helper.timeout(0.1, function()
            assert.are_equals(timesFulfilled, 1)
            assert.are_equals(timesRejected, 0)
            done()
          end)
        end)
      end)
    end)
  
    describe("2.3.3.3.4: If calling `next` throws an exception `e`,", function()
      describe("2.3.3.3.4.1: If `resolvePromise` or `rejectPromise` have been called, ignore it.", function()
        describe("`resolvePromise` was called with a non-nextable", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise)
                resolvePromise(sentinel)
                error(other)
              end
            }
          end
      
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(function(value)
              assert.are_equals(value, sentinel)
              done()
            end)
          end)
        end)
  
        describe("`resolvePromise` was called with an asynchronously-fulfilled promise", function()
          local function xFactory()
            local p = Promise.new()
            Helper.timeout(0.05, function()
              p:resolve(sentinel)
            end)
      
            return {
              next = function(instance, resolvePromise)
                resolvePromise(p)
                error(other)
              end
            }
          end
      
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(function(value)
              assert.are_equals(value, sentinel)
              done()
            end)
          end)
        end)
  
        describe("`resolvePromise` was called with an asynchronously-rejected promise", function()
          local function xFactory()
            local p = Promise.new()
            Helper.timeout(0.05, function()
              p:reject(sentinel)
            end)
    
            return {
              next = function(instance, resolvePromise)
                resolvePromise(p)
                error(other)
              end
            }
          end
    
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
    
        describe("`rejectPromise` was called", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise, rejectPromise)
                rejectPromise(sentinel)
                error(other)
              end
            }
          end
    
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
      
        describe("`resolvePromise` then `rejectPromise` were called", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise, rejectPromise)
                resolvePromise(sentinel)
                rejectPromise(other)
                error(other)
              end
            }
          end
    
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(function(value)
              assert.are_equals(value, sentinel)
              done()
            end)
          end)
        end)
    
        describe("`rejectPromise` then `resolvePromise` were called", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise, rejectPromise)
                rejectPromise(sentinel)
                resolvePromise(other)
                error(other)
              end
            }
          end
      
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
      end)
  
      describe("2.3.3.3.4.2: Otherwise, reject `promise` with `e` as the reason.", function()
        describe("straightforward case", function()
          local function xFactory()
            return {
              next = function()
                error(sentinel)
              end
            }
          end
    
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
  
        describe("`resolvePromise` is called asynchronously before the `throw`", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise)
                Helper.timeout(0.0, function()
                  resolvePromise(other)
                end)
                error(sentinel)
              end
            }
          end
      
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
  
        describe("`rejectPromise` is called asynchronously before the `throw`", function()
          local function xFactory()
            return {
              next = function(instance, resolvePromise, rejectPromise)
                Helper.timeout(0.0, function()
                  rejectPromise(other)
                end, 0)
                error(sentinel)
              end
            }
          end
  
          testPromiseResolution(it, xFactory, function(promise, done)
            async()
            promise:next(nil, function(reason)
              assert.are_equals(reason, sentinel)
              done()
            end)
          end)
        end)
      end)
    end)
  end)

  describe("2.3.3.4: If `next` is not a function, fulfill promise with `x` #busted", function()
    local function testFulfillViaNonFunction(next, stringRepresentation)  
      describe("`next` is " .. stringRepresentation, function()
        local x = nil
      
        local function xFactory()
          return x
        end

        before_each(function()
          x = { next = next }
        end)
      
        testPromiseResolution(it, xFactory, function(promise, done)
          async()
          settimeout(0.1)
          
          promise:next(function(value)
            assert.are_equals(value, x)
            done()
          end)
        end)
      end)
    end

    testFulfillViaNonFunction(5, "`5`")
    testFulfillViaNonFunction({}, "a table")
    testFulfillViaNonFunction({function() end}, "an array containing a function")
  end)
end)
