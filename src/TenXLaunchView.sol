// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import "./TenXLaunch.sol";
import "./TenXToken.sol";
import "./interfaces/IAmmPair.sol";

contract TenXLaunchView {
    TenXLaunch public immutable tenXLaunch;

    constructor(TenXLaunch _tenXLaunch) {
        tenXLaunch = _tenXLaunch;
    }

    function getTenXTokenData(
        TenXToken _token
    )
        public
        view
        returns (
            IAmmPair czusdPair_,
            address taxReceiver_,
            uint256 czusdGrant_,
            uint16 buyTax_,
            uint16 buyBurn_,
            uint16 sellTax_,
            uint16 sellBurn_
        )
    {
        czusdPair_ = IAmmPair(
            tenXLaunch.launchedTokenCzusdPair(address(_token))
        );
        taxReceiver_ = _token.taxReceiver();
        czusdGrant_ = tenXLaunch.launchedTokenLiquidityUsd(address(_token));
        buyTax_ = uint16(_token.buyTax());
        buyBurn_ = uint16(_token.buyBurn());
        sellTax_ = uint16(_token.sellTax());
        sellBurn_ = uint16(_token.sellBurn());
    }

    function getTenXTokenDataFromIndex(
        uint256 _index
    )
        public
        view
        returns (
            TenXToken token_,
            IAmmPair czusdPair_,
            address taxReceiver_,
            uint256 czusdGrant_,
            uint16 buyTax_,
            uint16 buyBurn_,
            uint16 sellTax_,
            uint16 sellBurn_
        )
    {
        token_ = TenXToken(tenXLaunch.launchedTokenAt(_index));
        (
            czusdPair_,
            taxReceiver_,
            czusdGrant_,
            buyTax_,
            buyBurn_,
            sellTax_,
            sellBurn_
        ) = getTenXTokenData(token_);
    }

    function getTenXTokenDataAll(
        uint256 startIndex,
        uint256 count
    )
        public
        view
        returns (
            TenXToken[] memory tokens_,
            IAmmPair[] memory czusdPairs_,
            address[] memory taxReceivers_,
            uint256[] memory czusdGrants_,
            uint16[] memory buyTaxes_,
            uint16[] memory buyBurns_,
            uint16[] memory sellTaxes_,
            uint16[] memory sellBurns_
        )
    {
        uint256 tokenCount = tenXLaunch.launchedTokensCount();
        if (startIndex >= tokenCount) {
            //start index too high, do nothing
            return (
                tokens_,
                czusdPairs_,
                taxReceivers_,
                czusdGrants_,
                buyTaxes_,
                buyBurns_,
                sellTaxes_,
                sellBurns_
            );
        }
        if (startIndex + count > tokenCount) {
            //count exceeds max, only get tokens up to max
            count = tokenCount - startIndex;
        }
        tokens_ = new TenXToken[](count);
        czusdPairs_ = new IAmmPair[](count);
        taxReceivers_ = new address[](count);
        czusdGrants_ = new uint256[](count);
        buyTaxes_ = new uint16[](count);
        buyBurns_ = new uint16[](count);
        sellTaxes_ = new uint16[](count);
        sellBurns_ = new uint16[](count);
        for (uint256 i = startIndex; i < count; i++) {
            TenXToken token = TenXToken(tenXLaunch.launchedTokenAt(i));
            tokens_[i] = token;
            czusdPairs_[i] = IAmmPair(
                tenXLaunch.launchedTokenCzusdPair(address(token))
            );
            taxReceivers_[i] = token.taxReceiver();
            czusdGrants_[i] = tenXLaunch.launchedTokenLiquidityUsd(
                address(token)
            );
            buyTaxes_[i] = (uint16(token.buyTax()));
            buyBurns_[i] = (uint16(token.buyBurn()));
            sellTaxes_[i] = (uint16(token.sellTax()));
            sellBurns_[i] = (uint16(token.sellBurn()));
        }
    }
}
