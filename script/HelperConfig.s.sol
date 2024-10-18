// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig {

    int256 public constant numberOfCryptocurrencies = 5;

    struct NetworkConfig {
        address[] priceFeedAddresses;
        string[] nameOfSymbols;
        uint256 numberCryptocurrencies;
        address[] tokenAddresses;
    }

    error HelperConfig__NotSameLength();
    error HelperConfig__IsRunningOnDifferentChain();

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    string[] public symbolOfCryptocurrency;
    NetworkConfig internal s_networkConfig;

    enum Currency{
        EURO,
        DOLLAR
    }

    constructor() {

        address[numberOfCryptocurrencies] memory tempPriceFeedAddresses;
        address[numberOfCryptocurrencies] memory tempTokenAddresses;
        if (block.chainid == 11155111) {
            tempPriceFeedAddresses = [0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, 0x694AA1769357215DE4FAC081bf1f309aDC325306, 0x694AA1769357215DE4FAC081bf1f309aDC325306, 0x694AA1769357215DE4FAC081bf1f309aDC325306, 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43];
            tempTokenAddresses = [0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, 0x0000000000000000000000000000000000001010, 0xd93f7E271cB87c23AaA73edC008A79646d1F9912, 0xb33EaAd8d922B1083446DC23f610c2567fB5180f];
        } else if (block.chainid == 137) {
            tempPriceFeedAddresses = [0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6, 0xF9680D99D6C9589e2a93a78A04A279e509205945, 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0, 0x10C8264C0935b3B9870013e057f330Ff3e9C56dC, 0xdf0Fb4e4F928d2dCB76f438575fDD8682386e13C];
            tempTokenAddresses = [0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, 0x0000000000000000000000000000000000001010, 0xd93f7E271cB87c23AaA73edC008A79646d1F9912, 0xb33EaAd8d922B1083446DC23f610c2567fB5180f];
        } else {
            revert HelperConfig__IsRunningOnDifferentChain();
        }

        string[numberOfCryptocurrencies] memory tempSymbols = ["WBTC", "WETH", "MATIC", "WSOL", "UNI"];

        for(uint256 i=0; i<uint256(numberOfCryptocurrencies); i++){
            symbolOfCryptocurrency.push(tempSymbols[i]);
            priceFeedAddresses.push(tempPriceFeedAddresses[i]);
            tokenAddresses.push(tempTokenAddresses[i]);
        }

        if (!(symbolOfCryptocurrency.length == priceFeedAddresses.length) || !(symbolOfCryptocurrency.length == uint256(numberOfCryptocurrencies)) || !(priceFeedAddresses.length == uint256(numberOfCryptocurrencies))){
            revert HelperConfig__NotSameLength();
        }

        s_networkConfig = NetworkConfig({
            priceFeedAddresses: priceFeedAddresses,
            nameOfSymbols: symbolOfCryptocurrency,
            numberCryptocurrencies: uint256(numberOfCryptocurrencies),
            tokenAddresses: tokenAddresses
        });

    }

    function getNetworkConfig() public view returns(NetworkConfig memory){
        return s_networkConfig;
    }

}