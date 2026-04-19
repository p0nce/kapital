-- src/resources.lua
local resources = {}

local resource_types = {
  "points", "wood", "stones", "blocks", "tiles", "sp", "bombs"
}

function resources.is_valid(name)
  for _, t in ipairs(resource_types) do
    if t == name then return true end
  end
  return false
end

function resources.add(state, resource_name, amount)
  assert(resources.is_valid(resource_name), "Invalid resource: " .. resource_name)
  state.resources[resource_name] = state.resources[resource_name] + amount
end

function resources.spend(state, resource_name, amount)
  assert(resources.is_valid(resource_name), "Invalid resource: " .. resource_name)
  if state.resources[resource_name] >= amount then
    state.resources[resource_name] = state.resources[resource_name] - amount
    return true
  end
  return false
end

function resources.can_afford(state, resource_name, amount)
  assert(resources.is_valid(resource_name), "Invalid resource: " .. resource_name)
  return state.resources[resource_name] >= amount
end

return resources
