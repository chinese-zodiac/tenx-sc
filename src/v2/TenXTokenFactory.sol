// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXTokenV2} from "./TenXToken.sol";
import {TenXSettingsV2} from "./TenXSettings.sol";

contract TenXTokenFactoryV2 {
    function create(
        string memory _name,
        string memory _symbol,
        string memory _tokenLogoCID,
        string memory _descriptionMarkdownCID,
        TenXSettingsV2 _tenXSettings,
        uint256 _balanceMax,
        uint256 _transactionSizeMax,
        uint256 _supply,
        address _taxReceiver,
        uint16 _buyTax,
        uint16 _buyBurn,
        uint16 _buyLpFee,
        uint16 _sellTax,
        uint16 _sellBurn,
        uint16 _sellLpFee,
        uint64 _launchTimestamp
    ) external returns (TenXTokenV2 token_) {
        token_ = new TenXTokenV2(
            msg.sender, //address creator,
            _name, //string memory _name,
            _symbol, //string memory _symbol,
            _tokenLogoCID, //string memory _tokenLogoCID,
            _descriptionMarkdownCID, //string memory _descriptionMarkdownCID,
            _tenXSettings, //TenXSettingsV2 _tenXSettings,
            _balanceMax, //uint256 _balanceMax,
            _transactionSizeMax, //uint256 _transactionSizeMax,
            _supply, //uint256 _supply,  XYZ = 1 CZUSD
            _taxReceiver, //address _taxReceiver,
            _buyTax, //uint16 _buyTax,
            _buyBurn, //uint16 _buyBurn,
            _buyLpFee, //uint16 _buyLpFee,
            _sellTax, //uint16 _sellTax,
            _sellBurn, //uint16 _sellBurn,
            _sellLpFee, //uint16 _sellLpFee,
            _launchTimestamp //uint64 _launchTimestamp
        );
    }
}
