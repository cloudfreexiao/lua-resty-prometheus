PREFIX ?= /usr/local/openresty
LUA_LIB_DIR ?= $(PREFIX)/lualib/$(LUA_VERSION)
INSTALL ?= install
LUA_PATH ?= $(shell lua -e "print(package.path)")

### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) lib/resty/*.lua $(LUA_LIB_DIR)/resty/

### dev:          Create a development ENV
.PHONY: dev
dev:
	luarocks install luaunit

### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'

### test:         Run the test case
test:
	prove -I../test-nginx/lib -r -s t/
	# LUA_PATH='$(LUA_PATH);./lib/?.lua;;' resty t/prometheus_test.lua
