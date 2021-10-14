pragma solidity ^0.5.0;
import "@openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/ownership/Secondary.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/** for deployment
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Secondary.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";
 */
pragma solidity ^0.5.0;



/**
 * @title PostDeliveryCrowdsale modified with finalization and whitelist
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    __unstable__TokenVault public vault;

    bool public finalized = false;

    mapping(address => bool) public whitelisted;

    // MAX CONTRIBUTION: 950k PP = 1 BNB
    uint256 public maxContributionInToken = 950000 * (10**18);

    constructor() public {
        vault = new __unstable__TokenVault();
    }

    /**
        @notice Call to finalize presale
        @dev Once the presale is finalized and time's over, everyone can claim their tokens
     */
    function finalize() external onlyOwner {
        finalized = true;
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address beneficiary) public {
        require(finalized, "Presale hasn't been finalized yet!");
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        uint256 amount = balances[beneficiary];
        require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");

        balances[beneficiary] = 0;
        vault.transfer(token(), beneficiary, amount);
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        require(whitelisted[beneficiary], "Address not whitelisted!");
        require(balances[beneficiary].add(tokenAmount) <= maxContributionInToken, "Purchased amount exceeds max contribution!");
        balances[beneficiary] = balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(vault), tokenAmount);
    }

    /**
        @notice Whitelists provided address
        @param _account Address to be whitelisted
     */
    function whitelistAddress(address _account) external onlyOwner {
        whitelisted[_account] = true;
    }

    /**
        @notice Whitelists provided addresses
     */
    function whitelistMultipleAddresses(address[] calldata _accounts) external onlyOwner {
        for (uint256 index = 0; index < _accounts.length; index++) {
            whitelisted[_accounts[index]] = true;
        }
    }

    /**
        @notice Withdraws unsold token which can be then burned, or locked in the treasury
     */
    function withdrawUnsold() external onlyOwner {
        require(hasClosed(), "Presale is still active!");
        IERC20(token()).transfer(owner(), IERC20(token()).balanceOf(address(this)));
    }

}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}

contract PpPresale is Crowdsale, TimedCrowdsale, PostDeliveryCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;
    uint256 private _openingTime = 1634313600; // Fri Oct 15 2021 16:00:00 GMT+0000
    uint256 private _closingTime = 1634486400; // Sun Oct 17 2021 16:00:00 GMT+0000 
    address public PPTokenAddress = 0xD4b52510719C594514CE7FED6CC876C03278cCf8; 
    uint256 private _rate = 950000; // PP/BNB rate
    constructor ()
     CappedCrowdsale(200 * (10**18)) //HARDCAP 200 BNB
     TimedCrowdsale(_openingTime, _closingTime)
     Crowdsale(_rate, msg.sender, IERC20(PPTokenAddress))
     PostDeliveryCrowdsale()
     public
    {}

}