// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";

contract TenXSettingsV2 is AccessControlEnumerable {
    uint256 public czusdGrantCap = 5_000 ether;
    uint256 public czusdGrantFloor = 5_000 ether;
    uint64 public launchTimestampCap = 90 days;
    uint16 public taxesTotalCap = 40_00; //40%
    uint16 public transactionSizeCap = 100_00; //100%
    uint16 public transactionSizeFloor = 1; //0.01%
    uint16 public balanceCap = 100_00; //100%
    uint16 public balanceFloor = 1; //0.01%
    uint16 public swapLiquifyAt = 1; //0.01%

    TenXBlacklistV2 public blacklist;
    IERC20Mintable public czusd =
        IERC20Mintable(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IAmmRouter02 public ammRouter =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IAmmFactory public ammFactory =
        IAmmFactory(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    event SetCzusdGrantCap(uint256 to);
    event SetCzusdGrantFlor(uint256 to);
    event SetLaunchTimestampCap(uint64 to);
    event SetTaxesTotalCap(uint16 to);
    event SetTransactionSizeCap(uint16 to);
    event SetTransactionSizeFloor(uint16 to);
    event SetBalanceCap(uint16 to);
    event SetBalanceFloor(uint16 to);
    event SetSwapLiquifyAt(uint16 to);
    event SetBlacklist(TenXBlacklistV2 to);
    event SetCzusd(IERC20Mintable to);
    event SetAmmRouter(IAmmRouter02 to);
    event SetAmmFactory(IAmmFactory to);

    error OverCap(uint256 amount, uint256 cap);
    error UnderFloor(uint256 amount, uint256 floor);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit SetCzusdGrantCap(czusdGrantCap);
        emit SetCzusdGrantFlor(czusdGrantFloor);
        emit SetLaunchTimestampCap(launchTimestampCap);
        emit SetTaxesTotalCap(taxesTotalCap);
        emit SetTransactionSizeCap(transactionSizeCap);
        emit SetTransactionSizeFloor(transactionSizeFloor);
        emit SetBalanceCap(balanceCap);
        emit SetBalanceFloor(balanceFloor);
        emit SetSwapLiquifyAt(swapLiquifyAt);
        emit SetBlacklist(blacklist);
        emit SetCzusd(czusd);
        emit SetAmmRouter(ammRouter);
        emit SetAmmFactory(ammFactory);
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
    function setTransactionSizeCap(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transactionSizeCap = to;
        emit SetTransactionSizeCap(transactionSizeCap);
    }
    function setTransactionSizeFloor(
        uint16 to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transactionSizeFloor = to;
        emit SetTransactionSizeFloor(transactionSizeFloor);
    }
    function setBalanceCap(uint16 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        balanceCap = to;
        emit SetBalanceCap(balanceCap);
    }
    function setBalanceFloor(uint16 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        balanceFloor = to;
        emit SetBalanceFloor(balanceFloor);
    }
    function setSwapLiquifyAt(uint16 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapLiquifyAt = to;
        emit SetSwapLiquifyAt(swapLiquifyAt);
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
}
