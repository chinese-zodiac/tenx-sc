// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXSettingsV2} from "./TenXSettings.sol";
import {TenXTokenV2} from "./TenXToken.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import {IterableArrayWithoutDuplicateKeys} from "../lib/IterableArrayWithoutDuplicateKeys.sol";

contract TenXLaunchV2 is AccessControlEnumerable {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;

    IterableArrayWithoutDuplicateKeys.Map private launchedTokens;
    mapping(address token => uint256 czusdWad) public czusdGrant;

    TenXSettingsV2 public tenXSettings;

    event LaunchToken(TenXTokenV2 token, uint256 index, uint256 cuzsdGrant);
    event SetTenXSettings(TenXSettingsV2 tenXSettings);

    constructor(TenXSettingsV2 _tenXSettings) {
        tenXSettings = _tenXSettings;
        emit SetTenXSettings(tenXSettings);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, tenXSettings.governance());
    }

    function launchToken(
        uint256 _czusdWad,
        string memory _name,
        string memory _symbol,
        string memory _tokenLogoCID,
        string memory _descriptionMarkdownCID,
        uint256 _balanceMax,
        uint256 _transactionSizeMax,
        address _taxReceiver,
        uint16 _buyTax,
        uint16 _buyBurn,
        uint16 _buyLpFee,
        uint16 _sellTax,
        uint16 _sellBurn,
        uint16 _sellLpFee,
        uint64 _launchTimestamp
    ) external {
        if (_launchTimestamp == 0) {
            //Pass 0 as launch timestamp to launch immediately.
            _launchTimestamp = uint64(block.timestamp);
        }
        tenXSettings.blacklist().revertIfAccountBlacklisted(msg.sender);
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

        TenXTokenV2 token = tenXSettings.tokenFactory().create(
            _name, //string memory _name,
            _symbol, //string memory _symbol,
            _tokenLogoCID, //string memory _tokenLogoCID,
            _descriptionMarkdownCID, //string memory _descriptionMarkdownCID,
            tenXSettings, //TenXSettingsV2 _tenXSettings,
            _balanceMax, //uint256 _balanceMax,
            _transactionSizeMax, //uint256 _transactionSizeMax,
            _czusdWad, //uint256 _supply,  XYZ = 1 CZUSD
            _taxReceiver, //address _taxReceiver,
            _buyTax, //uint16 _buyTax,
            _buyBurn, //uint16 _buyBurn,
            _buyLpFee, //uint16 _buyLpFee,
            _sellTax, //uint16 _sellTax,
            _sellBurn, //uint16 _sellBurn,
            _sellLpFee, //uint16 _sellLpFee,
            _launchTimestamp //uint64 _launchTimestamp
        );

        IERC20Mintable czusd = tenXSettings.czusd();
        IAmmRouter02 router = tenXSettings.ammRouter();
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

        token.grantRole(DEFAULT_ADMIN_ROLE, tenXSettings.governance());
        token.grantRole(keccak256("MANAGER_ROLE"), msg.sender);
        token.revokeRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function ADMIN_setTenXSettings(
        TenXSettingsV2 _tenXSettings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tenXSettings = _tenXSettings;
        emit SetTenXSettings(tenXSettings);
    }

    function launchedTokensCount() external view returns (uint256) {
        return launchedTokens.size();
    }

    function launchedTokenAt(
        uint256 index
    ) external view returns (TenXTokenV2) {
        return TenXTokenV2(launchedTokens.getKeyAtIndex(index));
    }
}
