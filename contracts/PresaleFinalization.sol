// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";

interface IPresale {
    // Function that finalizes the Pinksale presale
    function finalize() external;
}

interface IPP {
    // Enters after presale state - from now on
    // there will be tax and addition of liquidity over 1M $PP won't be possible
    function enterAfterPresaleState() external;
}

/**
    @notice Simple helper to do all function calls connected with presale finalization in one transaction
    @author kefas
    @dev BNB and $PP must be sent to this contract before calling the finalize presale
 */
contract PresaleFinalization is Ownable {

    // Contract address of the presale hosted on pinksale
    address public pinksalePresaleAddress = 0x7d97c30E59F0c3108abf8a6Ed62B1B7A8a0BCa5c;
    // Contract address of the presale hosted on our platform poolparty.investments
    address public ownPresaleAddress = 0x653b3901E1611108a4237504a496CA40262c798d;
    // PP token address
    address public ppAddress = 0xD4b52510719C594514CE7FED6CC876C03278cCf8;
    // Pancakeswap router address
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    receive() external payable {
        // Raised BNB will be sent to owner
        if (msg.sender != owner()) {
            (bool sent, ) = owner().call{value: msg.value}("");
            require(sent, "PP Presale Finalization: Forwarding BNB failed.");
        }
    }

    /**
        @notice Finalizes both pinksale and own presale, 
                adds liquidity raised in own presale to pancakeswap,
                and enters after presale state on $PP contract
        @dev This contract must own both presale and PP token,
             otherwise the finalization will fail

     */
    function finalizePresale() external onlyOwner {
        require(address(this).balance != 0, "BNB for LP must be deposited first!");
        require(IERC20(ppAddress).balanceOf(address(this)) != 0, "$PP for LP must be deposited first!");
        IPresale(pinksalePresaleAddress).finalize();
        IPresale(ownPresaleAddress).finalize();
        _addLiquidityToPancake();
        IPP(ppAddress).enterAfterPresaleState();
        Ownable(ppAddress).transferOwnership(owner());
    }

    function transferOwnershipOfOwnedToOwner(address _contract) external onlyOwner {
        Ownable(_contract).transferOwnership(owner());
    }
    
    function rescueStuckERC20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
    
    function rescueStuckBNB() external onlyOwner {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "Rescuing stuck BNB failed.");
    }
    

    function _addLiquidityToPancake() private {
        IERC20(ppAddress).approve(routerAddress, type(uint256).max);

        // add the liquidity
        IUniswapV2Router02(routerAddress).addLiquidityETH{value: address(this).balance}(
            ppAddress,
            IERC20(ppAddress).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}