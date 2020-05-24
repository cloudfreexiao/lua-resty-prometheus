local mt = {
    data = {}
}
mt.__index = mt

-- https://github.com/openresty/lua-nginx-module#ngxshareddict

-- get
-- get_stale
-- set
-- safe_set
-- add
-- safe_add
-- replace
-- delete
-- incr
-- lpush
-- rpush
-- lpop
-- rpop
-- llen
-- ttl
-- expire
-- flush_all
-- flush_expired
-- get_keys
-- capacity
-- free_space

function mt:set(key, value)
    self.data[key] = value
end

function mt:incr(key, num)
    local v = self.data[key]
    if v then
        self.data[key] = v + num
    else
        self.data[key] = v
    end
end

function mt:safe_set(...)
    self:set(...)
end

function mt:add(key, value, exptime, flags)
    local v = self.data[key]
    if v then
        self.data[key] = v + value
    else
        self.data[key] = v
    end
end

function mt:safe_add(...)
    self:add(...)
    return true
end

function mt:get_keys(max_count)
    local count = 0
    local tbl = {}
    for k, _ in pairs(self.data or {}) do
        table.insert(tbl, k)
        if max_count > 0 then
            count = count + 1
            if count >= max_count then
                break
            end
        end
    end
    return tbl
end

function mt:get(key)
    return self.data[key]
end

local M = {}

local objs = {}

function M.new(dict_name)
    local obj = objs[dict_name]
    if not obj then
        obj = setmetatable({}, mt)
        objs[dict_name] = obj
    end

    return obj
end

function M.get(dict_name)
    return objs[dict_name]
end

return M
