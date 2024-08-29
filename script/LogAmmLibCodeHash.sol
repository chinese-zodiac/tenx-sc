// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AmmPair} from "../src/amm/AmmPair.sol";

//Logs the init hash for use in AmmLibrary.pairFor to the console.
//This init hash changes whenever the bytecode for AmmPair changes.
//Changes to these may require recomputing the hash:
//Solidity version, openzeppelin, AmmPair logic, optimization parameters, AmmPair libs.
contract LogAmmLibCodeHash is Script {
    function run() public view {
        console2.logBytes32(getInitHash());
    }

    function getInitHash() public pure returns (bytes32) {
        bytes memory bytecode = type(AmmPair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }
}
