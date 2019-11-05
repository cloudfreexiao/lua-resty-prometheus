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

=== TEST 1: guage: {"state"}
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_connections = prometheus:gauge(
            "nginx_http_connections",
            "Number of HTTP connections",
            {"state"}
        )

        metric_connections:set(1024, ngx.var.server_name)
        metric_connections:set(1028, ngx.var.server_name)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_connections Number of HTTP connections
# TYPE nginx_http_connections gauge
nginx_http_connections{state="localhost"} 1028
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 2: set + inc
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_connections = prometheus:gauge(
            "nginx_http_connections",
            "Number of HTTP connections",
            {"state"}
        )

        metric_connections:set(1024, ngx.var.server_name)
        metric_connections:inc(10, ngx.var.server_name)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_connections Number of HTTP connections
# TYPE nginx_http_connections gauge
nginx_http_connections{state="localhost"} 1034
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 3: set + del
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_connections = prometheus:gauge(
            "nginx_http_connections",
            "Number of HTTP connections",
            {"host"}
        )

        metric_connections:set(1024, ngx.var.server_name .. "_1")
        metric_connections:set(1024, ngx.var.server_name)
        metric_connections:inc(10, ngx.var.server_name)
        metric_connections:del(ngx.var.server_name)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_connections Number of HTTP connections
# TYPE nginx_http_connections gauge
nginx_http_connections{host="localhost_1"} 1024
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 4: set + reset
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_connections = prometheus:gauge(
            "nginx_http_connections",
            "Number of HTTP connections",
            {"host"}
        )

        metric_connections:set(1024, ngx.var.server_name .. "_1")
        metric_connections:set(1024, ngx.var.server_name)
        metric_connections:reset()

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]
