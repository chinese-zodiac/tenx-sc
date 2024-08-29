// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {ERC20BurnMintMock} from "../mocks/ERC20BurnMintMock.sol";

import {WETH} from "../../src/amm/lib/WETH.sol";
import {AmmFactory} from "../../src/amm/AmmFactory.sol";
import {AmmRouter} from "../../src/amm/AmmRouter02.sol";

import {TenXTokenV2} from "../../src/v2/TenXToken.sol";
import {TenXSettingsV2} from "../../src/v2/TenXSettings.sol";
import {TenXBlacklistV2} from "../../src/v2/TenXBlacklist.sol";

contract TestTenXTokenV2 is Test {
    WETH public weth;
    AmmFactory public ammFactory;
    AmmRouter public ammRouter;
    ERC20BurnMintMock public czusd;
    TenXSettingsV2 public tenXSettings;
    TenXBlacklistV2 public tenXBlacklist;

    function setUp() public {
        weth = new WETH();
        ammFactory = new AmmFactory(address(this));
        ammRouter = new AmmRouter(address(ammFactory), address(weth));

        czusd = new ERC20BurnMintMock("Czodiac Usd", "CZUSD");

        tenXBlacklist = new TenXBlacklistV2();
        tenXSettings = new TenXSettingsV2(
            tenXBlacklist,
            czusd,
            ammRouter,
            ammFactory
        );
    }

    function test_constructorSetupStandard() public {
        address taxReceiver = makeAddr("taxReceiver");
        uint64 launchTimestamp = uint64(block.timestamp + 1 days);
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1, //uint16 _buyTax,
            2, //uint16 _buyBurn,
            3, //uint16 _buyLpFee,
            4, //uint16 _sellTax,
            5, //uint16 _sellBurn,
            6, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );

        assertEq("TestX", token.name());
        assertEq(
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm",
            token.tokenLogoCID()
        );
        assertEq(
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu",
            token.descriptionMarkdownCID()
        );
        assertEq(address(tenXSettings), address(token.tenXSettings()));
        assertEq(10_000 ether, token.totalSupply());
        assertEq(taxReceiver, token.taxReceiver());
        assertEq(1, token.buyTax());
        assertEq(2, token.buyBurn());
        assertEq(3, token.buyLpFee());
        assertEq(4, token.sellTax());
        assertEq(5, token.sellBurn());
        assertEq(6, token.sellLpFee());
        assertEq(5_000 ether, token.balanceMax());
        assertEq(250 ether, token.transactionSizeMax());
        assertEq(launchTimestamp, token.launchTimestamp());

        assertTrue(token.isExempt(taxReceiver));
        assertTrue(token.isExempt(address(this)));
        assertTrue(token.isExempt(address(token)));

        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));

        assertEq(token.balanceOf(address(this)), 10_000 ether);

        assertEq(
            ammFactory.getPair(address(czusd), address(token)),
            token.ammCzusdPair()
        );
    }
}
