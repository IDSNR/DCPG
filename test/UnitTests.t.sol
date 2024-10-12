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

    address immutable USER = makeAddr("user");
    address immutable OWNER_DCPG;
    string private API_ENDPOINT;

    constructor(){
        OWNER_DCPG = 0xc1cCaEEF257Ff506f27d0769C0662805259e27f6;
        API_ENDPOINT = "https://indertct.me/api/crypto_payment";
    }

    uint256 constant DECIMALS = 8;

    function setUp() public {
        
        vm.deal(USER, 10 ether);
        vm.deal(OWNER_DCPG, 10 ether);

        (dcpg, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig(); // Access the struct, no function call
        
        arrayOfPriceFeedAddresses = config.priceFeedAddresses; // Correct struct access
        nameOfSymbols = config.nameOfSymbols; // Correct struct access
        numberCryptocurrencies = config.numberCryptocurrencies; // Correct struct access

        assertEq(nameOfSymbols.length, arrayOfPriceFeedAddresses.length);
        assertEq(nameOfSymbols.length, numberCryptocurrencies);
        assertEq(arrayOfPriceFeedAddresses.length, numberCryptocurrencies);
    }

    function testGetPrice() public {
        (uint256 absPriceAsset) = dcpg.getPrice(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);

        uint256 priceTwoAsset = absPriceAsset * 2;
        uint256 priceValue = absPriceAsset - 60000 * 10 ** DECIMALS;

        uint256 priceTwoAssetsReally = dcpg.getPriceWAmount(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, 2);

        // Ensure that priceValue is non-negative (no need to check again since we are using uint256)
        assert(priceValue < 5000 * 10 ** DECIMALS);
        assertEq(priceTwoAssetsReally, priceTwoAsset);
    }

    function testHelperConfig() public view {
        assertEq(numberCryptocurrencies, 5);
        assertEq(nameOfSymbols.length, 5);
        assertEq(arrayOfPriceFeedAddresses.length, 5);
    }

    function testBasicGetterFunctionsDCPG() public view {
        assertEq(arrayOfPriceFeedAddresses[0], dcpg.getAvailablePriceFeedIndexes(0));
        assertEq(nameOfSymbols[0], dcpg.getAvailableCryptocurrencies(0));
        assertEq(arrayOfPriceFeedAddresses[0], dcpg.getPriceFeedOnCryptocurrency(nameOfSymbols[0]));
        assertEq(dcpg.getDecimals(), DECIMALS);
    }

    function testCreateNewPaymentAndPaymentGateway() public {
        vm.prank(USER);
        uint256 user_paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, 0, API_ENDPOINT, abi.encodePacked("The1stOne"));

        vm.prank(OWNER_DCPG);
        uint256 owner_paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, 0, API_ENDPOINT, abi.encodePacked("The2ndOne"));

        nameOfSymbols.push("AIAI");

        vm.expectRevert(PaymentGatewayOneOff.PaymentGatewayOneOff__NotSameSize.selector);
        vm.prank(USER);
        uint256 owner_Paymentgateway_id = dcpg.createNewPaymentGatewayOneOff(nameOfSymbols, arrayOfPriceFeedAddresses, 0, API_ENDPOINT, abi.encodePacked("The2ndOne"));

        nameOfSymbols.pop();

        vm.expectRevert();
        vm.prank(USER);
        address payment_gatewayaddress = dcpg.getPaymentGatewayAddressOnid(owner_paymentgateway_id);

        vm.prank(USER);
        address payment_gatewayAddress = dcpg.getPaymentGatewayAddressOnid(user_paymentgateway_id);
        
        console.log(payment_gatewayAddress);

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



    }

    function testProxyDCPG() public {
        vm.prank(OWNER_DCPG);
        dcpg.addCryptocurrency(address(0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9), "AUD");

        assertEq(dcpg.getPriceFeedOnCryptocurrency("AUD"), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
        assertEq(dcpg.getAvailableCryptocurrencies(5), "AUD");
        assertEq(dcpg.getAvailablePriceFeedIndexes(5), 0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);

        vm.expectRevert(DCPG.DCPG__IsNotOwner.selector);
        vm.prank(USER);
        dcpg.takeCryptocurrency(5);

        vm.prank(OWNER_DCPG);
        dcpg.takeCryptocurrency(5);

        vm.expectRevert();
        vm.prank(OWNER_DCPG);
        string memory aud = dcpg.getAvailableCryptocurrencies(5);

    }
}