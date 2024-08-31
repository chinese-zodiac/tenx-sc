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

contract TestTenXTokenV2 is Test {
    address public governance;
    WETH public weth;
    AmmFactory public ammFactory;
    AmmRouter public ammRouter;
    ERC20BurnMintMock public czusd;
    TenXSettingsV2 public tenXSettings;
    TenXBlacklistV2 public tenXBlacklist;

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
    function test_constructorReverts() public {
        address taxReceiver = makeAddr("taxReceiver");
        uint64 launchTimestamp = uint64(block.timestamp + 1 days);
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                30_00,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            5_00, //uint16 _buyTax,
            5_00, //uint16 _buyBurn,
            5_00, //uint16 _buyLpFee,
            5_00, //uint16 _sellTax,
            5_00, //uint16 _sellBurn,
            5_00, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                29_00,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            2_00, //uint16 _buyBurn,
            3_00, //uint16 _buyLpFee,
            5_00, //uint16 _sellTax,
            7_00, //uint16 _sellBurn,
            11_00, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            20_01, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            20_01, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            20_01, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            20_01, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            20_01, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                20_01,
                tenXSettings.taxesTotalCap()
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            20_01, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                10_001 ether,
                10_000 ether
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_001 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                10_001 ether,
                10_000 ether
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_000 ether, //uint256 _balanceMax,
            10_001 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.UnderFloor.selector,
                0.99 ether,
                1 ether
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            0.99 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.UnderFloor.selector,
                0.99 ether,
                1 ether
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            0.99 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        tenXBlacklist.grantRole(
            tenXSettings.blacklist().BLACKLISTER_ROLE(),
            address(this)
        );
        address[] memory addressList = new address[](1);
        addressList[0] = taxReceiver;
        tenXBlacklist.BLACKLISTER_addAccountBlacklist(addressList);
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXBlacklistV2.Blacklisted.selector,
                taxReceiver
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        tenXBlacklist.BLACKLISTER_delAccountBlacklist(addressList);
        address blacklistedAccount = makeAddr("blacklistedAccount");
        addressList[0] = blacklistedAccount;
        tenXBlacklist.BLACKLISTER_addAccountBlacklist(addressList);
        vm.startPrank(blacklistedAccount);
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXBlacklistV2.Blacklisted.selector,
                blacklistedAccount
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        vm.stopPrank();
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXBlacklistV2.Blacklisted.selector,
                blacklistedAccount
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            blacklistedAccount, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            launchTimestamp //uint64 _launchTimestamp
        );
        uint64 badLaunchTimestamp = uint64(block.timestamp + 91 days);
        uint64 maxLaunchTimestamp = uint64(block.timestamp + 90 days);
        vm.expectRevert(
            abi.encodeWithSelector(
                TenXSettingsV2.OverCap.selector,
                badLaunchTimestamp,
                maxLaunchTimestamp
            )
        );
        new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            0, //uint16 _buyTax,
            0, //uint16 _buyBurn,
            0, //uint16 _buyLpFee,
            0, //uint16 _sellTax,
            0, //uint16 _sellBurn,
            0, //uint16 _sellLpFee,
            badLaunchTimestamp //uint64 _launchTimestamp
        );
    }

    function test_addLiqExempt() public {
        address taxReceiver = makeAddr("taxReceiver");
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
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 20_000 ether);
        czusd.approve(address(ammRouter), 10_000 ether);
        token.approve(address(ammRouter), 10_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );

        assertEq(token.balanceOf(token.ammCzusdPair()), 10_000 ether);
        assertEq(czusd.balanceOf(token.ammCzusdPair()), 10_000 ether);
    }

    function test_buyExempt() public {
        address taxReceiver = makeAddr("taxReceiver");
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
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 20_000 ether);
        czusd.approve(address(ammRouter), 20_000 ether);
        token.approve(address(ammRouter), 20_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = address(czusd);
        path[1] = address(token);
        ammRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0.99 ether,
            path,
            address(this),
            block.timestamp
        );

        assertEq(1 ether, 10_000 ether - czusd.balanceOf(address(this)));
        assertApproxEqRel(
            0.9975 ether,
            token.balanceOf(address(this)),
            0.0001 ether
        );
    }

    function test_buyTaxed() public {
        address taxReceiver = makeAddr("taxReceiver");
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
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 20_000 ether);
        czusd.approve(address(ammRouter), 20_000 ether);
        token.approve(address(ammRouter), 20_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = address(czusd);
        path[1] = address(token);

        address trader1 = makeAddr("trader1");
        czusd.mint(trader1, 10_000 ether);

        vm.startPrank(trader1);
        czusd.approve(address(ammRouter), 10_000 ether);
        ammRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0.95 ether,
            path,
            trader1,
            block.timestamp
        );
        vm.stopPrank();

        uint256 expectedTokenBoughtApprox = 0.9975 ether;
        uint256 expectedTokenTaxed = (expectedTokenBoughtApprox * 1_00) /
            10_000;
        uint256 expectedTokenBurned = (expectedTokenBoughtApprox * 1_25) /
            10_000;
        uint256 expectedTokenLpFee = (expectedTokenBoughtApprox * 1_50) /
            10_000;
        uint256 expectedTokenReceived = expectedTokenBoughtApprox -
            expectedTokenTaxed -
            expectedTokenBurned -
            expectedTokenLpFee;

        uint256 tax = token.balanceOf(address(taxReceiver));
        uint256 burn = 10_000 ether - token.totalSupply();
        uint256 lpFee = token.balanceOf(address(token));
        uint256 tokenReceived = token.balanceOf(trader1);

        assertFalse(token.isExempt(trader1));
        assertEq(1 ether, 10_000 ether - czusd.balanceOf(address(trader1)));
        assertApproxEqRel(
            0.9975 ether,
            tokenReceived + tax + burn + lpFee,
            0.0001 ether
        );
        assertApproxEqRel(expectedTokenTaxed, tax, 0.0001 ether);
        assertApproxEqRel(expectedTokenBurned, burn, 0.0001 ether);
        assertApproxEqRel(expectedTokenLpFee, lpFee, 0.0001 ether);
        assertApproxEqRel(expectedTokenReceived, tokenReceived, 0.0001 ether);
    }

    function test_sellExempt() public {
        address taxReceiver = makeAddr("taxReceiver");
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            5_000 ether, //uint256 _balanceMax,
            250 ether, //uint256 _transactionSizeMax,
            20_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 10_000 ether);
        czusd.approve(address(ammRouter), 20_000 ether);
        token.approve(address(ammRouter), 20_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(czusd);
        ammRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0.99 ether,
            path,
            address(this),
            block.timestamp
        );

        assertEq(1 ether, 10_000 ether - token.balanceOf(address(this)));
        assertApproxEqRel(
            0.9975 ether,
            czusd.balanceOf(address(this)),
            0.0001 ether
        );
    }

    function test_sellTaxed() public {
        address taxReceiver = makeAddr("taxReceiver");
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_000 ether, //uint256 _balanceMax,
            10_000 ether, //uint256 _transactionSizeMax,
            20_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 10_000 ether);
        czusd.approve(address(ammRouter), 20_000 ether);
        token.approve(address(ammRouter), 20_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(czusd);

        address trader1 = makeAddr("trader1");
        token.transfer(trader1, 10_000 ether);

        vm.startPrank(trader1);
        token.approve(address(ammRouter), 10_000 ether);
        ammRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0.9 ether,
            path,
            trader1,
            block.timestamp
        );
        vm.stopPrank();

        uint256 expectedCzusdBoughtApprox = 0.9975 ether;
        uint256 expectedTokenTaxed = (1 ether * 2_00) / 10_000;
        uint256 expectedTokenBurned = (1 ether * 2_25) / 10_000;
        uint256 expectedTokenLpFee = (1 ether * 2_50) / 10_000;
        uint256 expectedCzusdReceived = expectedCzusdBoughtApprox -
            expectedTokenTaxed -
            expectedTokenBurned -
            expectedTokenLpFee;

        uint256 tax = token.balanceOf(address(taxReceiver));
        uint256 burn = 20_000 ether - token.totalSupply();
        uint256 lpFee = token.balanceOf(address(token));
        uint256 czusdReceived = czusd.balanceOf(trader1);

        assertFalse(token.isExempt(trader1));
        assertEq(1 ether, 10_000 ether - token.balanceOf(address(trader1)));
        assertApproxEqRel(
            0.9975 ether,
            czusdReceived + tax + burn + lpFee,
            0.001 ether
        );
        assertApproxEqRel(expectedTokenTaxed, tax, 0.0001 ether);
        assertApproxEqRel(expectedTokenBurned, burn, 0.0001 ether);
        assertApproxEqRel(expectedTokenLpFee, lpFee, 0.0001 ether);
        assertApproxEqRel(expectedCzusdReceived, czusdReceived, 0.001 ether);
    }

    function test_zap() public {
        address taxReceiver = makeAddr("taxReceiver");
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_000 ether, //uint256 _balanceMax,
            10_000 ether, //uint256 _transactionSizeMax,
            20_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        czusd.mint(address(this), 10_000 ether);
        czusd.approve(address(ammRouter), 20_000 ether);
        token.approve(address(ammRouter), 20_000 ether);
        ammRouter.addLiquidity(
            address(czusd),
            address(token),
            10_000 ether,
            10_000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );

        token.transfer(address(token), 2 ether);

        assertApproxEqRel(
            10_002 ether,
            token.balanceOf(token.ammCzusdPair()),
            0.0000001 ether
        );
    }

    function test_adminMethodAccessControlReverts() public {
        address notAdmin = makeAddr("notAdmin");
        address manager = makeAddr("manager");
        address taxReceiver = makeAddr("taxReceiver");
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_000 ether, //uint256 _balanceMax,
            10_000 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        token.grantRole(token.MANAGER_ROLE(), manager);

        vm.startPrank(notAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notAdmin,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_setAmmCzusdPair(address(0x0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notAdmin,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_setTenXSettings(TenXSettingsV2(address(0x0)));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notAdmin,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_zap();
        vm.stopPrank();

        vm.startPrank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                manager,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_setAmmCzusdPair(address(0x0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                manager,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_setTenXSettings(TenXSettingsV2(address(0x0)));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                manager,
                token.DEFAULT_ADMIN_ROLE()
            )
        );
        token.ADMIN_zap();
        vm.stopPrank();
    }

    function test_managerMethodAccessControlReverts() public {
        address notManager = makeAddr("notManager");
        address admin = makeAddr("admin");
        address taxReceiver = makeAddr("taxReceiver");
        TenXTokenV2 token = new TenXTokenV2(
            "TestX", //string memory _name,
            "TX", //string memory _symbol,
            "bafkreigzyrltrxv44gajay5ohmzz7ys2b3ybtkitfy4aojjhkawvfdc7gm", //string memory _tokenLogoCID,
            "bafybeiferzfrkmoemcegmqtyccgbb5rrez6u2md4xmwsbwglz6ey4d4mgu", //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            10_000 ether, //uint256 _balanceMax,
            10_000 ether, //uint256 _transactionSizeMax,
            10_000 ether, //uint256 _supply,
            taxReceiver, //address _taxReceiver,
            1_00, //uint16 _buyTax,
            1_25, //uint16 _buyBurn,
            1_50, //uint16 _buyLpFee,
            2_00, //uint16 _sellTax,
            2_25, //uint16 _sellBurn,
            2_50, //uint16 _sellLpFee,
            0 //uint64 _launchTimestamp
        );
        token.grantRole(token.DEFAULT_ADMIN_ROLE(), admin);

        vm.startPrank(notManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setDescriptionMarkdownCID("");
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setIsExempt(address(0x0), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setMaxes(0, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTaxes(0, 0, 0, 0, 0, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTaxReceiver(address(0x0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                notManager,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTokenLogoCID("");
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setDescriptionMarkdownCID("");
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setIsExempt(address(0x0), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setMaxes(0, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTaxes(0, 0, 0, 0, 0, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTaxReceiver(address(0x0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                token.MANAGER_ROLE()
            )
        );
        token.MANAGER_setTokenLogoCID("");
        vm.stopPrank();
    }
}
