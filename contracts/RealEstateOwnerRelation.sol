// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstate.sol";
import "./NotaryContractBase.sol";

contract RealEstateOwnerRelation is NotaryContractBase{
    Owner ownerContract;
    RealEstate realEstateContract;

    mapping(address => uint []) public ownerHisseIdMap;
    
    mapping(uint => RealEstateHisse) public realEstateIdHisseMap;
    mapping(uint => Hisse) public hisseIdHisseMap;

    event NewHisseAndRealEstateAdded(uint realEstateId, uint hisseId, address owner);
    event OwnerHissePayAdded(uint realEstateId, uint hisseId, address owner);
    event NewHisseAddedToRealEstate(uint realEstateId, uint hisseId, address owner);
    event OwnerShipChanged(uint hiseId, address oldOwner, address newOwner);
    
    constructor(address realEstateContractAdd, address ownerContractAdd)  {
        ownerContract=Owner(ownerContractAdd);
        realEstateContract=RealEstate(realEstateContractAdd);
    }

    function testOwnerShip(uint realEstateId) public{
        addOwnerShip(msg.sender, realEstateId, 1);        
    }
    
    function addOwnerShip(address ownAdd, uint realEstateId, uint _hisse) public {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        require(realEstateContract.isRealEstateRegisted(realEstateId), "Real estate does not exist in the system");   
         
        RealEstateHisse storage realEstateHisse = realEstateIdHisseMap[realEstateId];
        uint payda = realEstateContract.getRealEstatePayda(realEstateId);
        if(realEstateHisse.registered){
            require(realEstateHisse.toplamHisseMiktar + _hisse <= payda, "No more shareholders can be added to the real estate");
            uint hisseId = getOwnerHisseId(ownAdd, realEstateHisse.hisseIdList);
            if(hisseId != 0){
                hisseIdHisseMap[hisseId].pay += _hisse;
                emit OwnerHissePayAdded(realEstateId, hisseId, ownAdd);
            }else{
                uint newHisseId=hisseOlustur(_hisse, realEstateId, ownAdd);
                realEstateHisse.hisseIdList.push(newHisseId);
                emit NewHisseAddedToRealEstate(realEstateId, newHisseId, ownAdd);
            }
            realEstateHisse.toplamHisseMiktar += _hisse;
            realEstateIdHisseMap[realEstateId] = realEstateHisse;
        }else{
            require(_hisse <= payda,  "No more shareholders can be added to the real estate");
            realEstateHisse.payda = payda;
            realEstateHisse.toplamHisseMiktar= _hisse;
            realEstateHisse.registered =true;
            uint newHisseId=hisseOlustur(_hisse, realEstateId, ownAdd);
            realEstateHisse.hisseIdList.push(newHisseId);
            emit NewHisseAndRealEstateAdded(realEstateId, newHisseId, ownAdd);
        }
        
    }

    function hisseOlustur(uint _hisse, uint realEstateId, address ownAdd) private returns (uint) {
        uint newHisseId=block.timestamp;
        Hisse memory newHisse = Hisse(_hisse, realEstateId, ownAdd, true);
        hisseIdHisseMap[newHisseId] = newHisse;            
        ownerHisseIdMap[ownAdd].push(newHisseId);   
        return newHisseId;
    }

    function getOwnerHisseId(address ownAdd, uint[] memory hisseIdList) public view returns(uint) {
        for(uint i = 0; i< hisseIdList.length; i++){
            uint hisseId = hisseIdList[i];
            if(hisseIdHisseMap[hisseId].ownerAdd == ownAdd){
                return hisseId;
            }
        }
        return 0;
    }

    function changeOwnerShip(uint hisseId, address newOwner) public {
        Hisse memory hisse  = hisseIdHisseMap[hisseId];
        require(hisse.registered, "Hisse bulunamadi");
        //require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");

        hisseIdHisseMap[hisseId].ownerAdd = newOwner;
        
        uint[] memory hisseIdList = ownerHisseIdMap[msg.sender];
        for(uint i = 0; i<hisseIdList.length; i++){
            if(hisseIdList[i] == hisseId){
                ownerHisseIdMap[msg.sender][i] = 0;
            } 
        }
        ownerHisseIdMap[newOwner].push(hisseId);
        
        emit OwnerShipChanged(hisseId, msg.sender, newOwner);
    }

    function hisseSatisaCikabilirMi(uint hisseId, address ownAdd) public view returns(bool){
        Hisse memory hisse  = hisseIdHisseMap[hisseId];
        return hisse.registered && hisse.ownerAdd == ownAdd;
    }

    function getOwnerHisseId(address ownAdd, uint index) public view returns(uint){
        return ownerHisseIdMap[ownAdd][index];
    }

    function getOwnerHisseLength(address ownAdd) public view returns(uint){
        return ownerHisseIdMap[ownAdd].length;
    }

    function getHisse(uint hisseId) public view returns(Hisse memory){
        return hisseIdHisseMap[hisseId];
    }

    function getHisseInfos(address ownAdd) public view returns (Hisse[] memory){
           uint [] memory hisseIds = ownerHisseIdMap[ownAdd];
           Hisse [] memory result = new Hisse[](hisseIds.length);
           for(uint i = 0; i< hisseIds.length; i++){
               result[i] = hisseIdHisseMap[hisseIds[i]];
           }
           return result;            
    }

}