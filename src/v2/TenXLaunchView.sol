// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXLaunchV2} from "./TenXLaunch.sol";
import {TenXTokenV2} from "./TenXToken.sol";
import {TenXSettingsV2} from "./TenXSettings.sol";
import {IAmmPair} from "../interfaces/IAmmPair.sol";

contract TenXLaunchViewV2 {
    TenXLaunchV2 public immutable TEN_X_LAUNCH;

    constructor(TenXLaunchV2 _tenXLaunch) {
        TEN_X_LAUNCH = _tenXLaunch;
    }

    function getTenXTokenData(
        TenXTokenV2 _token
    )
        public
        view
        returns (
            string memory tokenLogoCID_,
            string memory descriptionMarkdownCID_,
            uint256 balanceMax_,
            uint256 transactionSizeMax_,
            IAmmPair ammCzusdPair_,
            address taxReceiver_,
            uint256 czusdGrant_,
            uint16 buyTax_,
            uint16 buyBurn_,
            uint16 buyLpFee_,
            uint16 sellTax_,
            uint16 sellBurn_,
            uint16 sellLpFee_,
            uint64 launchTimestamp_
        )
    {
        tokenLogoCID_ = _token.tokenLogoCID();
        descriptionMarkdownCID_ = _token.descriptionMarkdownCID();
        balanceMax_ = _token.balanceMax();
        transactionSizeMax_ = _token.transactionSizeMax();
        ammCzusdPair_ = IAmmPair(_token.ammCzusdPair());
        taxReceiver_ = _token.taxReceiver();
        czusdGrant_ = TEN_X_LAUNCH.czusdGrant(address(_token));
        buyTax_ = _token.buyTax();
        buyBurn_ = _token.buyBurn();
        buyLpFee_ = _token.buyLpFee();
        sellTax_ = _token.sellTax();
        sellBurn_ = _token.sellBurn();
        sellLpFee_ = _token.sellLpFee();
        launchTimestamp_ = _token.launchTimestamp();
    }

    function getTenXTokenDataFromIndex(
        uint256 _index
    )
        public
        view
        returns (
            TenXTokenV2 token_,
            string memory tokenLogoCID_,
            string memory descriptionMarkdownCID_,
            uint256 balanceMax_,
            uint256 transactionSizeMax_,
            IAmmPair ammCzusdPair_,
            address taxReceiver_,
            uint256 czusdGrant_,
            uint16 buyTax_,
            uint16 buyBurn_,
            uint16 buyLpFee_,
            uint16 sellTax_,
            uint16 sellBurn_,
            uint16 sellLpFee_,
            uint64 launchTimestamp_
        )
    {
        token_ = TenXTokenV2(TEN_X_LAUNCH.launchedTokenAt(_index));
        (
            tokenLogoCID_,
            descriptionMarkdownCID_,
            balanceMax_,
            transactionSizeMax_,
            ammCzusdPair_,
            taxReceiver_,
            czusdGrant_,
            buyTax_,
            buyBurn_,
            buyLpFee_,
            sellTax_,
            sellBurn_,
            sellLpFee_,
            launchTimestamp_
        ) = getTenXTokenData(token_);
    }

    function getTenXTokenLpData(
        TenXTokenV2 _token
    )
        public
        view
        returns (
            uint256 initialSupply_,
            uint256 totalSupply_,
            uint256 tokensInLP_,
            uint256 czusdInLP_,
            uint256 tokenPriceCzusdWad_,
            uint256 tokenMcapCzusd_,
            uint256 totalLpValueCzusd_
        )
    {
        address ammCzusdPair = _token.ammCzusdPair();
        initialSupply_ = _token.INITIAL_SUPPLY();
        totalSupply_ = _token.totalSupply();
        tokensInLP_ = _token.balanceOf(ammCzusdPair);
        czusdInLP_ = TEN_X_LAUNCH.tenXSettings().czusd().balanceOf(
            ammCzusdPair
        );
        tokenPriceCzusdWad_ = (czusdInLP_ * 1 ether) / tokensInLP_;
        tokenMcapCzusd_ =
            (tokenPriceCzusdWad_ * _token.totalSupply()) /
            1 ether;
        totalLpValueCzusd_ = czusdInLP_ * 2;
    }
}
