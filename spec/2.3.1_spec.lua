local Helper = require('spec.helper.helper')

local dummy = { dummy = 'dummy' } -- we fulfill or reject with this when we don't intend to test against it

describe("2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a `TypeError' as the reason.", function()
  it("via return from a fulfilled promise", function(done)
    async()

    local promise

    promise = Helper.resolved(dummy):next(function()
      return promise
    end)

    promise:next(nil, function (reason)
      assert.is_truthy(string.find(reason, 'TypeError'))
      done()
    end)
  end)

  it("via return from a rejected promise", function(done)
    async()

    local promise

    promise = Helper.rejected(dummy):next(nil, function()
      return promise
    end)

    promise:next(nil, function (reason)
      assert.is_truthy(string.find(reason, 'TypeError'))
      done()
    end)
  end)
end)
