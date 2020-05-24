local skynet = require("skynet")
require("skynet.manager")

local split = require("luazdf.str.split")
local table_num = require("luazdf.table.num")

local prometheus = require("fly.prometheus.index")

local function retpack(noret, ...)
    if noret ~= "NORET" then
        skynet.retpack(noret, ...)
    end
end

local CMD = {}

function CMD.collect()
    return prometheus.collect()
end

function CMD.test()
    skynet.error("++++++prometheus_monitor test+++++++")
end

skynet.start(
    function()
        -- init prometheus plugin
        local service_name = "." .. SERVICE_NAME
        prometheus.init(
            {
                service_name = service_name
            }
        )

        skynet.dispatch(
            "lua",
            function(_, _, cmd, ...)
                -- skynet.ignoreret()	-- session is fd, don't call skynet.ret
                -- skynet.trace()
                local start_time = skynet.now()
                local cmdlist = split(cmd, "@")
                assert(cmdlist[1])
                assert(cmdlist[2])
                local f = assert(CMD[cmdlist[1]], cmdlist[1])
                retpack(f(cmdlist[2], ...))
                prometheus.log({start_time = start_time})
            end
        )

        skynet.register(service_name)
    end
)
