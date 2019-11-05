use Test::Nginx::Socket::Lua 'no_plan';
use Cwd qw(cwd);

no_shuffle();
no_long_string();

our $HttpConfig = qq{
    lua_package_path "./lib/?.lua;;";
    lua_shared_dict metrics 8m;
};

run_tests();

__DATA__

=== TEST 1: observe: {"state"}
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_latency = prometheus:histogram(
            "nginx_http_request_duration_seconds", "HTTP request latency", {"host"})

        metric_latency:observe(0.1, ngx.var.server_name)
        metric_latency:observe(0.1, ngx.var.server_name)
        metric_latency:observe(0.1, ngx.var.server_name)
        metric_latency:observe(0.3, ngx.var.server_name)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_request_duration_seconds HTTP request latency
# TYPE nginx_http_request_duration_seconds histogram
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.100"} 3
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.200"} 3
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.300"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.400"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.500"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="00.750"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="01.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="01.500"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="02.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="03.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="04.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="05.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="10.000"} 4
nginx_http_request_duration_seconds_bucket{host="localhost",le="+Inf"} 4
nginx_http_request_duration_seconds_count{host="localhost"} 4
nginx_http_request_duration_seconds_sum{host="localhost"} 0.6
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]
