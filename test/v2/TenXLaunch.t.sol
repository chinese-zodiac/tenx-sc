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
import {TenXTokenFactoryV2} from "../../src/v2/TenXTokenFactory.sol";
import {TenXLaunchV2} from "../../src/v2/TenXLaunch.sol";

contract TestTenXLaunchV2 is Test {
    address public governance;
    WETH public weth;
    AmmFactory public ammFactory;
    AmmRouter public ammRouter;
    ERC20BurnMintMock public czusd;
    TenXSettingsV2 public tenXSettings;
    TenXBlacklistV2 public tenXBlacklist;
    TenXTokenFactoryV2 public tenXTokenFactory;
    TenXLaunchV2 public tenXLaunch;

    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function setUp() public {
        governance = makeAddr("governance");
        weth = new WETH();
        ammFactory = new AmmFactory(address(this));
        ammRouter = new AmmRouter(address(ammFactory), address(weth));
        AmmZapV1 ammZap = new AmmZapV1(address(weth), address(ammRouter), 50);

        czusd = new ERC20BurnMintMock("Czodiac Usd", "CZUSD");

        tenXBlacklist = new TenXBlacklistV2();
        tenXTokenFactory = new TenXTokenFactoryV2();
        tenXSettings = new TenXSettingsV2(
            governance,
            tenXBlacklist,
            tenXTokenFactory,
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

    function test_launchToken() public {
        address taxReceiver = makeAddr("taxReceiver");
        uint64 launchTimestamp = uint64(block.timestamp);
        tenXLaunch.launchToken(
            5_000 ether,
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            2_00, //uint16 _buyBurn,
            3_00, //uint16 _buyLpFee,
            4_00, //uint16 _sellTax,
            5_00, //uint16 _sellBurn,
            6_00, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );

        TenXTokenV2 token = tenXLaunch.launchedTokenAt(0);
        address ammCzusdPair = token.ammCzusdPair();

        assertEq(tenXLaunch.launchedTokensCount(), 1);
        assertEq(czusd.balanceOf(ammCzusdPair), 5_000 ether);
        assertEq(token.balanceOf(ammCzusdPair), 5_000 ether);
        assertEq(token.launchTimestamp(), launchTimestamp);
        assertEq(token.name(), "TestX");
        assertEq(token.symbol(), "TX");
        assertEq(
            token.tokenLogoCID(),
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm"
        );
        assertEq(
            token.descriptionMarkdownCID(),
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu"
        );
        assertEq(token.balanceMax(), 5_000 ether);
        assertEq(token.transactionSizeMax(), 250 ether);
        assertEq(token.taxReceiver(), taxReceiver);
        assertEq(1_00, token.buyTax());
        assertEq(2_00, token.buyBurn());
        assertEq(3_00, token.buyLpFee());
        assertEq(4_00, token.sellTax());
        assertEq(5_00, token.sellBurn());
        assertEq(6_00, token.sellLpFee());

        assertTrue(token.isExempt(taxReceiver));
        assertTrue(token.isExempt(address(tenXLaunch)));
        assertTrue(token.isExempt(address(token)));

        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), governance));
        assertFalse(
            token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(tenXLaunch))
        );
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), taxReceiver));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));

        assertTrue(token.hasRole(MANAGER_ROLE, address(this)));
        assertFalse(token.hasRole(MANAGER_ROLE, address(tenXLaunch)));

        assertEq(token.getRoleMemberCount(token.DEFAULT_ADMIN_ROLE()), 1);
        assertEq(token.getRoleMemberCount(MANAGER_ROLE), 1);

        assertEq(tenXLaunch.czusdGrant(address(token)), 5_000 ether);
    }

    function test_constructorReverts() public {
        address taxReceiver = makeAddr("taxReceiver");

        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                10_001 ether,
                tenXSettings.czusdGrantCap()
            )
        );
        tenXLaunch.launchToken(
            10_001 ether,
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            2_00, //uint16 _buyBurn,
            3_00, //uint16 _buyLpFee,
            4_00, //uint16 _sellTax,
            5_00, //uint16 _sellBurn,
            6_00, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.UnderFloor.selector,
                4_999 ether,
                tenXSettings.czusdGrantFloor()
            )
        );
        tenXLaunch.launchToken(
            4_999 ether,
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            1_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            2_00, //uint16 _buyBurn,
            3_00, //uint16 _buyLpFee,
            4_00, //uint16 _sellTax,
            5_00, //uint16 _sellBurn,
            6_00, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        tenXBlacklist.grantRole(
            tenXSettings.blacklist().BLACKLISTER_ROLE(),
            address(this)
        );
        address[] memory addressList = new address[](1);
        address blacklisted = makeAddr("blacklisted");
        addressList[0] = blacklisted;
        tenXBlacklist.BLACKLISTER_addAccountBlacklist(addressList);
        vm.startPrank(blacklisted);
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXBlacklistV2.Blacklisted.selector,
                blacklisted
            )
        );
        tenXLaunch.launchToken(
            5_000 ether,
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            1_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            2_00, //uint16 _buyBurn,
            3_00, //uint16 _buyLpFee,
            4_00, //uint16 _sellTax,
            5_00, //uint16 _sellBurn,
            6_00, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
    }
}
