local Helper = require('spec.spec_helper')
local dummy = { dummy = 'dummy' }

describe("2.2.1: Both `onFulfilled` and `onRejected` are optional arguments.", function()
  describe("2.2.1.1: If `onFulfilled` is not a function, it must be ignored.", function()
    describe("applied to a directly-rejected promise", function()
      local function testNonFunction(non_function, string_representation)
        it("`onFulfilled` is " .. string_representation, function(done)
          async()
          Helper.rejected(dummy):next(non_function, function()
            done()
          end)
        end)
      end

      testNonFunction(nil, "`nil`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)


    describe("applied to a promise rejected and then chained off of", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        it("`onFulfilled` is " .. stringRepresentation, function (done)
          async()

          Helper.rejected(dummy):next(function() end, nil):next(nonFunction, function()
            done();
          end)
        end)
      end

      testNonFunction(nil, "`nil`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)
  end)

  describe("2.2.1.2: If `onRejected` is not a function, it must be ignored.", function()
    describe("applied to a directly-fulfilled promise", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        it("`onRejected` is " .. stringRepresentation, function (done)
          async()

          Helper.resolved(dummy):next(function()
            done()
          end, nonFunction)
        end)
      end

      testNonFunction(nil, "`null`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)

    describe("applied to a promise fulfilled and then chained off of", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        it("`onFulfilled` is " .. stringRepresentation, function (done)
          async()

          Helper.resolved(dummy):next(undefined, function() end):next(function()
            done()
          end, nonFunction)
        end)
      end

      testNonFunction(undefined, "`undefined`")
      testNonFunction(null, "`null`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "an object")
    end)
  end)
end)