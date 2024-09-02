// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {IAmmFactory} from "../../src/interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../../src/interfaces/IAmmRouter02.sol";
import {IERC20Mintable} from "../../src/interfaces/IERC20Mintable.sol";
import {AmmZapV1} from "../../src/amm/AmmZapV1.sol";
import {TenXSettingsV2} from "../../src/v2/TenXSettings.sol";
import {TenXBlacklistV2} from "../../src/v2/TenXBlacklist.sol";
import {TenXTokenFactoryV2} from "../../src/v2/TenXTokenFactory.sol";
import {TenXLaunchV2} from "../../src/v2/TenXLaunch.sol";
import {TenXLaunchViewV2} from "../../src/v2/TenXLaunchView.sol";

contract DeployTenXLaunch is Script {
    function run() public {
        vm.startBroadcast();

        ///*
        //BSC TESTNET
        address governance = address(
            0xfcD9F2d36f7315d2785BA19ca920B14116EA3451
        );
        IAmmRouter02 router = IAmmRouter02(
            address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)
        );
        AmmZapV1 zap = new AmmZapV1(router.WETH(), address(router), 50);
        IAmmFactory factory = IAmmFactory(
            address(0x6725F303b657a9451d8BA641348b6761A6CC7a17)
        );
        IERC20Mintable czusd = IERC20Mintable(
            address(0x2af880f34F479506Fa8001F13c4c0d7e126A290B)
        );

        //*/

        /*
        //BSC MAINNET
        address governance = address(
            0x745A676C5c472b50B50e18D4b59e9AeEEc597046
        );
        AmmZapV1 zap = AmmZapV1(
            address(0xD4c4a7C55c9f7B3c48bafb6E8643Ba79F42418dF)
        );
        IAmmRouter02 router = IAmmRouter02(
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E)
        );
        IAmmFactory factory = IAmmFactory(
            address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)
        );
        IERC20Mintable czusd = IERC20Mintable(
            address(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70)
        );
        */

        TenXBlacklistV2 blacklist = new TenXBlacklistV2();
        TenXTokenFactoryV2 tokenFactory = new TenXTokenFactoryV2();
        TenXSettingsV2 settings = new TenXSettingsV2(
            governance, //address _governance,
            blacklist, //TenXBlacklistV2 _blacklist,
            tokenFactory, //TenXTokenFactoryV2 _tokenFactory,
            czusd, //IERC20Mintable _czusd,
            router, //IAmmRouter02 _ammRouter,
            factory, //IAmmFactory _ammFactory,
            zap //AmmZapV1 _ammZapV1
        );
        TenXLaunchV2 tenXLaunch = new TenXLaunchV2(settings);
        new TenXLaunchViewV2(tenXLaunch);

        //POST: Request governance to grant czusd MINTER_ROLE to tenXLaunch

        vm.stopBroadcast();
    }
}
