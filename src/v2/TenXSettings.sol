// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {AmmZapV1} from "../amm/AmmZapV1.sol";

contract TenXSettingsV2 is AccessControlEnumerable {
    uint256 public czusdGrantCap = 10_000 ether;
    uint256 public czusdGrantFloor = 5_000 ether;
    uint64 public launchTimestampCap = 90 days;
    uint16 public taxesTotalCap = 30_00; //30.00%
    uint16 public transactionSizeCapBps = 100_00; //100.00%
    uint16 public transactionSizeFloorBps = 1; //0.01%
    uint16 public balanceCapBps = 100_00; //100.00%
    uint16 public balanceFloorBps = 1; //0.01%
    uint16 public swapLiquifyAtBps = 1; //0.01%

    address public governance;
    TenXBlacklistV2 public blacklist;
    IERC20Mintable public czusd;
    IAmmRouter02 public ammRouter;
    IAmmFactory public ammFactory;
    AmmZapV1 public ammZapV1;

    event SetCzusdGrantCap(uint256 to);
    event SetCzusdGrantFlor(uint256 to);
    event SetLaunchTimestampCap(uint64 to);
    event SetTaxesTotalCap(uint16 to);
    event SetTransactionSizeCapBps(uint16 to);
    event SetTransactionSizeFloorBps(uint16 to);
    event SetBalanceCapBps(uint16 to);
    event SetBalanceFloorBps(uint16 to);
    event SetSwapLiquifyAtBps(uint16 to);
    event SetGovernance(address to);
    event SetBlacklist(TenXBlacklistV2 to);
    event SetCzusd(IERC20Mintable to);
    event SetAmmRouter(IAmmRouter02 to);
    event SetAmmFactory(IAmmFactory to);
    event SetAmmZapV1(AmmZapV1 to);

    error OverCap(uint256 amount, uint256 cap);
    error UnderFloor(uint256 amount, uint256 floor);

    constructor(
        address _governance,
        TenXBlacklistV2 _blacklist,
        IERC20Mintable _czusd,
        IAmmRouter02 _ammRouter,
        IAmmFactory _ammFactory,
        AmmZapV1 _ammZapV1
    ) {
        governance = _governance;
        blacklist = _blacklist;
        czusd = _czusd;
        ammRouter = _ammRouter;
        ammFactory = _ammFactory;
        ammZapV1 = _ammZapV1;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit SetCzusdGrantCap(czusdGrantCap);
        emit SetCzusdGrantFlor(czusdGrantFloor);
        emit SetLaunchTimestampCap(launchTimestampCap);
        emit SetTaxesTotalCap(taxesTotalCap);
        emit SetTransactionSizeCapBps(transactionSizeCapBps);
        emit SetTransactionSizeFloorBps(transactionSizeFloorBps);
        emit SetBalanceCapBps(balanceCapBps);
        emit SetBalanceFloorBps(balanceFloorBps);
        emit SetSwapLiquifyAtBps(swapLiquifyAtBps);
        emit SetGovernance(governance);
        emit SetBlacklist(blacklist);
        emit SetCzusd(czusd);
        emit SetAmmRouter(ammRouter);
        emit SetAmmFactory(ammFactory);
        emit SetAmmZapV1(ammZapV1);
    }

    function setCzusdGrantCap(
        uint256 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusdGrantCap = to;
        emit SetCzusdGrantCap(czusdGrantCap);
    }
    function setCzusdGrantFlor(
        uint256 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusdGrantFloor = to;
        emit SetCzusdGrantFlor(czusdGrantFloor);
    }
    function setLaunchTimestampCap(
        uint64 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        launchTimestampCap = to;
        emit SetLaunchTimestampCap(launchTimestampCap);
    }
    function setTaxesTotalCap(uint16 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxesTotalCap = to;
        emit SetTaxesTotalCap(taxesTotalCap);
    }
    function setTransactionSizeCapBps(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transactionSizeCapBps = to;
        emit SetTransactionSizeCapBps(transactionSizeCapBps);
    }
    function setTransactionSizeFloorBps(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transactionSizeFloorBps = to;
        emit SetTransactionSizeFloorBps(transactionSizeFloorBps);
    }
    function setBalanceCapBps(uint16 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        balanceCapBps = to;
        emit SetBalanceCapBps(balanceCapBps);
    }
    function setBalanceFloorBps(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        balanceFloorBps = to;
        emit SetBalanceFloorBps(balanceFloorBps);
    }
    function setSwapLiquifyAtBps(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapLiquifyAtBps = to;
        emit SetSwapLiquifyAtBps(swapLiquifyAtBps);
    }
    function setCzodiacGovernance(
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        governance = to;
        emit SetGovernance(governance);
    }
    function setBlacklist(
        TenXBlacklistV2 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklist = to;
        emit SetBlacklist(blacklist);
    }
    function setCzusd(IERC20Mintable to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusd = to;
        emit SetCzusd(czusd);
    }
    function setAmmRouter(
        IAmmRouter02 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ammRouter = to;
        emit SetAmmRouter(ammRouter);
    }
    function setAmmFactory(
        IAmmFactory to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ammFactory = to;
        emit SetAmmFactory(ammFactory);
    }
    function setAmmZapV1(AmmZapV1 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ammZapV1 = to;
        emit SetAmmZapV1(to);
    }
}
