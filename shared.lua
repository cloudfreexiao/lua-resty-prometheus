local mt = {}
mt.__index = mt

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

function mt:get_keys(max_count)
    local count = 0
    local tbl = {}
    for k, _ in pairs(self.data or {}) do
        table.insert(tbl, k)
        if max_count >0 then
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
    local obj = objs[tostring(dict_name)]
    if not obj then
        local o = {
            data = {},
        }
        obj = setmetatable(o, mt)
        objs[tostring(dict_name)] = obj
    end

    return obj
end

return M