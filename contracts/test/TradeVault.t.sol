// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/TradeVault.sol";
import "../contracts/MockERC20.sol";

contract TradeVaultTest is Test {
    TradeVault tradeVault;
    MockERC20 cashToken;
    MockERC20 assetToken;
    address deployer;
    address user1;
    address user2;

    function setUp() public {
        deployer = address(this);
        user1 = address(1);
        user2 = address(2);

        cashToken = new MockERC20("Cash Token", "CASH", 18);
        assetToken = new MockERC20("Asset Token", "ASSET", 18);

        tradeVault = new TradeVault(address(cashToken), address(assetToken), /* other parameters */);
    }

    // Test for updating cash valuation cap
    function testUpdateCashValuationCap() public {
        uint256 newCap = 1000 ether;
        vm.prank(deployer);
        tradeVault.updateCashValuationCap(newCap);
        assertEq(tradeVault.cashValuationCap(), newCap);
    }

    // Test for changing owner
    function testChangeOwner() public {
        vm.prank(deployer);
        tradeVault.changeOwner(payable(user1));
        assertEq(tradeVault.owner(), user1);
    }

    // Test for depositing cash
    function testDepositCash() public {
        uint256 depositAmount = 100 ether;
        cashToken.mint(user1, depositAmount);

        vm.prank(user1);
        cashToken.approve(address(tradeVault), depositAmount);
        tradeVault.depositCash(depositAmount);

        assertEq(cashToken.balanceOf(address(tradeVault)), depositAmount);
    }

    // Test for burning TradeVaultPool tokens
    function testBurnTradeVaultPoolToken() public {
        // Arrange: User1 gets some TradeVaultPool tokens
        uint256 depositAmount = 100 ether;
        cashToken.mint(user1, depositAmount);
        
        vm.startPrank(user1);
        cashToken.approve(address(tradeVault), depositAmount);
        tradeVault.depositCash(depositAmount);

        uint256 burnAmount = 50 ether;  // Example burn amount, adjust based on actual balance
        tradeVault.burnTradeVaultPoolToken(burnAmount);
        vm.stopPrank();
    }


    // Test for depositing asset
    function testDepositAsset() public {
        uint256 depositAmount = 100 ether;
        assetToken.mint(user1, depositAmount);

        vm.prank(user1);
        assetToken.approve(address(tradeVault), depositAmount);
        tradeVault.depositAsset(depositAmount);

        assertEq(assetToken.balanceOf(address(tradeVault)), depositAmount);
    }

    // Test for burning AssetPool tokens
    function testBurnAssetPoolToken() public {
        // Arrange: User1 gets some AssetPool tokens
        uint256 depositAssetAmount = 100 ether;
        assetToken.mint(user1, depositAssetAmount);

        vm.startPrank(user1);
        assetToken.approve(address(tradeVault), depositAssetAmount);
        tradeVault.depositAsset(depositAssetAmount);

        // Assume user1 now has some AssetPool tokens, let's say 50 ether worth.
        // In a real scenario, you would check the exact balance of AssetPool tokens 
        // the user received from depositAsset and use that for burning.

        uint256 burnAmount = 50 ether; // Example burn amount, adjust based on actual balance
        tradeVault.burnAssetPoolToken(burnAmount);
        vm.stopPrank();

        // Assert: Check the state after burning
        // For example, assert that the user's AssetPool token balance has decreased
        // assertEq(assetPoolToken.balanceOf(user1), expectedNewBalance);

        // Also, check if the cash or other asset balances in the contract are updated correctly
        // Depending on your contract's logic, there might be more state changes to assert
    }
}