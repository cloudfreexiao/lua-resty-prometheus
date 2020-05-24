local skynet = require("skynet")
local base_prometheus = require("prometheus.prometheus")
local ipairs = ipairs
local tonumber = tonumber

local ook, clear_tab = pcall(require, "table.clear")
if not ook then
    clear_tab = function(tab)
        for k, _ in pairs(tab) do
            tab[k] = nil
        end
    end
end

-- Default set of latency buckets, 1ms to 60s:
local DEFAULT_BUCKETS = {
    1,
    2,
    5,
    7,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    200,
    300,
    400,
    500,
    1000,
    2000,
    5000,
    10000,
    30000,
    60000
}

local metrics = {}
local prometheus

local _M = {}

-- https://prometheus.io/docs/instrumenting/writing_exporters/
-- https://github.com/pourer/pika_exporter
-- https://www.jianshu.com/p/9646ce49f722
-- https://github.com/prometheus/haproxy_exporter
-- https://github.com/yunlzheng/prometheus-book

-- Prometheus中主要使用的四类指标类型，如下所示
-- Counter (累加指标)
-- Gauge (测量指标)
-- Summary (概略图)
-- Histogram (直方图)

-- Counter 一个累加指标数据，这个值随着时间只会逐渐的增加，
-- 比如程序完成的总任务数量，运行错误发生的总次数。
-- 常见的还有交换机中snmp采集的数据流量也属于该类型，
-- 代表了持续增加的数据包或者传输字节累加值。

-- Gauge代表了采集的一个单一数据，这个数据可以增加也可以减少，
-- 比如CPU使用情况，内存使用量，硬盘当前的空间容量等等

-- Histogram和Summary使用的频率较少，两种都是基于采样的方式。
-- 另外有一些库对于这两个指标的使用和支持程度不同，有些仅仅实现了部分功能。
-- 这两个类型对于某一些业务需求可能比较常见，比如查询单位时间内：总的响应时间低于300ms的占比，或者查询95%用户查询的门限值对应的响应时间是多少。
--  使用Histogram和Summary指标的时候同时会产生多组数据，_count代表了采样的总数，_sum则代表采样值的和。 _bucket则代表了落入此范围的数据

-- function CMD.task()
--     local addr = skynet.self()
--     local taskinfo = skynet.call(addr, "debug", "TASK")
--     fly_log.debug(" taskinfo->", addr, table_num(taskinfo))
-- end

function _M.init(conf)
    clear_tab(metrics)
    metrics.conf = conf
    prometheus = base_prometheus.init(conf) -- 1sec

    metrics.metric_requests = prometheus:counter("requests_total", "Number of HTTP requests", {"host", "status"})

    metrics.metric_latency =
        prometheus:histogram("request_duration_seconds", "HTTP request latency", {"host"}, DEFAULT_BUCKETS)

    metrics.metric_connections = prometheus:gauge("connections", "Number of HTTP connections", {"state"})
end

function _M.log(var)
    metrics.metric_requests:inc(1, {metrics.conf.service_name, 200})
    metrics.metric_latency:observe(tonumber(skynet.now() - var.start_time), {metrics.conf.service_name})
end

function _M.collect()
    if not prometheus then
        skynet.error("prometheus_metrics: is not initialized, please make sure ")
        return 500, {message = "An unexpected error occurred"}
    end

    metrics.metric_connections:set("connections_reading", {"reading"})
    metrics.metric_connections:set("connections_waiting", {"waiting"})
    metrics.metric_connections:set("connections_writing", {"writing"})

    return 200, table.concat(prometheus:collect())
end

return _M
