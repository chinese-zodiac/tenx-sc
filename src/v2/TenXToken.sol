// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXSettingsV2} from "./TenXSettings.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {AmmZapV1} from "../amm/AmmZapV1.sol";

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

    uint256 public immutable INITIAL_SUPPLY;

    uint256 public balanceMax;
    uint256 public transactionSizeMax;

    TenXSettingsV2 internal tenXSettings;

    address public ammCzusdPair;
    address public taxReceiver;

    uint16 private constant _BASIS = 10_000;

    uint16 public buyTax;
    uint16 public buyBurn;
    uint16 public sellTax;
    uint16 public sellBurn;
    uint16 public buyLpFee;
    uint16 public sellLpFee;

    uint64 public launchTimestamp;

    uint256 public totalTaxWad;
    uint256 public totalBurnWad;
    uint256 public totalLpWad;

    error OverMax(uint256 amount, uint256 max);
    error BeforeCountdown(uint64 currentTimestamp, uint64 countdownTimestamp);

    event SetTaxes(
        uint16 buyTax,
        uint16 buyBurn,
        uint16 buyLpFee,
        uint16 sellTax,
        uint16 sellBurn,
        uint16 sellLpFee
    );
    event SetMaxes(uint256 balanceMax, uint256 transactionSizeMax);
    event SetLaunchTimestamp(uint64 launchTimestamp);
    event SetTaxReceiver(address taxReceiver);
    event SetIsExempt(address account, bool isExempt);
    event SetTokenLogoCID(string tokenLogoCID);
    event SetDescriptionMarkdownCID(string descriptionMarkdownCID);
    event TaxesCollected(uint256 taxWad, uint256 burnWad, uint256 lpWad);
    event SetAmmCzusdPair(address ammCzusdPair);
    event SetTenXSettings(TenXSettingsV2 tenXSettings);

    constructor(
        address creator,
        string memory _name,
        string memory _symbol,
        string memory _tokenLogoCID,
        string memory _descriptionMarkdownCID,
        TenXSettingsV2 _tenXSettings,
        uint256 _balanceMax,
        uint256 _transactionSizeMax,
        uint256 _supply,
        address _taxReceiver,
        uint16 _buyTax,
        uint16 _buyBurn,
        uint16 _buyLpFee,
        uint16 _sellTax,
        uint16 _sellBurn,
        uint16 _sellLpFee,
        uint64 _launchTimestamp
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _grantRole(DEFAULT_ADMIN_ROLE, creator);

        tenXSettings = _tenXSettings;
        taxReceiver = _taxReceiver;
        isExempt[taxReceiver] = true;
        isExempt[creator] = true;
        isExempt[address(this)] = true;
        emit SetIsExempt(taxReceiver, true);
        emit SetIsExempt(creator, true);
        emit SetIsExempt(address(this), true);

        ammCzusdPair = tenXSettings.ammFactory().createPair(
            address(this),
            address(tenXSettings.czusd())
        );
        _mint(creator, _supply);
        INITIAL_SUPPLY = _supply;

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
        if (launchTimestamp > maxLaunchTimestamp) {
            revert TenXSettingsV2.OverCap(launchTimestamp, maxLaunchTimestamp);
        }
        if (launchTimestamp < block.timestamp) {
            revert TenXSettingsV2.UnderFloor(launchTimestamp, block.timestamp);
        }

        emit SetTaxes(buyTax, buyBurn, buyLpFee, sellTax, sellBurn, sellLpFee);
        emit SetMaxes(balanceMax, transactionSizeMax);
        emit SetLaunchTimestamp(launchTimestamp);
        emit SetTokenLogoCID(tokenLogoCID);
        emit SetDescriptionMarkdownCID(descriptionMarkdownCID);
        emit SetAmmCzusdPair(ammCzusdPair);
        emit SetTenXSettings(tenXSettings);
    }

    function ADMIN_setTenXSettings(
        TenXSettingsV2 _tenXSettings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tenXSettings = _tenXSettings;
        emit SetTenXSettings(tenXSettings);
    }

    function ADMIN_setAmmCzusdPair(
        address _ammCzusdPair
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ammCzusdPair = _ammCzusdPair;
        emit SetAmmCzusdPair(ammCzusdPair);
    }

    function ADMIN_zap() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _zap();
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
        emit SetTaxes(buyTax, buyBurn, buyLpFee, sellTax, sellBurn, sellLpFee);
    }

    function MANAGER_setMaxes(
        uint256 _balanceMax,
        uint256 _transactionSizeMax
    ) external onlyRole(MANAGER_ROLE) {
        balanceMax = _balanceMax;
        transactionSizeMax = _transactionSizeMax;
        _revertIfBalanceMaxOutOfRange();
        _revertIfTransactionSizeMaxOutOfRange();
        emit SetMaxes(balanceMax, transactionSizeMax);
    }

    function MANAGER_setTaxReceiver(
        address _taxReceiver
    ) external onlyRole(MANAGER_ROLE) {
        taxReceiver = _taxReceiver;
        isExempt[taxReceiver] = true;
        tenXSettings.blacklist().revertIfAccountBlacklisted(taxReceiver);
        emit SetTaxReceiver(taxReceiver);
    }

    function MANAGER_setIsExempt(
        address _account,
        bool _isExempt
    ) external onlyRole(MANAGER_ROLE) {
        isExempt[_account] = _isExempt;
        emit SetIsExempt(_account, _isExempt);
    }

    //JPG, PNG, SVG
    function MANAGER_setTokenLogoCID(
        string calldata _tokenLogoCID
    ) external onlyRole(MANAGER_ROLE) {
        tokenLogoCID = _tokenLogoCID;
        emit SetTokenLogoCID(tokenLogoCID);
    }

    //Guide: https://commonmark.org/help/
    //Upload to IPFS as .md file.
    function MANAGER_setDescriptionMarkdownCID(
        string calldata _descriptionMarkdownCID
    ) external onlyRole(MANAGER_ROLE) {
        descriptionMarkdownCID = _descriptionMarkdownCID;
        emit SetDescriptionMarkdownCID(descriptionMarkdownCID);
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
        if (
            balanceMax > (tenXSettings.balanceCapBps() * totalSupply()) / _BASIS
        ) {
            revert TenXSettingsV2.OverCap(
                balanceMax,
                (tenXSettings.balanceCapBps() * totalSupply()) / _BASIS
            );
        }
        if (
            balanceMax <
            (tenXSettings.balanceFloorBps() * totalSupply()) / _BASIS
        ) {
            revert TenXSettingsV2.UnderFloor(
                balanceMax,
                (tenXSettings.balanceFloorBps() * totalSupply()) / _BASIS
            );
        }
    }

    function _revertIfTransactionSizeMaxOutOfRange() internal view {
        if (
            transactionSizeMax >
            (tenXSettings.transactionSizeCapBps() * totalSupply()) / _BASIS
        ) {
            revert TenXSettingsV2.OverCap(
                transactionSizeMax,
                (tenXSettings.transactionSizeCapBps() * totalSupply()) / _BASIS
            );
        }
        if (
            transactionSizeMax <
            (tenXSettings.transactionSizeFloorBps() * totalSupply()) / _BASIS
        ) {
            revert TenXSettingsV2.UnderFloor(
                transactionSizeMax,
                (tenXSettings.transactionSizeFloorBps() * totalSupply()) /
                    _BASIS
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
            //from == address(0) || Total supply is minted in constructor.
            to == address(0) ||
            value == 0 ||
            isExempt[from] ||
            isExempt[to]
        ) {
            //Default behavior for mints, burns, exempt, transfers
            super._update(from, to, value);
        } else {

            //If theres enough tokens available, swap to LP
            //Can also be done manually by admin
            if (
                balanceOf(address(this)) >=
                (tenXSettings.swapLiquifyAtBps() * totalSupply()) / _BASIS
            ) {
                _zap();
            }
            _updateStandardWallet(from, to, value);
        }

        _revertIfStandardWalletAndOverMaxHolding(from);
        _revertIfStandardWalletAndOverMaxHolding(to);
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
        if (block.timestamp < launchTimestamp) {
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
            lpWad += (value * sellLpFee) / _BASIS;
        }

        if (taxWad > 0) {
            super._update(from, taxReceiver, taxWad);
            totalTaxWad += taxWad;
        }
        if (burnWad > 0) {
            super._update(from, address(0), burnWad);
            totalBurnWad += burnWad;
        }
        if (lpWad > 0) {
            super._update(from, address(this), lpWad);
            totalLpWad += lpWad;
        }
        emit TaxesCollected(taxWad, burnWad, lpWad);
        super._update(from, to, value - taxWad - burnWad - lpWad);
    }

    function _revertIfStandardWalletAndOverMaxHolding(
        address wallet
    ) internal view {
        if (
            wallet != ammCzusdPair &&
            !isExempt[wallet] &&
            balanceOf(wallet) > balanceMax
        ) {
            revert OverMax(balanceOf(wallet), balanceMax);
        }
    }

    function _zap() private {
        uint256 zapAmount = balanceOf(address(this));
        AmmZapV1 ammZap = tenXSettings.ammZapV1();
        _approve(address(this), address(ammZap), zapAmount);
        bool prevZapExempt = isExempt[address(ammZap)];
        isExempt[address(ammZap)] = true;
        ammZap.zapInToken(address(this), zapAmount, ammCzusdPair, 0);
        isExempt[address(ammZap)] = prevZapExempt;
    }
}
