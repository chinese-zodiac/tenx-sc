// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/TenXLaunchView.sol";

contract DeployTenXLaunchView is Script {
    function run() public {
        vm.startBroadcast();

        new TenXLaunchView(
            TenXLaunch(0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22)
        );

        vm.stopBroadcast();
    }
}
