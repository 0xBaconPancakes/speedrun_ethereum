//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 0.01 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw = false;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    event Stake(address indexed from, uint256 amount);
    event OpenForWithdraw();

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Staker: already completed");
        _;
    }

    function stake() public payable notCompleted {
        require(timeLeft() > 0, "Staker: deadline passed");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // TODO: After some `deadline` allow anyone to call an `execute()` function
    //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value if the threshold is reached
    function execute() public notCompleted {
        require(timeLeft() == 0, 'Staker: too early');
        if (address(this).balance >= threshold){
            exampleExternalContract.complete{value : address(this).balance}();
        } else {
            openForWithdraw = true;
            emit OpenForWithdraw();
        }
    }

    // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() public notCompleted {
        require(timeLeft() == 0, 'Staker: too early');
        require(openForWithdraw, 'not open for withdraw');
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }

    // TODO: Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
