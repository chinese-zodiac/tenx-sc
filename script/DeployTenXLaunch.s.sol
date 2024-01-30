// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/TenXLaunch.sol";

contract DeployTenXLaunch is Script {
    function run() public {
        vm.startBroadcast();

        new TenXLaunch();

        vm.stopBroadcast();
    }
}
