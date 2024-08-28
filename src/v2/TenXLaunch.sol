// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXSettingsV2} from "./TenXSettings.sol";
import {TenXTokenV2} from "./TenXToken.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";

import {IterableArrayWithoutDuplicateKeys} from "../lib/IterableArrayWithoutDuplicateKeys.sol";

contract TenXLaunchV2 {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;

    IterableArrayWithoutDuplicateKeys.Map private launchedTokens;
    mapping(address token => uint256 czusdWad) public czusdGrant;

    TenXSettingsV2 public immutable tenXSettings;

    constructor() {
        tenXSettings = new TenXSettingsV2();
        tenXSettings.grantRole(tenXSettings.DEFAULT_ADMIN_ROLE(), msg.sender);
        tenXSettings.revokeRole(
            tenXSettings.DEFAULT_ADMIN_ROLE(),
            address(this)
        );
    }

    event LaunchToken(TenXTokenV2 token, uint256 index, uint256 cuzsdGrant);
    function launchToken(
        string memory _name,
        string memory _symbol,
        uint256 _czusdWad,
        address _taxReceiver,
        uint256 _buyTax,
        uint256 _buyBurn,
        uint256 _sellTax,
        uint256 _sellBurn
    ) external {
        if (_czusdWad > tenXSettings.czusdGrantCap()) {
            revert TenXSettingsV2.OverCap(
                _czusdWad,
                tenXSettings.czusdGrantCap()
            );
        }
        if (_czusdWad < tenXSettings.czusdGrantFloor()) {
            revert TenXSettingsV2.UnderFloor(
                _czusdWad,
                tenXSettings.czusdGrantFloor()
            );
        }

        TenXTokenV2 token = new TenXTokenV2(
            _name,
            _symbol,
            _czusdWad, //supply equal to czusdWad, 1 token = $1
            _taxReceiver,
            _buyTax,
            _buyBurn,
            _sellTax,
            _sellBurn
        );

        IERC20Mintable czusd = tenXSettings.czusd();
        IAmmRouter02 router = tenXSettings.router();
        czusd.mint(address(this), _czusdWad);

        token.approve(address(router), _czusdWad);
        czusd.approve(address(router), _czusdWad);

        // add the liquidity
        router.addLiquidity(
            address(token),
            address(czusd),
            _czusdWad,
            _czusdWad,
            0, // slippage impossible
            0, // slippage impossible
            address(0), // permanently locked liq
            block.timestamp
        );

        launchedTokens.add(address(token));
        czusdGrant[address(token)] = _czusdWad;
        emit LaunchToken(token, launchedTokens.size() - 1, _czusdWad);
    }

    function launchedTokensCount() external view returns (uint256) {
        return launchedTokens.size();
    }

    function launchedTokenAt(uint256 index) external view returns (address) {
        return launchedTokens.getKeyAtIndex(index);
    }
}
