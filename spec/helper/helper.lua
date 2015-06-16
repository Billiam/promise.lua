local Promise = require('promise')
local ev = require('busted.loop.default')

Promise.async = function(callback)
  ev.create_timer(0, callback)
end

local Helper = {}

Helper.timeout = function(time, callback)
  assert(time, 'No timeout provided')
  assert(callback, 'No callback provided')
  ev.create_timer(time, callback)
end

--generate a pre-resolved promise
Helper.resolved = function(value)
  local p = Promise.new()
  p:resolve(value)
  return p
end

--generate a pre-rejected promise
Helper.rejected = function(reason)
  local p = Promise.new()
  p:reject(reason)
  return p
end

Helper.test_fulfilled = function(it, value, test)
  it("already-fulfilled", function(done)
    test(Helper.resolved(value), done)
  end)

  it("immediately-fulfilled", function(done)
    local p = Promise.new()
    test(p, done)
    p:resolve(value)
  end)

  it("eventually-fulfilled", function(done)
    local p = Promise.new()
    test(p, done)
    Helper.timeout(0.05, function()
      p:resolve(value)
    end)
  end)
end

Helper.test_rejected = function(it, reason, test)
  it("already-rejected", function(done)
    test(Helper.rejected(reason), done)
  end)

  it("immediately-rejected", function(done)
    local p = Promise.new()
    test(p, done)
    p:reject(reason)
  end)

  it("eventually-rejected", function(done)
    local p = Promise.new()
    test(p, done)
    Helper.timeout(0.05, function()
      p:reject(reason)
    end)
  end)
end

return Helper
