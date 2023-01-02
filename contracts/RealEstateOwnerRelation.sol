// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstate.sol";

contract RealEstateOwnerRelation {
    Owner ownerContract;
    RealEstate realEstateContract;

    struct Hisse {
        uint pay;  
       //string edinmeSebebi; //TODO enum
        //uint edinmeZamani;
        uint realEstateId;
        address ownerAdd;
        bool registered;
    }

    struct RealEstateHisse{
        bool registered;
        uint payda;
        uint toplamHisseMiktar;
        uint [] hisseIdList;
    }
 
    mapping(address => mapping(uint => bool)) public ownerHisseListMap;

    mapping(uint => RealEstateHisse) public realEstateIdHisseMap;
    mapping(uint => Hisse) public hisseIdHisseMap;

    event NewHisseAndRealEstateAdded(uint realEstateId, uint hisseId, address owner);
    event OwnerHissePayAdded(uint realEstateId, uint hisseId, address owner);
    event NewHisseAddedToRealEstate(uint realEstateId, uint hisseId, address owner);
    event OwnerShipChanged(uint hiseId, address oldOwner, address newOwner);

    
    constructor(address realEstateContractAdd)  {
        //ownerContract=Owner(ownerContractAdd);
        realEstateContract=RealEstate(realEstateContractAdd);
    }

    function testOwnerShip(uint realEstateId) public{
        addOwnerShip(msg.sender, realEstateId, 1);        
    }
    
    function addOwnerShip(address ownAdd, uint realEstateId, uint _hisse) public {
        //TODO sadece admin yapabilsin
        //require(ownerContract.isOwnerRegistered(ownAdd), "Owner does not exist in system");
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
                uint newHisseId=block.timestamp;
                realEstateHisse.hisseIdList.push(newHisseId);
                Hisse memory newHisse = Hisse(_hisse,realEstateId, ownAdd, true);
                hisseIdHisseMap[newHisseId] = newHisse;    
                ownerHisseListMap[ownAdd][newHisseId] = true;
                emit NewHisseAddedToRealEstate(realEstateId, newHisseId, ownAdd);
            }
            realEstateHisse.toplamHisseMiktar += _hisse;
            realEstateIdHisseMap[realEstateId] = realEstateHisse;
        }else{
            require(_hisse <= payda,  "No more shareholders can be added to the real estate");
            realEstateHisse.payda = payda;
            realEstateHisse.toplamHisseMiktar= _hisse;
            realEstateHisse.registered =true;
            uint newHisseId=block.timestamp;
            realEstateHisse.hisseIdList.push(newHisseId);
            Hisse memory newHisse = Hisse(_hisse,realEstateId, ownAdd, true);
            hisseIdHisseMap[newHisseId] = newHisse;            
            ownerHisseListMap[ownAdd][newHisseId] = true;
            emit NewHisseAndRealEstateAdded(realEstateId, newHisseId, ownAdd);
        }
        
    }

    function getOwnerHisseId(address ownAdd, uint[] memory hisseIdList) public view returns(uint) {
        mapping(uint => bool) storage ownHisseIdList = ownerHisseListMap[ownAdd];
        for(uint i = 0; i< hisseIdList.length; i++){
            if(ownHisseIdList[hisseIdList[i]]){
                return hisseIdList[i];
            }
        }
        return 0;
    }

    function changeOwnerShip(uint hisseId, address newOwner) public {
        //sadece owner
        require(hisseIdHisseMap[hisseId].registered, "Hisse bulunamadi");

        hisseIdHisseMap[hisseId].ownerAdd = newOwner;
        
        ownerHisseListMap[msg.sender][hisseId] = false;
        ownerHisseListMap[newOwner][hisseId] = true;
        emit OwnerShipChanged(hisseId, msg.sender, newOwner);
    }

    function hisseSatisaCikabilirMi(uint hisseId, address ownAdd) public view returns(bool){
        Hisse memory hisse  = hisseIdHisseMap[hisseId];
        return hisse.registered && hisse.ownerAdd == ownAdd;
    }

}