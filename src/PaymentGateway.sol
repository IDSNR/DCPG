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

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DCPG} from "./DCPG.sol";

contract PaymentGatewayOneOff is ReentrancyGuard{
    // Errors

    error PaymentGatewayOneOff__NotOwner();
    error PaymentGatewayOneOff__IndexTooHigh();
    error PaymentGatewayOneOff__NotSameSize();

    // Type Declarations

    struct Payment {
        uint256 paymentId;
        bytes metaDataSecondary;
        bool succeded;
        uint256 cryptoIndex;
    }

    // Variables

    string[] private s_availableCryptocurrencyes;
    address[] private s_availableCryptocurrenciesPriceFeed;
    string private s_api_endpoint;
    bytes private s_metaData;
    address private ownerAddress;

    mapping(string => address) private s_cryptoToPriceFeed;



    // Events

    // Modifiers

    modifier OnlyOwner() {
        if(msg.sender != ownerAddress){
            revert PaymentGatewayOneOff__NotOwner();
        }
        _;
    }

    // Functions

    constructor(string[] memory availableCryptocurrencies, address[] memory availableCryptocurrenciesPriceFeed, string memory api_endpoint, bytes memory metaData, address owner_address){
        s_availableCryptocurrencyes = availableCryptocurrencies;
        s_availableCryptocurrenciesPriceFeed = availableCryptocurrenciesPriceFeed;
        s_api_endpoint = api_endpoint;
        s_metaData = metaData;
        ownerAddress = owner_address;
        uint256 length = s_availableCryptocurrenciesPriceFeed.length;
        if(!(length == s_availableCryptocurrencyes.length)){
            revert PaymentGatewayOneOff__NotSameSize();
        }
        for(uint256 i=0; i<length; i++){
            s_cryptoToPriceFeed[s_availableCryptocurrencyes[i]] = s_availableCryptocurrenciesPriceFeed[i];
        }
    }


    // External


    function AddCryptocurrencies(address priceFeedAddress, string calldata symbol)
        external
        OnlyOwner
    {   
        s_availableCryptocurrencyes.push(symbol);
        s_availableCryptocurrenciesPriceFeed.push(priceFeedAddress);
        s_cryptoToPriceFeed[symbol] = priceFeedAddress;
    }

    function takeCryptoCurrencies(uint256 index)
        external 
        OnlyOwner
    {
        s_availableCryptocurrencyes[index] = s_availableCryptocurrencyes[s_availableCryptocurrencyes.length-1];
        s_availableCryptocurrencyes.pop();

        s_availableCryptocurrenciesPriceFeed[index] = s_availableCryptocurrenciesPriceFeed[s_availableCryptocurrenciesPriceFeed.length-1];
        s_availableCryptocurrenciesPriceFeed.pop();
    }

    function changeApiEndpoint(string memory _new_api_endpoint)
        external
        OnlyOwner
    {
        s_api_endpoint = _new_api_endpoint;
    }

    function changeMetadata(bytes memory _new_metadata)
        external 
        OnlyOwner
    {
        s_metaData = _new_metadata;
    }


    // View and Pure

    function getPriceFeedCryptoCurrencies(string memory cryptocurrency) 
        external 
        view 
        OnlyOwner 
        returns(address)
    {
        return s_cryptoToPriceFeed[cryptocurrency];
    }

    function getCryptocurrencies(uint256 index)
        external
        view
        OnlyOwner
        returns(string memory)
    {
        return s_availableCryptocurrencyes[index];
    }

    function getPriceFeeds(uint256 index)
        external
        view
        OnlyOwner
        returns(address)
    {
        return s_availableCryptocurrenciesPriceFeed[index];
    }

    function getApiEndpoint()
        external 
        view
        OnlyOwner
        returns(string memory)
    {
        return s_api_endpoint;
    }

    function getMetadata()
        external 
        view
        OnlyOwner
        returns(bytes memory)
    {
        return s_metaData;
    }

}

contract PaymentGatewaySubscription is ReentrancyGuard {
    // Errors

    // Variables

    string[] private s_availableCryptocurrencyes;
    address[] private s_availableCryptocurrenciesPriceFeed;
    string private s_api_endpoint;
    bytes private s_metaData;

    // Events

    // Modifiers

    // Functions





    // External View and Pure





}