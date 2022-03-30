# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
# change ETH_RPC_URL to another one (e.g., FTM_RPC_URL) for different chains
build  :; forge build
test   :; forge test -vv --fork-url ${ETH_RPC_URL} 
trace   :; forge test -vvv --fork-url ${ETH_RPC_URL}
# local tests without fork
test-local  :; forge test
trace-local  :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot