package = "lua-resty-prometheus"
version = "0.1"

source = {
  url = "git://github.com/iresty/lua-resty-prometheus.git",
  tag = "v0.1",
}

description = {
  summary = "Prometheus metric library for OpenResty",
  homepage = "https://github.com/iresty/lua-resty-prometheus",
  license = "MIT"
}

build = {
    type = "builtin",
    modules = {
        ["resty.prometheus"] = "lib/resty/prometheus.lua"
    }
}
