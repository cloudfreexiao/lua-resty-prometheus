package = "lua-resty-prometheus"
version = "master-0"

source = {
  url = "git://github.com/iresty/lua-resty-prometheus.git",
  branch = "master",
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
