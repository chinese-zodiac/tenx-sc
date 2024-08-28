// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {TenXBlacklist} from "./TenXBlacklist.sol";

contract TenXSettingsV2 is AccessControlEnumerable {
    uint256 public czusdGrantCap = 5_000 ether;
    uint256 public czusdGrantFloor = 500 ether;
    uint64 public launchTimestampCap = 90 days;
    uint16 public taxesTotalCap = 40_00; //40%
    uint16 public transactionSizeCap = 100_00; //100%
    uint16 public transactionSizeFloor = 1; //0.01%
    uint16 public balanceCap = 100_00; //100%
    uint16 public balanceFloor = 1; //0.01%
    uint16 public swapLiquifyAt = 1; //0.01%

    TenXBlacklist public blacklist;
    IERC20Mintable public czusd =
        IERC20Mintable(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IAmmRouter02 public router =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    error OverCap(uint256 amount, uint256 cap);
    error UnderFloor(uint256 amount, uint256 floor);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
