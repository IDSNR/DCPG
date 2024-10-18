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
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract PaymentGatewayOneOff is ReentrancyGuard{
    // Errors

    error PaymentGatewayOneOff__NotOwner();
    error PaymentGatewayOneOff__IndexTooHigh();
    error PaymentGatewayOneOff__NotSameSize();
    error PaymentGatewayOneOff__AmountMustBeBiggerThanZero();
    error PaymentGatewayOneOff__NotEnoughTokens();
    error PaymentGatewayOneOff__ErrorInTransfer();

    // Type Declarations

    struct PaymentSession {
        uint256 paymentId;
        bytes metaDataSecondary;
        PaymentSessionStatus status;
        address customer;
    }


    enum PaymentSessionStatus{
        CREATED_NOT_INTERACTED, // 0
        FAILED, // 1
        SUCCEEDED, // 2
        SENT_BUT_NOT_ENOUGH, // 3
        FAILED_CREATE // 4
    }

    // Variables

    string[] private s_availableCryptocurrencyes;
    address[] private s_availableCryptocurrenciesPriceFeed;
    string private s_api_endpoint;
    bytes private s_metaData;
    address private ownerAddress;
    uint256 private s_paymentId = 0;
    AggregatorV3Interface private s_priceFeed;
    PaymentSession[] private s_paymentSessions;
    mapping(string => address) private s_cryptoToPriceFeed;
    mapping(string => address) private s_symbolToTokenAddress;
    mapping(address => uint256) private s_customerToPaymentSessionId;
    uint256 private s_amount;
    address[] private s_tokenAddresses;

    uint256 private constant AMOUNT_DECIMALS = 8;

    event AddNewCryptocurrency(
        string indexed name,
        address indexed priceFeedAddress
    );

    event TakeCryptocurrency(
        uint256 indexed cryptoIndex
    );

    event NewPaymentSession(
        address indexed customer,
        bytes indexed newMetaData
    );

    // Events

    // Modifiers

    modifier OnlyOwner() {
        if(msg.sender != ownerAddress){
            revert PaymentGatewayOneOff__NotOwner();
        }
        _;
    }

    // Functions

    constructor(
        string[] memory availableCryptocurrencies, 
        address[] memory availableCryptocurrenciesPriceFeed, 
        address[] memory tokenAddresses,
        string memory api_endpoint, 
        bytes memory metaData, 
        address owner_address, 
        uint256 amount
        )
    {
        if(!(amount != 0)){
            revert PaymentGatewayOneOff__AmountMustBeBiggerThanZero();
        }
        s_tokenAddresses = tokenAddresses;
        s_amount = amount;
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
            s_cryptoToPriceFeed[s_availableCryptocurrencyes[i]] = availableCryptocurrenciesPriceFeed[i];
            s_symbolToTokenAddress[s_availableCryptocurrencyes[i]] = tokenAddresses[i];
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

    function addNewPaymentSession(bytes memory metaDataSecondary, address customer) public returns(uint256){ // Test
        uint256 paymentId = s_paymentId;
        PaymentSession memory paymentSession = PaymentSession({
            paymentId: paymentId,
            metaDataSecondary: metaDataSecondary,
            status: PaymentSessionStatus.CREATED_NOT_INTERACTED,
            customer: customer
        });
        s_paymentId = paymentId + 1;
        s_paymentSessions.push(paymentSession);
        s_customerToPaymentSessionId[customer] = paymentId;
        emit NewPaymentSession(customer, metaDataSecondary);
        return paymentId;
    }

    /**
     * @param cryptocurrency - The string reprsenting the cryptocurrency symbol you want to pay with. Symbol must be in s_availableCryptocurrencyes array, and subsequently in s_symbolToTokenAddress mapping.
     * @param customer - The customer you want to process the payment of.
     * @notice This function requires that such a transfer of money has already been approved by the customer to the paymentGateway address
     */
    function processPayment(string memory cryptocurrency, address customer) public nonReentrant {
        PaymentSession memory paymentSession = s_paymentSessions[s_customerToPaymentSessionId[customer]];
        address tokenAddress = s_symbolToTokenAddress[cryptocurrency];

        IERC20 tokenContract = IERC20(tokenAddress);

        uint256 balanceCostumer = tokenContract.balanceOf(customer);
        uint256 balanceOwner = tokenContract.balanceOf(ownerAddress);

        uint256 amount = s_amount;

        if(balanceCostumer < amount){
            revert PaymentGatewayOneOff__NotEnoughTokens();
        }

        tokenContract.transferFrom(customer, ownerAddress, amount);

        if((balanceCostumer - amount != tokenContract.balanceOf(customer)) || (balanceOwner + amount != tokenContract.balanceOf(ownerAddress))){
            revert PaymentGatewayOneOff__ErrorInTransfer();
        }

        paymentSession.status = PaymentSessionStatus.SUCCEEDED;

        // api call

        
    }


    // External

    function getAddress() public view returns(address){
        return address(this);
    }

    function getTokenAddressIndex(uint256 index) public view returns(address){
        return s_tokenAddresses[index];
    }

    function getTokenAddressSymbol(string memory symbol) public view returns(address){
        return s_symbolToTokenAddress[symbol];
    }

    function getPaymentSession(uint256 index) public view returns(PaymentSession memory){
        return s_paymentSessions[index];
    }

    function getPaymentSessionCostumer(uint256 index) public view returns(address){
        return s_paymentSessions[index].customer;
    }

    function getPaymentSessionMetaData(uint256 index) public view returns(bytes memory){
        return s_paymentSessions[index].metaDataSecondary;
    }

    function getPaymentSessionStatus(uint256 index) public view returns(uint256){
        return uint256(s_paymentSessions[index].status);
    }

    // Payment session id is equal to its index

    function addCryptocurrencies(address priceFeedAddress, string calldata symbol, address tokenAddress)
        external
        OnlyOwner
    {   
        s_availableCryptocurrencyes.push(symbol);
        s_availableCryptocurrenciesPriceFeed.push(priceFeedAddress);
        s_tokenAddresses.push(tokenAddress);
        s_cryptoToPriceFeed[symbol] = priceFeedAddress;
        s_symbolToTokenAddress[symbol] = tokenAddress;
        emit AddNewCryptocurrency(symbol, priceFeedAddress);
    }

    function takeCryptoCurrencies(uint256 index)
        external 
        OnlyOwner
    {
        s_availableCryptocurrencyes[index] = s_availableCryptocurrencyes[s_availableCryptocurrencyes.length-1];
        s_availableCryptocurrencyes.pop();

        s_availableCryptocurrenciesPriceFeed[index] = s_availableCryptocurrenciesPriceFeed[s_availableCryptocurrenciesPriceFeed.length-1];
        s_availableCryptocurrenciesPriceFeed.pop();

        s_tokenAddresses[index] = s_tokenAddresses[s_tokenAddresses.length-1];
        s_tokenAddresses.pop();

        emit TakeCryptocurrency(index);
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

    function changeOwner(address newOwner)
        external
        OnlyOwner
    {
        ownerAddress = newOwner;
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

    function findCryptocurrencyIndex(string memory cryptocurrency)
        external
        view
        returns(uint256)
    {
        uint256 length = s_availableCryptocurrencyes.length;
        for(uint256 i=0; i< length; i++){
            if(keccak256(abi.encodePacked(cryptocurrency)) == keccak256(abi.encodePacked(s_availableCryptocurrencyes[i]))){
                return i;
            }
        }
        return type(uint256).max;
    }

    function getPaymentSessions(uint256 index) // Write test
        external 
        view
        OnlyOwner
        returns(PaymentSession memory)
    {
        return s_paymentSessions[index];
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