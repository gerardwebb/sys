
SHARED_FSPATH=./../shared
#SHARED_FSPATH=./

BOILERPLATE_FSPATH=$(SHARED_FSPATH)/boilerplate

include $(BOILERPLATE_FSPATH)/help.mk
include $(BOILERPLATE_FSPATH)/os.mk
include $(BOILERPLATE_FSPATH)/gitr.mk
include $(BOILERPLATE_FSPATH)/tool.mk
include $(BOILERPLATE_FSPATH)/flu.mk
include $(BOILERPLATE_FSPATH)/go.mk


# remove the "v" prefix
VERSION ?= $(shell echo $(TAGGED_VERSION) | cut -c 2-)

override FLU_SAMPLE_NAME =client
override FLU_LIB_NAME =client


CI_DEP=github.com/getcouragenow/sys
CI_DEP_FORK=github.com/joe-getcouragenow/sys


SDK_BIN=$(PWD)/bin-all/sdk-cli
SERVER_BIN=$(PWD)/bin-all/sys-main

EXAMPLE_SERVER_PORT=8888
EXAMPLE_SERVER_ADDRESS=127.0.0.1:$(EXAMPLE_SERVER_PORT)
EXAMPLE_EMAIL = superadmin@getcouragenow.org
EXAMPLE_PASSWORD = superadmin
EXAMPLE_SYS_CORE_DB_ENCRYPT_KEY = yYz8Xjb4HBn4irGQpBWulURjQk2XmwES
EXAMPLE_SYS_CORE_CFG_PATH = ./config/syscore.yml
EXAMPLE_SYS_ACCOUNT_CFG_PATH = ./config/sysaccount.yml
EXAMPLE_SERVER_DIR = ./example/server
EXAMPLE_SDK_DIR = ./example/sdk-cli

this-all: this-print this-dep this-build this-print-end

## Print all settings
this-print: 
	@echo
	@echo "-- SYS: start --"
	@echo SDK_BIN: $(SDK_BIN)
	@echo

this-print-end:
	@echo
	@echo "-- SYS: end --"
	@echo
	@echo


this-dep:
	cd $(SHARED_FSPATH) && $(MAKE) this-all

this-dev-dep:
	## TODO Add to boot and version it
	GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
	brew install jsonnet

### BUILD

this-prebuild:
	# so the go mod is updated
	go get -u github.com/getcouragenow/sys-share

this-build: this-build-delete this-config-gen

	mkdir -p ./bin-all
	mkdir -p ./bench

	cd sys-account && $(MAKE) this-all
	cd sys-core && $(MAKE) this-all

	go build -o $(SDK_BIN) $(EXAMPLE_SDK_DIR)/main.go
	go build -o $(SERVER_BIN) $(EXAMPLE_SERVER_DIR)/main.go

this-config-gen: this-config-delete this-config-dep
	@echo Generating Config
	@mkdir -p ./config
	jsonnet -S $(EXAMPLE_SERVER_DIR)/sysaccount.jsonnet > $(EXAMPLE_SYS_ACCOUNT_CFG_PATH)
	jsonnet -S $(EXAMPLE_SERVER_DIR)/syscore.jsonnet -V SYS_CORE_DB_ENCRYPT_KEY=$(EXAMPLE_SYS_CORE_DB_ENCRYPT_KEY) > $(EXAMPLE_SYS_CORE_CFG_PATH)

this-config-dep:
	cd $(EXAMPLE_SERVER_DIR) && jb install

this-config-delete:
	@echo Deleting previously generated config
	rm -rf $(EXAMPLE_SYS_CORE_CFG_PATH)
	rm -rf $(EXAMPLE_SYS_ACCOUNT_CFG_PATH)

this-build-delete:
	rm -rf ./bin-all

### RUN

this-sdk-run:
	$(SDK_BIN)

this-server-run:
	mkdir -p db
	rm -rf ./db/gcn.db && $(SERVER_BIN) -p $(EXAMPLE_SERVER_PORT) -a $(EXAMPLE_SYS_ACCOUNT_CFG_PATH) -c $(EXAMPLE_SYS_CORE_CFG_PATH)

this-example-sdk-auth-signup:
	@echo Running Example Register Client
	$(SDK_BIN) sys-account auth-service register --email $(EXAMPLE_EMAIL) --password $(EXAMPLE_PASSWORD) --password-confirm $(EXAMPLE_PASSWORD) --server-addr $(EXAMPLE_SERVER_ADDRESS)

this-example-sdk-auth-signin:
	@echo Running Example Login Client
	$(SDK_BIN) sys-account auth-service login --email $(EXAMPLE_EMAIL) --password $(EXAMPLE_PASSWORD) --server-addr $(EXAMPLE_SERVER_ADDRESS)

# gotten from "make this-example-sdk-auth"
# TODO: easy way to capture this ? Might have to set to ENV and then get from ENV when runnng this make target
# TODO: error: "command failed: grpc: the credentials require transport level security (use grpc.WithTransportCredentials() to set)"
#EXAMPLE_TOKEN=eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIiLCJyb2xlIjp7InJvbGUiOjF9LCJ1c2VyRW1haWwiOiJzdXBlcmFkbWluQGdldGNvdXJhZ2Vub3cub3JnIiwiZXhwIjoxNjAyOTEwODA4fQ.ppCcWFxLt1nWZMBz_I8d_O2E2eje0EKCsDwVRzXNcbFFBzDykdIEdXgtUGWp8oLi6jcfYaQygyAmlMuZVZ-Blg
this-example-sdk-accounts-list:
	@echo Running Example Accounts CRUD
	#$(SDK_BIN) sys-account account-service list-accounts --jwt-access-token $(EXAMPLE_TOKEN) --server-addr $(SERVER_ADDRESS) --tls-insecure-skip-verify
	$(SDK_BIN) sys-account account-service list-accounts --server-addr $(EXAMPLE_SERVER_ADDRESS) --

this-ex-sdk-bench: this-ex-sdk-bench-start this-ex-sdk-bench-01 this-ex-sdk-bench-02
	@echo -- Example SDK Benchmark: End --

this-ex-sdk-bench-start: 
	@echo -- Example SDK Benchmark: Start --

	@echo Running Example SDK Benchmark, Run server first!
	
this-ex-sdk-bench-01:
	# Small
	@echo USERS: 10
	@echo DB CONNECTIONS: 1
	$(SDK_BIN) sys-bench -s $(EXAMPLE_SERVER_ADDRESS) -j "./bench/fake-register-data.json" -p "../sys-share/sys-account/proto/v2/sys_account_services.proto" -n "v2.sys_account.services.AuthService.Register" -r 10 -c 1


this-ex-sdk-bench-02:
	# Medium
	@echo USERS: 100
	@echo DB CONNECTIONS: 10
	$(SDK_BIN) sys-bench -s $(EXAMPLE_SERVER_ADDRESS) -j "./bench/fake-register-data.json" -p "../sys-share/sys-account/proto/v2/sys_account_services.proto" -n "v2.sys_account.services.AuthService.Register" -r 100 -c 10

this-ex-sdk-bench-03:
	# Medium
	@echo USERS: 1000
	@echo DB CONNECTIONS: 100
	$(SDK_BIN) sys-bench -s $(EXAMPLE_SERVER_ADDRESS) -j "./bench/fake-register-data.json" -p "../sys-share/sys-account/proto/v2/sys_account_services.proto" -n "v2.sys_account.services.AuthService.Register" -r 1000 -c 100
