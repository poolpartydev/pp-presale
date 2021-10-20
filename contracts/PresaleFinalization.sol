// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/Ownable.sol";
import "./IUniswapV2Router.sol";

interface IPresale {
    // Function that finalizes the Pinksale presale
    function finalize() public;
}

interface IPP {
    // Enters after presale state - from now on
    // there will be tax and addition of liquidity over 1M $PP won't be possible
    function enterAfterPresaleState() public;
}

/**
    @notice Simple helper to do all function calls connected with presale finalization in one transaction
    @author kefas
    @dev BNB and $PP must be sent to this contract before calling the finalize presale
 */
contract PresaleFinalization is Ownable {

    // Contract address of the presale hosted on pinksale
    address public pinksalePresaleAddress = address(0);
    // Contract address of the presale hosted on our platform poolparty.investments
    address public ownPresaleAddress = address(0);
    // PP token address
    address public ppAddress = address(0);
    // Pancakeswap router address
    address public routerAddress = address(0)

    /**
        @notice Finalizes both pinksale and own presale, 
                adds liquidity raised in own presale to pancakeswap,
                and enters after presale state on $PP contract

     */
    function finalizePresale() external onlyOwner {
        require(address(this).balance != 0, "BNB must be deposited first!");
        IPresale(pinksalePresaleAddress).finalize();
        IPresale(ownPresaleAddress).finalize();
        _addLiquidityToPancake();
        IPP(ppAddress).enterAfterPresaleState();
    }

    function _addLiquidityToPancake() private {
        IERC20(ppAddress).approve(routerAddress, type(uint256).max);

        // add the liquidity
        IUniswapV2Router02.addLiquidityETH{value: address(this).balance}(
            address(this),
            IERC20(ppAddress).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}