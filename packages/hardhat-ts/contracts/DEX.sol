// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    IERC20 token; //instantiates the imported contract

    uint256 public totalLiquidity; //total liquidity in the contract
    mapping (address => uint256) public liquidity; //liquidity per address

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address indexed sender, uint256 ethAmount, uint256 tokenAmount);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address indexed sender, uint256 tokenAmount, uint256 ethAmount);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address indexed sender, uint256 liquidityMinted, uint256 ethIn, uint256 tokenIn);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(address indexed sender, uint256 liquidityBurned, uint256 ethOut, uint256 tokenOut);

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already initialized");
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: transferFrom failed");

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = xReserves * 1000 + xInputWithFee;
        yOutput = numerator / denominator;
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     *
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    function ethReserves() public view returns (uint256) {
        return address(this).balance;
    }

    function tokenReserves() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */

    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "DEX: ethToToken: must send ETH");
        uint256 tokenReserve = tokenReserves();
        uint256 ethReserve = ethReserves();
        tokenOutput = price(msg.value, ethReserve, tokenReserve);
        token.transfer(msg.sender, tokenOutput);
        emit EthToTokenSwap(msg.sender, msg.value, tokenOutput);
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "DEX: tokenToEth: must send tokens");
        uint256 tokenReserve = tokenReserves();
        uint256 ethReserve = ethReserves();
        ethOutput = price(tokenInput, tokenReserve, ethReserve);
        token.transferFrom(msg.sender, address(this), tokenInput);
        payable(msg.sender).transfer(ethOutput);
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
    }

    
    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokenDeposit) {
        uint256 tokenReserve = tokenReserves();
        uint256 ethReserve = ethReserves() - msg.value;
        uint256 tokenDeposit = msg.value * tokenReserve / ethReserve;

        uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenDeposit), "DEX: deposit: transferFrom failed");
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public returns (uint256 ethWithdrawn, uint256 tokenWithdrawn) {
        require(amount > 0, "DEX: withdraw: must withdraw more than 0");
        require(amount <= liquidity[msg.sender], "DEX: withdraw: not enough liquidity");

        uint256 ethWithdrawn = (amount * ethReserves()) / totalLiquidity;
        uint256 tokenWithdrawn = (amount * tokenReserves()) / totalLiquidity;
        totalLiquidity -= amount;
        (bool sent, ) = msg.sender.call{value: ethWithdrawn}("");
        require(sent, "DEX: withdraw: failed to send ETH");
        require(token.transfer(msg.sender, tokenWithdrawn), "DEX: withdraw: failed to send token");
        emit LiquidityRemoved(msg.sender, amount, ethWithdrawn, tokenWithdrawn);
    }
}