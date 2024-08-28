// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {TenXLaunch} from "../../src/v1/TenXLaunch.sol";

contract DeployTenXLaunch is Script {
    function run() public {
        vm.startBroadcast();

        new TenXLaunch();

        vm.stopBroadcast();
    }
}
