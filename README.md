# TenXLaunch

Allows launching tokens with free czusd liquidity up to $10k.

## Official Deployments

### v2

Network: BSC Testnet

| Contract                          | Address                                    |
| --------------------------------- | ------------------------------------------ |
| TenXLaunchViewV2                  | 0xf93dC391a6B59195aAF275B7DC53C46ecAaa1B36 |
| TenXLaunchV2                      | 0xca611BdAeF106d508D5CceD0e387bbe7aB17566A |
| TenXSettingsV2                    | 0xd28c22d8194a33c90d98bCFe331EbfEe9d4fC1C9 |
| TenXTokenFactoryV2                | 0xFf2de94b54e96F8dbA8F0eC7EA64c5E51dFbE190 |
| TenXBlacklistV2                   | 0xf461DC79454cad65B0FBa4bf12219F0b484e3B35 |
| AmmZapV1                          | 0x42EeD5933EBBB64c61A6d858378E64Ac8FF566D1 |
| IterableArrayWithoutDuplicateKeys | 0xC968ce1792537290dceF639F8bc1dd1E48Cebc78 |

### v1

TenXLaunch
BSC:0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22

TenXLaunchView
BSC:0xFaCC24759420c63DdD39650268cAc0AA582eb682

## deployment

Key variables are set in the script, and should be updated correctly for the network.

forge script script/v2/DeployTenXLaunch.s.sol:DeployTenXLaunch --broadcast --verify -vvv --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
