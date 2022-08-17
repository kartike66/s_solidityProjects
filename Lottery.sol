// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract lottery {
    address public owner;
    address payable[] public players;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;

    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(payable(msg.sender));

    }

    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));

    }

    function pickWinner() public onlyOwner {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

}
