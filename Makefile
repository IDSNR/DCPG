-include .env

deploy_to_test:; forge script script/Deploy.s.sol:DeployScript --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv
test_sepolia:; forge test --fork-url $(SEPOLIA_RPC_URL) -vvvvvvv
cover:; forge coverage --fork-url $(SEPOLIA_RPC_URL) -vvvvvvv