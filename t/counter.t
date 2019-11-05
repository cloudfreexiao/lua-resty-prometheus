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

=== TEST 1: counter: {"host", "status"}
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_requests = prometheus:counter(
            "nginx_http_requests_total",
            "Number of HTTP requests",
            {"host", "status"}
        )

        metric_requests:inc(1, ngx.var.server_name, 200)
        metric_requests:inc(1, ngx.var.server_name, 200)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_requests_total Number of HTTP requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total{host="localhost",status="200"} 2
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 2: counter: {"host", "status", "node"}
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_requests = prometheus:counter(
            "nginx_http_requests_total",
            "Number of HTTP requests",
            {"host", "status", "node"}
        )

        metric_requests:inc(1, ngx.var.server_name, 200, ngx.var.remote_addr)
        metric_requests:inc(1, ngx.var.server_name, 200, ngx.var.remote_addr)
        metric_requests:inc(1, ngx.var.server_name, 500, ngx.var.remote_addr)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_requests_total Number of HTTP requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total{host="localhost",status="200",node="127.0.0.1"} 2
nginx_http_requests_total{host="localhost",status="500",node="127.0.0.1"} 1
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 3: counter: del
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_requests = prometheus:counter(
            "nginx_http_requests_total",
            "Number of HTTP requests",
            {"host", "status"}
        )

        metric_requests:inc(2, ngx.var.server_name, 200)
        metric_requests:del(ngx.var.server_name, 200)
        metric_requests:inc(1, ngx.var.server_name, 200)

        prometheus:collect()
    }
}
--- request
GET /t
--- response_body
# HELP nginx_http_requests_total Number of HTTP requests
# TYPE nginx_http_requests_total counter
nginx_http_requests_total{host="localhost",status="200"} 1
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
--- no_error_log
[error]



=== TEST 4: counter: reset
--- http_config eval: $::HttpConfig
--- config
location = /t {
    content_by_lua_block {
        local prometheus = require('resty.prometheus').init("metrics")
        local metric_requests = prometheus:counter(
            "nginx_http_requests_total",
            "Number of HTTP requests",
            {"host", "status"}
        )

        metric_requests:inc(2, ngx.var.server_name, 200)
        metric_requests:inc(1, ngx.var.server_name, 200)
        metric_requests:reset()

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
