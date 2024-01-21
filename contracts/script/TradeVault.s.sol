// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TradeVault.sol";
import "../src/MockERC20.sol";

contract DeployTradeVault is Script {
    function run() external {
        vm.startBroadcast();

        MockERC20 assetToken = new MockERC20("Asset Token", "ASSET", 18);

        // Parameters for TradeVault deployment
        address assetTokenAddress = address(assetToken);
        uint256 assetToCashRate = 1e18;  // Example rate
        uint256 cashValuationCap = 1e24; // Example cap

        // Deploy the TradeVault contract
        TradeVault tradeVault = new TradeVault(assetTokenAddress, assetToCashRate, cashValuationCap, "TradeVault", "TVT");

        vm.stopBroadcast();
    }
}
