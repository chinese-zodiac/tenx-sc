// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {TenXLaunchView} from "../../src/v1/TenXLaunchView.sol";
import {TenXLaunch} from "../../src/v1/TenXLaunch.sol";

contract DeployTenXLaunchView is Script {
    function run() public {
        vm.startBroadcast();

        new TenXLaunchView(
            TenXLaunch(0x9A62fE6B016f8ba28b64D822D4fB6E5206268C22)
        );

        vm.stopBroadcast();
    }
}
