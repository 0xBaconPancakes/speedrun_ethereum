pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import './YourToken.sol';

contract Vendor is Ownable {
    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) public {
        yourToken = YourToken(tokenAddress);
    }

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    function buyTokens() public payable {
        uint256 amountOfTokens = msg.value * tokensPerEth;
        yourToken.transfer(msg.sender, amountOfTokens);
        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function sellTokens(uint256 amountOfTokens) public {
        require(yourToken.balanceOf(msg.sender) >= amountOfTokens, "Not enough tokens");
        uint256 amountOfETH = amountOfTokens / tokensPerEth;
        yourToken.transferFrom(msg.sender, address(this), amountOfTokens);
        payable(msg.sender).transfer(amountOfETH);
        emit SellTokens(msg.sender, amountOfTokens, amountOfETH);
    }
}
