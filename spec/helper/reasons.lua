local Helper = require('spec.helper.helper')

local reasons = {
  ["`nil`"] = function()
    return nil
  end,
  ["`false`"] = function()
    return false
  end,
  ["`0`"] = function()
    return 0
  end,
  ["an error"] = function()
    error()
  end,
  ["a table"] = function()
    return {}
  end,
  ["an always-pending nextable"] = function()
    return { next = function() end }
  end,
  ["a fulfilled promise"] = function()
    return Helper.resolved(dummy)
  end,
  ["a rejected promise"] = function()
    return Helper.rejected(dummy)
  end,
}

return reasons