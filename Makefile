# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
# change ETH_RPC_URL to another one (e.g., FTM_RPC_URL) for different chains
FORK_URL := ${ETH_RPC_URL} 
build  :; forge build
test   :; forge test -vv --fork-url ${FORK_URL}
trace   :; forge test -vvv --fork-url ${FORK_URL}
test-contract :; forge test -vv --fork-url ${FORK_URL} --match-contract $(contract)
trace-contract :; forge test -vvv --fork-url ${FORK_URL} --match-contract $(contract)
# local tests without fork
test-local  :; forge test
trace-local  :; forge test -vvv
clean  :; forge clean
snapshot :; forge snapshot