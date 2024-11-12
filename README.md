# TenXLaunch

Allows launching tokens with free czusd liquidity up to $10k.

## Official Deployments

### v2

Network: BSC Testnet

| Contract                          | Address                                    |
| --------------------------------- | ------------------------------------------ |
| TenXLaunchViewV2                  | 0x44E70D023A8dAAE0253121Ce1e0eE3060EF81C75 |
| TenXLaunchV2                      | 0x00e746Aa67Cf111917BbAD6e070116e2832D65B6 |
| TenXSettingsV2                    | 0x6AEEe36069b881B536cA7d9761353ec2c2405B03 |
| TenXTokenFactoryV2                | 0xAA934798B1215d95A608C3082131Bf0234C90eaE |
| TenXBlacklistV2                   | 0xC324C1f146713b2d6ae6EcCa2DD4288c84D8018b |
| AmmZapV1                          | 0x4DF8F9bE759c54BeBA853056a9278c6118892652 |
| IterableArrayWithoutDuplicateKeys | 0x606E3cBB3fb84Ed08c31Cce44aB9A200F54A5630 |

### v1

TenXLaunch
BSC:0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22

TenXLaunchView
BSC:0xFaCC24759420c63DdD39650268cAc0AA582eb682

## build
forge build --via-ir

## deployment

Key variables are set in the script, and should be updated correctly for the network.

forge script script/v2/DeployTenXLaunch.s.sol:DeployTenXLaunch --broadcast --verify -vvv --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -i 1 --sender $DEPLOYER_ADDRESS
