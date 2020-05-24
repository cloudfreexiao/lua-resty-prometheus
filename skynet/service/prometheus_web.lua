local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

local mode, agent_protocol = ...
agent_protocol = agent_protocol or "http"

if mode == "agent" then
    local function response(id, write, ...)
        local ok, err = httpd.write_response(write, ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", id, err))
        end
    end

    local api = require("fly.prometheus.index").api()

    local SSLCTX_SERVER = nil
    local function gen_interface(protocol, fd)
        if protocol == "http" then
            return {
                init = nil,
                close = nil,
                read = sockethelper.readfunc(fd),
                write = sockethelper.writefunc(fd)
            }
        elseif protocol == "https" then
            local tls = require "http.tlshelper"
            if not SSLCTX_SERVER then
                SSLCTX_SERVER = tls.newctx()
                -- gen cert and key
                -- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
                local certfile = skynet.getenv("certfile") or "./server-cert.pem"
                local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
                print(certfile, keyfile)
                SSLCTX_SERVER:set_cert(certfile, keyfile)
            end
            local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
            return {
                init = tls.init_responsefunc(fd, tls_ctx),
                close = tls.closefunc(tls_ctx),
                read = tls.readfunc(fd, tls_ctx),
                write = tls.writefunc(fd, tls_ctx)
            }
        else
            error(string.format("Invalid protocol: %s", protocol))
        end
    end

    skynet.start(
        function()
            skynet.dispatch(
                "lua",
                function(_, _, id)
                    socket.start(id)
                    local interface = gen_interface(agent_protocol, id)
                    if interface.init then
                        interface.init()
                    end
                    -- limit request body size to 8192 (you can pass nil to unlimit)
                    local code, url, method, header, body = httpd.read_request(interface.read, 8192)
                    if code then
                        if code ~= 200 then
                            response(id, interface.write, code)
                        else
                            local path = urllib.parse(url)
                            if path == api.uri and api.match_method(method) then
                                local resp_code, response_data = api.collect()
                                response(id, interface.write, code, response_data, api.resp_header)
                            else
                                response(id, interface.write, 404)
                            end
                        end
                    else
                        if url == sockethelper.socket_error then
                            skynet.error("socket closed")
                        else
                            skynet.error(url)
                        end
                    end
                    socket.close(id)
                    if interface.close then
                        interface.close()
                    end
                end
            )
        end
    )
else
    local port = tonumber(agent_protocol)

    skynet.start(
        function()
            local agent = {}
            local gate_protocol = "http"
            for i = 1, 1 do
                agent[i] = skynet.newservice(SERVICE_NAME, "agent", gate_protocol)
            end
            local balance = 1
            local id = socket.listen("0.0.0.0", port)
            skynet.error(string.format("Listen web port[%d] protocol:[%s]", port, gate_protocol))
            socket.start(
                id,
                function(fd, addr)
                    skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
                    skynet.send(agent[balance], "lua", fd)
                    balance = balance + 1
                    if balance > #agent then
                        balance = 1
                    end
                end
            )

            skynet.register("." .. SERVICE_NAME)
        end
    )
end
