pragma solidity ^0.5.9;

contract HelloWorld {

    string public yourName = "Hello, World!";

    constructor() public {
        yourName = "Unknown";
    }

    function setName(string memory nm) public {
        yourName = nm;
    }
}
