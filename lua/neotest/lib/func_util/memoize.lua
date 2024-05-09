--- Memoize function from https://github.com/kikito/memoize.lua
local logger = require("neotest.logging")

local function is_callable(f)
  local tf = type(f)
  if tf == "function" then
    return true
  end
  if tf == "table" then
    local mt = getmetatable(f)
    return type(mt) == "table" and is_callable(mt.__call)
  end
  return false
end

local function cache_get(cache, params)
  local node = cache
  for i = 1, #params do
    node = node.children and node.children[params[i]]
    if not node then
      return nil
    end
  end
  return node.results
end

local function cache_put(cache, params, results)
  local node = cache
  local param
  for i = 1, #params do
    param = params[i]
    node.children = node.children or {}
    node.children[param] = node.children[param] or {}
    node = node.children[param]
  end
  node.results = results
end

return function(f, cache)
  cache = cache or {}

  if not is_callable(f) then
    error(
      string.format(
        "Only functions and callable tables are memoizable. Received %s (a %s)",
        tostring(f),
        type(f)
      )
    )
  end

  return function(...)
    local params = { ... }

    logger.trace("Memoize: ", vim.inspect(params))
    local results = cache_get(cache, params)
    if not results then
      results = { f(...) }
      logger.trace("cache_miss: ", vim.inspect(results))
      cache_put(cache, params, results)
    else
      logger.trace("cache_hit: " , vim.inspect(params))
    end

    return unpack(results)
  end
end
