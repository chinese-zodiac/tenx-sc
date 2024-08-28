// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {TenXToken} from "./TenXToken.sol";
import {IAmmFactory} from "../interfaces/IAmmFactory.sol";
import {IAmmRouter02} from "../interfaces/IAmmRouter02.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";

import {IterableArrayWithoutDuplicateKeys} from "../lib/IterableArrayWithoutDuplicateKeys.sol";

contract TenXLaunch {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;

    uint256 public constant maxCzusdWad = 5_000 ether;
    uint256 public constant minCzusdWad = 500 ether;

    uint256 public constant maxTaxes = 4000; //40%

    IterableArrayWithoutDuplicateKeys.Map private launchedTokens;
    mapping(address token => uint256 liquidityUsd)
        public launchedTokenLiquidityUsd;
    IERC20Mintable public immutable czusd =
        IERC20Mintable(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IAmmRouter02 public immutable router =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

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
        require(_czusdWad <= maxCzusdWad, "Above max");
        require(_czusdWad >= minCzusdWad, "Below min");

        require(
            _buyTax + _buyBurn + _sellTax + _sellBurn < maxTaxes,
            "Tax and burn too high"
        );

        TenXToken token = new TenXToken(
            _name,
            _symbol,
            _czusdWad, //supply equal to czusdWad, 1 token = $1
            _taxReceiver,
            _buyTax,
            _buyBurn,
            _sellTax,
            _sellBurn
        );
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
        launchedTokenLiquidityUsd[address(token)] = _czusdWad;
    }

    function launchedTokenCzusdPair(
        address token
    ) external view returns (address) {
        return TenXToken(token).ammCzusdPair();
    }

    function launchedTokensCount() external view returns (uint256) {
        return launchedTokens.size();
    }

    function launchedTokenAt(uint256 index) external view returns (address) {
        return launchedTokens.getKeyAtIndex(index);
    }
}
