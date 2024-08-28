// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./interfaces/IAmmFactory.sol";
/*
    TODO:
    add events
    add link to token logo
    add max tx
    add max supply
    add auto lp on buy/sell
    add social links array (tg, x, web)
    add short description
    */
contract TenXToken is ERC20, ERC20Permit, ERC20Burnable {
    uint256 constant _BASIS = 10000;

    address public constant czusd =
        address(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IAmmFactory public constant factory =
        IAmmFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    mapping(address account => bool isExempt) public isTaxExempt;

    uint256 public immutable buyTax;
    uint256 public immutable buyBurn;
    uint256 public immutable sellTax;
    uint256 public immutable sellBurn;

    address public ammCzusdPair;

    address public taxReceiver;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _taxReceiver,
        uint256 _buyTax,
        uint256 _buyBurn,
        uint256 _sellTax,
        uint256 _sellBurn
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        taxReceiver = _taxReceiver;
        isTaxExempt[taxReceiver] = true;
        isTaxExempt[msg.sender] = true;
        ammCzusdPair = factory.createPair(address(this), czusd);
        _mint(msg.sender, _supply);

        buyTax = _buyTax;
        buyBurn = _buyBurn;
        sellTax = _sellTax;
        sellBurn = _sellBurn;
    }

    function setTaxReceiver(address _taxReceiver) external {
        require(msg.sender == taxReceiver, "Only taxReceiver");
        taxReceiver = _taxReceiver;
    }

    //Overrides _update on mint, burn, transfer to handle taxes.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (
            from == address(0) ||
            to == address(0) ||
            value == 0 ||
            isTaxExempt[from] ||
            isTaxExempt[to] ||
            (from != ammCzusdPair && to != ammCzusdPair)
        ) {
            //Default behavior for mints, burns, exempt, and transfers
            super._update(from, to, value);
        } else {
            //Tax and burn for buys, sells
            uint256 taxWad;
            uint256 burnWad;
            if (from == ammCzusdPair) {
                //buy taxes
                taxWad += (value * buyTax) / _BASIS;
                burnWad += (value * buyBurn) / _BASIS;
            }
            if (to == ammCzusdPair) {
                //sell taxes
                taxWad += (value * sellTax) / _BASIS;
                burnWad += (value * sellBurn) / _BASIS;
            }

            if (taxWad > 0) super._update(from, taxReceiver, taxWad);
            if (burnWad > 0) super._update(from, address(0), burnWad);

            super._update(from, to, value - taxWad - burnWad);
        }
    }
}
