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
import {PaymentGatewayOneOff} from "../src/PaymentGateway.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DCPG is ReentrancyGuard{

    //////////////
    /// Errors ///
    //////////////

    error DCPG__DoesNotHaveIndex();
    error DCPG__DifferentLength();
    error DCPG__IsNotOwner();

    ///////////////
    // Variables //
    ///////////////

    AggregatorV3Interface internal s_priceFeed;

    address[] private s_priceFeedAddresses;
    string[] private s_cryptocurrencySymbols;
    uint256 internal s_PaymentId = 0;

    mapping(string => address) private s_symbolToPriceFeedAddress;

    mapping(uint256 => address) private s_idToPaymentGatewayAddress;
    mapping(address => uint256[]) private s_addressToPaymentGateways;

    uint256 internal constant DECIMALS_PRICE_FEED = 8;
    address internal constant OWNERS_ADDRESS = 0xc1cCaEEF257Ff506f27d0769C0662805259e27f6;


    enum Method{
        ONEOFF,
        SUBSRIPTION
    }

    //////////////
    /// Events ///
    //////////////


    /////////////////
    /// Modifiers ///
    /////////////////

    modifier hasPaymentId(uint256 id) {
        uint256[] memory indexes = s_addressToPaymentGateways[msg.sender];
        bool hasId = false;
        for(uint256 i=0; i<indexes.length; i++){
            if(indexes[i] == id){
                hasId = true;
                break;
            }
        }
        assert(hasId);
        _;
    }

    modifier isOwnerProxy() {
        if(msg.sender != OWNERS_ADDRESS){
            revert DCPG__IsNotOwner();
        }
        _;
    }

    ///////////////
    // Functions //
    ///////////////

    constructor(address[] memory priceFeeds, string[] memory cryptoSymbols){
        s_priceFeedAddresses = priceFeeds;
        s_cryptocurrencySymbols = cryptoSymbols;
        uint256 length_one = s_priceFeedAddresses.length;
        uint256 length_two = s_cryptocurrencySymbols.length;

        if(length_one != length_two){
            revert DCPG__DifferentLength();
        }

        for(uint256 i=0; i<length_one; i++){
            s_symbolToPriceFeedAddress[cryptoSymbols[i]] = priceFeeds[i];
        }
    }

    function getPrice(address assetAddress) public returns (uint256) {
        s_priceFeed = AggregatorV3Interface(assetAddress);
        (
            , 
            int256 price,
            ,
            ,
            
        ) = s_priceFeed.latestRoundData();
        return uint256(price);
    }

    function getPriceWAmount(address assetAddress, uint256 amount) public returns (uint256) {
        uint256 price = getPrice(assetAddress);
        return price * amount;
    }

    function createNewPaymentGatewayOneOff(string[] memory cryptos, address[] memory priceFeedAddresses, uint256 method, string memory api_endpoint, bytes calldata callData) public returns(uint256){
        PaymentGatewayOneOff paymentGatewayOneOff = new PaymentGatewayOneOff(cryptos, priceFeedAddresses, api_endpoint, callData, msg.sender);
        s_idToPaymentGatewayAddress[s_PaymentId] = address(paymentGatewayOneOff);
        s_addressToPaymentGateways[msg.sender].push(s_PaymentId);
        s_PaymentId++;
        return s_PaymentId-1;
    }

    function addCryptocurrency(address priceFeed, string calldata cryptoSymbol)
        external
        isOwnerProxy
    {
        s_priceFeedAddresses.push(priceFeed);
        s_cryptocurrencySymbols.push(cryptoSymbol);
        s_symbolToPriceFeedAddress[cryptoSymbol] = priceFeed;
    }

    function takeCryptocurrency(uint256 index)
        external
        isOwnerProxy
    {
        s_priceFeedAddresses[index] = s_priceFeedAddresses[s_priceFeedAddresses.length-1];
        s_priceFeedAddresses.pop();
        s_cryptocurrencySymbols[index] = s_cryptocurrencySymbols[s_cryptocurrencySymbols.length-1];
        s_cryptocurrencySymbols.pop();
    }

    // Getter functions
    // External View

    function getPriceFeedOnCryptocurrency(string memory crypto) external view returns(address){
        return s_symbolToPriceFeedAddress[crypto];
    }

    function getAvailableCryptocurrencies(uint256 index) external view returns(string memory){
        return s_cryptocurrencySymbols[index];
    }

    function getAvailablePriceFeedIndexes(uint256 index) external view returns(address){
        return s_priceFeedAddresses[index];
    }

    function getPaymentGatewayId(uint256 index) external view returns(uint256){
        return s_addressToPaymentGateways[msg.sender][index];
    }

    function getPaymentGatewayAddressOnid(uint256 id) 
        external 
        view 
        hasPaymentId(id)
        returns(address)
    {
        return s_idToPaymentGatewayAddress[id];
    }

    function getDecimals() external pure returns(uint256) {
        return DECIMALS_PRICE_FEED;
    }

    
}

