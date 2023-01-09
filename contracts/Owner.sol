// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NotaryContractBase.sol";

contract Owner is NotaryContractBase {

    mapping(address => OwnerInfo) public ownerMap;

    function addOwner(string memory _tcknOrVkn, string memory _fullName) public {
         ownerMap[msg.sender] = OwnerInfo(msg.sender, _tcknOrVkn, _fullName, true, Rol.USER);
    }

    function addAdmin(string memory _tcknOrVkn, string memory _fullName) public {
         ownerMap[msg.sender] = OwnerInfo(msg.sender, _tcknOrVkn, _fullName, true, Rol.ADMIN);
    }

    function isOwnerRegistered(address ownAdd) public view returns(bool){
        return ownerMap[ownAdd].registered;
    }

    function isAdmin(address add) public view returns(bool){
      return ownerMap[add].rol == Rol.ADMIN;
    }
  
}
