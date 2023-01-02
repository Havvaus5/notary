// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Owner {

    struct OwnerInfo {
      address  ownerAdd;
      string tcknorVkn;
      string fullName;
      bool registered;
    }
    
    mapping(address => OwnerInfo) ownerMap;

    function addOwner(string memory _tcknOrVkn, string memory _fullName) public {
         ownerMap[msg.sender] = OwnerInfo(msg.sender, _tcknOrVkn, _fullName, true);
    }

    function isOwnerRegistered(address ownAdd) public view returns(bool){
        return ownerMap[ownAdd].registered;
    }
  
}
