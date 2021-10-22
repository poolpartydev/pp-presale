pragma solidity ^0.8.0;

interface PinkSale {
    // How much BNB contributed
    function contributionOf(address a) external view returns (uint256);
    // How much tokens got
    function purchasedOf(address a) external view returns (uint256);
}