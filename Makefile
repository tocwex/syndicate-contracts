-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil install \
        deploy-anvil-pk deploy-sepolia deploy-sepolia-ledger deploy-sepolia-wallet \
        check-env check-deployment verify

NETWORK_ARGS_ANVIL := --rpc-url 127.0.0.1:8545
NETWORK_ARGS_SEPOLIA := --rpc-url $(SEPOLIA_RPC_URL)

VERIFY_ARGS := --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

BASIC_ARGS := --broadcast -vvvv

check-env-anvil:
	@echo "Checking anvil environment variables..."
	@test -n "$(ANVIL_PRIVATE_KEY_0)" || (echo "ANVIL_PRIVATE_KEY_0 is required" && exit 1)


check-env-sepolia:
	@echo "Checking Sepolia environment variables..."
	@test -n "$(SEPOLIA_RPC_URL)" || (echo "SEPOLIA_RPC_URL is required" && exit 1)
	@test -n "$(ETHERSCAN_API_KEY)" || (echo "ETHERSCAN_API_KEY is required" && exit 1)

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build
build-warn:; forge build

test :; forge test -vvv --fork-url $(SEPOLIA_RPC_URL)
test-wip :; forge test -vvv --match-test WIP --fork-url $(SEPOLIA_RPC_URL)
test-vvvv :; forge test -vvvv --fork-url $(SEPOLIA_RPC_URL)
test-admin :; forge test -vvvv --match-test Size --fork-url $(SEPOLIA_RPC_URL)
	
snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy-anvil-pk: check-env-anvil
	@echo "Deploying to Anvil Devnet..."
	@echo "Using private keys..."
	@SIGNER_TYPE=private-key forge script script/DeploySyndicate.s.sol:DeploySyndicate $(NETWORK_ARGS_ANVIL) --private-key $(ANVIL_PRIVATE_KEY_0) $(BASIC_ARGS)


deploy-sepolia-pk: check-env-sepolia
	@echo "Deploying to Sepolia Testnet..."
	@echo "Using private keys..."
	@SIGNER_TYPE=private-key forge script script/DeploySyndicate.s.sol:DeploySyndicate $(NETWORK_ARGS_SEPOLIA) --private-key $(SEPOLIA_PRIVATE_KEY_0) $(VERIFY_ARGS) $(BASIC_ARGS)


deploy-sepolia-ledger: check-env-sepolia
	@echo "Deploying to Anvil Devnet..."
	@echo "Using ledger address $LEDGER_ADDRESS..."
	@echo "Please sign on ledger hardware wallet..."
	@SIGNER_TYPE=ledger forge script script/DeploySyndicate.s.sol:DeploySyndicate $(NETWORK_ARGS_SEPOLIA) --ledger --sender $(LEDGER_ADDRESS) $(VERIFY_ARGS) $(BASIC_ARGS)


# TODO Add addtional deployment types for contract wallet deployments
