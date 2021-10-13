// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor () ERC20() public {
        _mint(msg.sender, 1000000000 * 10**18);
    }
}
