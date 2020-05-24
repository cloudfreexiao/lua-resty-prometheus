local skynet = require("skynet")
local exporter = require("fly.prometheus.exporter")

-- https://github.com/apache/incubator-apisix/blob/master/doc/plugins/prometheus-cn.md
-- https://github.com/openresty/lua-nginx-module

-- curl -i http://127.0.0.1:43002/fly/prometheus/metrics

local _M = {}

function _M.init(conf)
    exporter.init(conf)
end

function _M.log(var)
    exporter.log(var)
end

function _M.collect()
    return exporter.collect()
end

function _M.api()
    return {
        uri = "/fly/prometheus/metrics",
        match_method = function(method)
            for _, v in ipairs({"GET"}) do
                if v == method then
                    return true
                end
            end
            return false
        end,
        resp_header = {
            content_type = "text/plain"
        },
        collect = function()
            return skynet.call(".prometheus_monitor", "lua", "collect@.prometheus_web")
        end
    }
end

return _M
