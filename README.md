## TenXLaunch

Allows launching tokens with free czusd liquidity up to $10k.

## Official Deployments

TenXLaunch
BSC:0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22

TenXLaunchView
BSC:0xFaCC24759420c63DdD39650268cAc0AA582eb682

## deployment

The czusd, amm factory, and amm router addresses are hardcoded in the smart contracts.

forge script script/DeployTenXLaunch.s.sol:DeployTenXLaunch --broadcast --verify -vvv --rpc-url https://rpc.ankr.com/bsc --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
