// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {ERC20BurnMintMock} from "../mocks/ERC20BurnMintMock.sol";

import {WETH} from "../../src/amm/lib/WETH.sol";
import {AmmFactory} from "../../src/amm/AmmFactory.sol";
import {AmmRouter} from "../../src/amm/AmmRouter02.sol";
import {AmmZapV1} from "../../src/amm/AmmZapV1.sol";

import {TenXTokenV2} from "../../src/v2/TenXToken.sol";
import {TenXSettingsV2} from "../../src/v2/TenXSettings.sol";
import {TenXBlacklistV2} from "../../src/v2/TenXBlacklist.sol";
import {TenXLaunchV2} from "../../src/v2/TenXLaunch.sol";

contract TestTenXLaunchV2 is Test {
    address public governance;
    WETH public weth;
    AmmFactory public ammFactory;
    AmmRouter public ammRouter;
    ERC20BurnMintMock public czusd;
    TenXSettingsV2 public tenXSettings;
    TenXBlacklistV2 public tenXBlacklist;
    TenXLaunchV2 public tenXLaunch;

    function setUp() public {
        governance = makeAddr("governance");
        weth = new WETH();
        ammFactory = new AmmFactory(address(this));
        ammRouter = new AmmRouter(address(ammFactory), address(weth));
        AmmZapV1 ammZap = new AmmZapV1(address(weth), address(ammRouter), 50);

        czusd = new ERC20BurnMintMock("Czodiac Usd", "CZUSD");

        tenXBlacklist = new TenXBlacklistV2();
        tenXSettings = new TenXSettingsV2(
            governance,
            tenXBlacklist,
            czusd,
            ammRouter,
            ammFactory,
            ammZap
        );

        tenXLaunch = new TenXLaunchV2(tenXSettings);
    }

    function test_constructor() public {
        assertEq(address(tenXLaunch.tenXSettings()), address(tenXSettings));
        assertTrue(
            tenXLaunch.hasRole(tenXLaunch.DEFAULT_ADMIN_ROLE(), address(this))
        );
        assertTrue(
            tenXLaunch.hasRole(tenXLaunch.DEFAULT_ADMIN_ROLE(), governance)
        );
    }
}
