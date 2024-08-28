// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXSettingsV2} from "./TenXSettings.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
/*
    TODO:
    add events
    */
contract TenXTokenV2 is
    ERC20,
    ERC20Permit,
    ERC20Burnable,
    AccessControlEnumerable
{
    mapping(address account => bool isExempt) public isExempt;
    //JPG, PNG, or SVG
    string public tokenLogoCID;
    //Guide: https://commonmark.org/help/
    //Upload to IPFS as .md file.
    string public descriptionMarkdownCID;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    TenXSettingsV2 public tenXSettings;

    address public ammCzusdPair;
    address public taxReceiver;

    uint16 private constant _BASIS = 10_000;

    uint16 public buyTax;
    uint16 public buyBurn;
    uint16 public sellTax;
    uint16 public sellBurn;
    uint16 public buyLpFee;
    uint16 public sellLpFee;
    uint16 public balanceMax;
    uint16 public transactionSizeMax;

    uint64 public launchTimestamp;

    error OverMax(uint256 amount, uint256 max);
    error BeforeCountdown(uint64 currentTimestamp, uint64 countdownTimestamp);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenLogoCID,
        string memory _descriptionMarkdownCID,
        TenXSettingsV2 _tenXSettings,
        uint256 _supply,
        address _taxReceiver,
        uint16 _buyTax,
        uint16 _buyBurn,
        uint16 _buyLpFee,
        uint16 _sellTax,
        uint16 _sellBurn,
        uint16 _sellLpFee,
        uint16 _balanceMax,
        uint16 _transactionSizeMax,
        uint64 _launchTimestamp
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tenXSettings = _tenXSettings;
        taxReceiver = _taxReceiver;
        isExempt[taxReceiver] = true;
        isExempt[msg.sender] = true;
        isExempt[address(this)] = true;

        ammCzusdPair = tenXSettings.ammFactory().createPair(
            address(this),
            address(tenXSettings.czusd())
        );
        _mint(msg.sender, _supply);

        tokenLogoCID = _tokenLogoCID;
        descriptionMarkdownCID = _descriptionMarkdownCID;

        buyTax = _buyTax;
        buyBurn = _buyBurn;
        buyLpFee = _buyLpFee;
        sellTax = _sellTax;
        sellBurn = _sellBurn;
        sellLpFee = _sellLpFee;
        balanceMax = _balanceMax;
        transactionSizeMax = _transactionSizeMax;
        launchTimestamp = _launchTimestamp;

        _revertIfTaxTooHigh();
        _revertIfBalanceMaxOutOfRange();
        _revertIfTransactionSizeMaxOutOfRange();
        tenXSettings.blacklist().revertIfAccountBlacklisted(taxReceiver);
        uint64 maxLaunchTimestamp = uint64(block.timestamp) +
            tenXSettings.launchTimestampCap();
        if (launchTimestamp != 0 && launchTimestamp > maxLaunchTimestamp) {
            revert TenXSettingsV2.OverCap(launchTimestamp, maxLaunchTimestamp);
        }
    }

    function ADMIN_setTenXSettings(
        TenXSettingsV2 _tenXSettings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tenXSettings = _tenXSettings;
    }

    function ADMIN_setAmmCzusdPair(
        address _ammCzusdPair
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ammCzusdPair = _ammCzusdPair;
    }

    function ADMIN_swapAndLiquify() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _swapAndLiquify();
    }

    function MANAGER_setTaxes(
        uint16 _buyTax,
        uint16 _buyBurn,
        uint16 _buyLpFee,
        uint16 _sellTax,
        uint16 _sellBurn,
        uint16 _sellLpFee
    ) external onlyRole(MANAGER_ROLE) {
        buyTax = _buyTax;
        buyBurn = _buyBurn;
        buyLpFee = _buyLpFee;
        sellTax = _sellTax;
        sellBurn = _sellBurn;
        sellLpFee = _sellLpFee;
        _revertIfTaxTooHigh();
    }

    function MANAGER_setMaxes(
        uint16 _balanceMax,
        uint16 _transactionSizeMax
    ) external onlyRole(MANAGER_ROLE) {
        balanceMax = _balanceMax;
        transactionSizeMax = _transactionSizeMax;
        _revertIfBalanceMaxOutOfRange();
        _revertIfTransactionSizeMaxOutOfRange();
    }

    function MANAGER_setTaxReceiver(
        address _taxReceiver
    ) external onlyRole(MANAGER_ROLE) {
        taxReceiver = _taxReceiver;
        isExempt[taxReceiver] = true;
        tenXSettings.blacklist().revertIfAccountBlacklisted(taxReceiver);
    }

    function MANAGER_setIsExempt(
        address _account,
        bool _isExempt
    ) external onlyRole(MANAGER_ROLE) {
        isExempt[_account] = _isExempt;
    }

    //JPG, PNG, SVG
    function MANAGER_setTokenLogoCID(
        string calldata _tokenLogoCID
    ) external onlyRole(MANAGER_ROLE) {
        tokenLogoCID = _tokenLogoCID;
    }

    //Guide: https://www.markdownguide.org/cheat-sheet/
    //Upload to IPFS as .md file.
    function MANAGER_setDescriptionMarkdownCID(
        string calldata _descriptionMarkdownCID
    ) external onlyRole(MANAGER_ROLE) {
        descriptionMarkdownCID = _descriptionMarkdownCID;
    }

    function _revertIfTaxTooHigh() internal view {
        uint16 totalTax = buyTax +
            buyBurn +
            buyLpFee +
            sellTax +
            sellBurn +
            sellLpFee;

        if (totalTax > tenXSettings.taxesTotalCap()) {
            revert TenXSettingsV2.OverCap(
                totalTax,
                tenXSettings.taxesTotalCap()
            );
        }
    }

    function _revertIfBalanceMaxOutOfRange() internal view {
        if (balanceMax > tenXSettings.balanceCap()) {
            revert TenXSettingsV2.OverCap(
                balanceMax,
                tenXSettings.balanceCap()
            );
        }
        if (balanceMax < tenXSettings.balanceFloor()) {
            revert TenXSettingsV2.UnderFloor(
                balanceMax,
                tenXSettings.balanceFloor()
            );
        }
    }

    function _revertIfTransactionSizeMaxOutOfRange() internal view {
        if (transactionSizeMax > tenXSettings.transactionSizeCap()) {
            revert TenXSettingsV2.OverCap(
                transactionSizeMax,
                tenXSettings.transactionSizeCap()
            );
        }
        if (transactionSizeMax < tenXSettings.transactionSizeFloor()) {
            revert TenXSettingsV2.UnderFloor(
                transactionSizeMax,
                tenXSettings.transactionSizeFloor()
            );
        }
    }

    //Overrides _update on mint, burn, transfer to handle taxes.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        TenXBlacklistV2 blacklist = tenXSettings.blacklist();
        blacklist.revertIfAccountBlacklisted(address(this));
        blacklist.revertIfAccountBlacklisted(from);
        blacklist.revertIfAccountBlacklisted(to);
        if (
            (from != ammCzusdPair && to != ammCzusdPair) || //not a buy or sell
            from == address(0) ||
            to == address(0) ||
            value == 0 ||
            isExempt[from] ||
            isExempt[to]
        ) {
            //Default behavior for mints, burns, exempt, transfers
            super._update(from, to, value);
        } else {
            _updateStandardWallet(from, to, value);
        }

        _revertIfStandardWalletAndOverMaxHolding(from);
        _revertIfStandardWalletAndOverMaxHolding(to);

        //If theres enough tokens available, swap to LP
        //Can also be done manually by admin
        if (
            balanceOf(address(this)) >=
            (tenXSettings.swapLiquifyAt() * totalSupply()) / _BASIS
        ) {
            _swapAndLiquify();
        }
    }

    function _updateStandardWallet(
        address from,
        address to,
        uint256 value
    ) internal {
        //Revert if transaction is too large
        if (value > transactionSizeMax) {
            revert OverMax(value, transactionSizeMax);
        }
        //Revert if trading isnt open yet for public.
        if (launchTimestamp != 0 && block.timestamp < launchTimestamp) {
            revert BeforeCountdown(uint64(block.timestamp), launchTimestamp);
        }
        //Tax and burn for buys, sells
        uint256 taxWad;
        uint256 burnWad;
        uint256 lpWad;
        if (from == ammCzusdPair) {
            //buy taxes
            taxWad += (value * buyTax) / _BASIS;
            burnWad += (value * buyBurn) / _BASIS;
            lpWad += (value * buyLpFee) / _BASIS;
        }
        if (to == ammCzusdPair) {
            //sell taxes
            taxWad += (value * sellTax) / _BASIS;
            burnWad += (value * sellBurn) / _BASIS;
            lpWad += (value * buyLpFee) / _BASIS;
        }

        if (taxWad > 0) super._update(from, taxReceiver, taxWad);
        if (burnWad > 0) super._update(from, address(0), burnWad);
        if (lpWad > 0) super._update(from, address(this), lpWad);

        super._update(from, to, value - taxWad - burnWad - lpWad);
    }

    function _revertIfStandardWalletAndOverMaxHolding(
        address wallet
    ) internal view {
        if (
            wallet != ammCzusdPair &&
            wallet != address(0) &&
            !isExempt[wallet] &&
            balanceOf(wallet) > balanceMax
        ) {
            revert OverMax(balanceOf(wallet), balanceMax);
        }
    }

    function _swapAndLiquify() private {
        uint256 bal = balanceOf(address(this));

        address czusd = address(tenXSettings.czusd());
        IAmmRouter02 router = tenXSettings.ammRouter();

        uint256 tokens = bal / 2;
        uint256 toSwap = bal - tokens;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = czusd;

        // Swap toSwap of address(this) to czusd
        approve(address(router), toSwap);
        router.swapExactTokensForTokens(
            toSwap,
            0, // accept any amount of czusd
            path,
            address(this),
            block.timestamp
        );
        uint256 czusdBal = IERC20(czusd).balanceOf(address(this));

        // Add liquidity and burn it
        approve(address(router), tokens);
        IERC20(czusd).approve(address(router), czusdBal);
        router.addLiquidity(
            czusd,
            address(this),
            czusdBal,
            tokens,
            0,
            0,
            address(0x0),
            block.timestamp
        );
    }
}