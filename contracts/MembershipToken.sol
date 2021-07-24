pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MembershipToken is ERC20 {
    constructor() ERC20('MembershipToken', 'MBT') {
        _mint(msg.sender, 1000);
    }
}