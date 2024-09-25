# TenXLaunch

Allows launching tokens with free czusd liquidity up to $10k.

## Official Deployments

### v2

Network: BSC Testnet

| Contract                          | Address                                    |
| --------------------------------- | ------------------------------------------ |
| TenXLaunchViewV2                  | 0x7dc2F4B81846Af198D5E8d94c6E013B98E9C6Cba |
| TenXLaunchV2                      | 0xB959E7D27fe1A44A0315D5c134D2BbA3E0c1246f |
| TenXSettingsV2                    | 0x1C6ca5e2B2a41aF0C4bF781D43D5A31AFaB4EdaF |
| TenXTokenFactoryV2                | 0x2dDEBc1B2726D2A4Df89946c7a26C96A3a63b51D |
| TenXBlacklistV2                   | 0xf06AE5E56dB54004C0a166240A5c0CfcC6dfcd45 |
| AmmZapV1                          | 0xdC119Ed4a4F921BDDC63adE95809F06f35345381 |
| IterableArrayWithoutDuplicateKeys | 0xD0D0B3a423f6c76648EfcF6b4892AD60d2f2eF48 |

### v1

TenXLaunch
BSC:0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22

TenXLaunchView
BSC:0xFaCC24759420c63DdD39650268cAc0AA582eb682

## deployment

Key variables are set in the script, and should be updated correctly for the network.

forge script script/v2/DeployTenXLaunch.s.sol:DeployTenXLaunch --broadcast --verify -vvv --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
