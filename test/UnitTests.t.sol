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


// imports

import {Test, console} from "forge-std/Test.sol";
import {DCPG} from "../src/DCPG.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployScript} from "../script/Deploy.s.sol";
import {PaymentGatewayOneOff} from "../src/PaymentGateway.sol";

contract TestGetPrice is Test {
    
    DCPG dcpg;
    HelperConfig helperConfig;

    DeployScript deployer = new DeployScript();
    
    address[] public arrayOfPriceFeedAddresses;
    uint256 public numberCryptocurrencies;
    string[] public nameOfSymbols;
    address[] public arrayOfTokenAddresses;
    
    uint256[] private methodsAllowed = [0];
    address immutable USER = makeAddr("user");
    address immutable OWNER_DCPG;
    string private API_ENDPOINT;
    PaymentGatewayOneOff private s_paymentGatewayOneOff;
    bytes private DEFAULT_METADATA;
    uint256 immutable DEFAULT_AMOUNT;
    bytes private EMPTY_METADATA;

    constructor(){
        OWNER_DCPG = 0xc1cCaEEF257Ff506f27d0769C0662805259e27f6;
        API_ENDPOINT = "https://indertct.me/api/crypto_payment";
        DEFAULT_METADATA = abi.encodePacked("{'message': 'You will win!'}");
        DEFAULT_AMOUNT = 50;
        EMPTY_METADATA = abi.encodePacked("");
    }

    uint256 constant DECIMALS = 8;

    function setUp() public {
        
        vm.deal(USER, 10 ether);
        vm.deal(OWNER_DCPG, 10 ether);

        (dcpg, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig(); 
        
        arrayOfPriceFeedAddresses = config.priceFeedAddresses; 
        nameOfSymbols = config.nameOfSymbols;
        numberCryptocurrencies = config.numberCryptocurrencies; 
        arrayOfTokenAddresses = config.tokenAddresses;

        assertEq(nameOfSymbols.length, arrayOfPriceFeedAddresses.length);
        assertEq(nameOfSymbols.length, numberCryptocurrencies);
        assertEq(arrayOfPriceFeedAddresses.length, numberCryptocurrencies);

        vm.prank(USER);
        uint256 paymentGatewayId = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, 0, API_ENDPOINT, DEFAULT_METADATA, DEFAULT_AMOUNT);
        vm.prank(USER);
        address paymentGatewayAddress = dcpg.getPaymentGatewayAddressOnid(paymentGatewayId);

        s_paymentGatewayOneOff = PaymentGatewayOneOff(paymentGatewayAddress);
    }

    function testMethodVariety(uint256 method) public {
        bool isAllowed = false;
        for(uint256 i=0; i<methodsAllowed.length; i++){
            if (methodsAllowed[i] == method){
                isAllowed = true;
            }
        }
        if(!isAllowed){
            vm.expectRevert(DCPG.DCPG__MethodNotAllowed.selector);
            dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, method, API_ENDPOINT, DEFAULT_METADATA, DEFAULT_AMOUNT);
        }
    }

    function testGetPrice(uint8 amount) public {
        (uint256 absPriceAsset) = dcpg.getPrice(arrayOfPriceFeedAddresses[uint256(amount) % arrayOfPriceFeedAddresses.length]);

        uint256 priceTwoAsset = absPriceAsset * uint256(amount);

        uint256 priceTwoAssetsReally = dcpg.getPriceWAmount(arrayOfPriceFeedAddresses[uint256(amount) % arrayOfPriceFeedAddresses.length], uint256(amount));

        // Ensure that priceValue is non-negative (no need to check again since we are using uint256)
        assertEq(priceTwoAssetsReally, priceTwoAsset);
    }

    function testPaymentSession() public {
        uint256 paymentSessionId = s_paymentGatewayOneOff.addNewPaymentSession(DEFAULT_METADATA, USER);
        PaymentGatewayOneOff.PaymentSession memory paymentSession = s_paymentGatewayOneOff.getPaymentSession(paymentSessionId);

        address customer = paymentSession.customer;
        address customer_ = s_paymentGatewayOneOff.getPaymentSessionCostumer(paymentSessionId);
        assertEq(customer, customer_);
        assertEq(customer, USER);

        bytes memory metadata = paymentSession.metaDataSecondary;
        bytes memory metadata_ = s_paymentGatewayOneOff.getPaymentSessionMetaData(paymentSessionId);
        assertEq(metadata, metadata_);
        assertEq(metadata, DEFAULT_METADATA);

        uint256 status = uint256(paymentSession.status);
        uint256 status_ = s_paymentGatewayOneOff.getPaymentSessionStatus(paymentSessionId);
        assertEq(status, status_);
        assertEq(status_, 0);

    }

    function testFindCryptocurrencyIndexPaymentGateway(uint256 random_n) public view {
        assertEq(s_paymentGatewayOneOff.findCryptocurrencyIndex(nameOfSymbols[random_n % nameOfSymbols.length]), random_n % nameOfSymbols.length);
    }

    function testHelperConfig() public view {
        assertEq(numberCryptocurrencies, 5);
        assertEq(nameOfSymbols.length, 5);
        assertEq(arrayOfPriceFeedAddresses.length, 5);
    }

    function testPaymentGatewayNotZero() public {
        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__AmountMustBeBiggerThanZero.selector);
        vm.prank(USER);
        uint256 user_paymentgateway_id_ = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, 0, API_ENDPOINT, abi.encodePacked("The1stOne"), 0);
    }

    function testTokenAddresses() public {
        vm.expectRevert();
        vm.prank(USER);
        dcpg.getTokenAddress(5);

        vm.expectRevert();
        vm.prank(USER);
        s_paymentGatewayOneOff.getTokenAddressIndex(5);

    }

    function testGetPriceOnPaymentGatewayOneOff(uint8 amount) public {
        (uint256 absPriceAsset) = s_paymentGatewayOneOff.getPrice(arrayOfPriceFeedAddresses[uint256(amount) % arrayOfPriceFeedAddresses.length]);

        uint256 priceTwoAsset = absPriceAsset * uint256(amount);

        uint256 priceTwoAssetsReally = s_paymentGatewayOneOff.getPriceWAmount(arrayOfPriceFeedAddresses[uint256(amount) % arrayOfPriceFeedAddresses.length], uint256(amount));

        // Ensure that priceValue is non-negative (no need to check again since we are using uint256)
        assertEq(priceTwoAssetsReally, priceTwoAsset);
    }

    function testBasicGetterFunctionsDCPG() public view {
        assertEq(8, dcpg.getDecimals());
        assertEq(arrayOfPriceFeedAddresses[0], dcpg.getAvailablePriceFeedIndexes(0));
        assertEq(nameOfSymbols[0], dcpg.getAvailableCryptocurrencies(0));
        assertEq(arrayOfPriceFeedAddresses[0], dcpg.getPriceFeedOnCryptocurrency(nameOfSymbols[0]));
        assertEq(dcpg.getDecimals(), DECIMALS);
    }

    function testCreateNewPaymentAndPaymentGateway() public {
        vm.prank(USER);
        uint256 user_paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, 0, API_ENDPOINT, abi.encodePacked("The1stOne"), DEFAULT_AMOUNT);

        vm.prank(OWNER_DCPG);
        uint256 owner_paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, 0, API_ENDPOINT, abi.encodePacked("The2ndOne"), DEFAULT_AMOUNT);

        nameOfSymbols.push("AIAI");

        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotSameSize.selector);
        vm.prank(USER);
        uint256 owner_Paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, arrayOfTokenAddresses, 0, API_ENDPOINT, abi.encodePacked("The2ndOne"), DEFAULT_AMOUNT);

        nameOfSymbols.pop();

        vm.expectRevert();
        vm.prank(USER);
        address payment_gatewayaddress = dcpg.getPaymentGatewayAddressOnid(owner_paymentgateway_id);

        vm.prank(USER);
        address payment_gatewayAddress = dcpg.getPaymentGatewayAddressOnid(user_paymentgateway_id);

        PaymentGatewayOneOff paymentGateway = PaymentGatewayOneOff(payment_gatewayAddress);
        
        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotOwner.selector);
        vm.prank(OWNER_DCPG);
        string memory api_Endpoint = paymentGateway.getApiEndpoint();

        vm.prank(USER);
        string memory api_endpoint = paymentGateway.getApiEndpoint();

        assertEq(api_endpoint, API_ENDPOINT);

        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotOwner.selector);
        vm.prank(OWNER_DCPG);
        bytes memory metaData = paymentGateway.getMetadata();

        vm.prank(USER);
        bytes memory metadata = paymentGateway.getMetadata();

        assertEq(metadata, abi.encodePacked("The1stOne"));

        vm.prank(USER);
        assertEq(paymentGateway.getCryptocurrencies(0), nameOfSymbols[0]);
        vm.prank(USER);
        address contractAddpf = paymentGateway.getPriceFeedCryptoCurrencies(nameOfSymbols[0]);
        vm.prank(USER);
        address realadddr = paymentGateway.getPriceFeeds(0);
        assertEq(contractAddpf, realadddr);

        // Proxy paymentGateway tests

        string memory NEW_API_ENDPOINT = "https:/new.api/endpoint";

        vm.prank(USER);
        paymentGateway.changeApiEndpoint(NEW_API_ENDPOINT);
        vm.prank(USER);
        assertEq(paymentGateway.getApiEndpoint(), NEW_API_ENDPOINT);
        
        bytes memory NEW_METADATA = abi.encodePacked("Ok, let's see if I can do this");

        vm.prank(USER);
        paymentGateway.changeMetadata(NEW_METADATA);
        vm.prank(USER);
        assertEq(paymentGateway.getMetadata(), NEW_METADATA);

        vm.prank(USER);
        paymentGateway.changeOwner(OWNER_DCPG);

        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotOwner.selector);
        vm.prank(USER);
        address test__ = paymentGateway.getPriceFeeds(0);

        vm.prank(OWNER_DCPG);
        paymentGateway.changeOwner(USER);

        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotOwner.selector);
        vm.prank(OWNER_DCPG);
        address test___ = paymentGateway.getPriceFeeds(0);  

        vm.prank(USER);
        paymentGateway.addCryptocurrencies(0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9, "AUD", 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);
        vm.prank(USER);
        assertEq(paymentGateway.getPriceFeedCryptoCurrencies("AUD"), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
        vm.prank(USER);
        assertEq(paymentGateway.getCryptocurrencies(5), "AUD");
        vm.prank(USER);
        assertEq(paymentGateway.getPriceFeeds(5), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
        vm.prank(USER);
        assertEq(paymentGateway.getTokenAddressIndex(5), 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);
        vm.prank(USER);
        assertEq(paymentGateway.getTokenAddressSymbol("AUD"), 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);

        vm.prank(USER);
        paymentGateway.takeCryptoCurrencies(5);
        vm.expectRevert();
        vm.prank(USER);
        paymentGateway.getCryptocurrencies(5);
        vm.expectRevert();
        vm.prank(USER);
        paymentGateway.getTokenAddressIndex(5);
        vm.expectRevert();
        vm.prank(USER);
        paymentGateway.getTokenAddressIndex(5);
    }

    function testProxyDCPG() public {
        vm.prank(OWNER_DCPG);
        dcpg.addCryptocurrency(address(0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9), "AUD", 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);

        assertEq(dcpg.getPriceFeedOnCryptocurrency("AUD"), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
        assertEq(dcpg.getAvailableCryptocurrencies(5), "AUD");
        assertEq(dcpg.getAvailablePriceFeedIndexes(5), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
        assertEq(dcpg.getTokenAddress(5), 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);
        assertEq(dcpg.getTokenAddressOnCryptocurrency("AUD"), 0x3Cef98bb43d732E2F285eE605a8158cDE967D219);

        vm.expectRevert(DCPG.DCPG__IsNotOwner.selector);
        vm.prank(USER);
        dcpg.takeCryptocurrency(5);

        vm.prank(OWNER_DCPG);
        dcpg.takeCryptocurrency(5);

        vm.expectRevert();
        dcpg.getAvailableCryptocurrencies(5);
        vm.expectRevert();
        dcpg.getTokenAddress(5);
        vm.expectRevert();
        dcpg.getAvailablePriceFeedIndexes(5);

    }

    function testAddress() public view {
        assertEq(address(s_paymentGatewayOneOff), s_paymentGatewayOneOff.getAddress());
    }
}