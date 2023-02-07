// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstate.sol";
import "./NotaryContractBase.sol";

contract RealEstateOwnerRelation is NotaryContractBase{
    Owner ownerContract;
    RealEstate realEstateContract;

    mapping(address => uint[]) public ownerHisseIdMap;
    
    mapping(uint => RealEstateHisse) public realEstateIdHisseMap;
    mapping(uint => Hisse) public hisseIdHisseMap;
    uint[] hisseIdLUT;

    event NewHisseAndRealEstateAdded(uint realEstateId, uint hisseId, address owner, uint pay);
    event OwnerHissePayAdded(uint realEstateId, uint hisseId, address owner);
    event NewHisseAddedToRealEstate(uint realEstateId, uint hisseId, address owner, uint pay);
    event OwnerAddedToRealEstate(uint realEstateId, uint hisseId, address owner);
    
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
                hisseIdLUT.push(newHisseId);
                emit NewHisseAddedToRealEstate(realEstateId, newHisseId, ownAdd, _hisse);
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
            hisseIdLUT.push(newHisseId);
            if(payda > 1){
                emit NewHisseAndRealEstateAdded(realEstateId, newHisseId, ownAdd, _hisse);
            }else{
                emit OwnerAddedToRealEstate(realEstateId, newHisseId, ownAdd);
            }
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

    function changeOwnerShip(uint hisseId, address newOwner, address oldOwner) public {
        Hisse memory hisse  = hisseIdHisseMap[hisseId];
        require(hisse.registered, "Hisse bulunamadi");
        //require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");

        hisseIdHisseMap[hisseId].ownerAdd = newOwner;
        
        uint[] storage hisseIdList = ownerHisseIdMap[oldOwner];
        for(uint i = 0; i < hisseIdList.length; i++){
            if(hisseIdList[i] == hisseId){
                hisseIdList[i] = 0;
            } 
        }
        ownerHisseIdMap[newOwner].push(hisseId);
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

    function getAllRealEstateAndHisse() public view returns(HisseView[] memory){
        uint[] memory realEstateLUT = realEstateContract.getRealEstateLUT();
        HisseView [] memory result = new HisseView[](hisseIdLUT.length + realEstateLUT.length);
        uint index = 0;
        for(uint i = 0; i< realEstateLUT.length; i++){
            uint realEstateId = realEstateLUT[i];
            RealEstateHisse memory realEstateHisse = realEstateIdHisseMap[realEstateId];
            RealEstateData memory realEstateData = realEstateContract.getRealEstateInfo(realEstateId);
            if(realEstateHisse.registered){
                for (uint y = 0; y < realEstateHisse.hisseIdList.length; y++) {
                    uint hisseId =  realEstateHisse.hisseIdList[y];
                    result[index++] = HisseView(realEstateId, hisseId, hisseIdHisseMap[hisseId], realEstateData, realEstateHisse.toplamHisseMiktar);  
                }
                if(realEstateHisse.toplamHisseMiktar < realEstateHisse.payda){
                    result[index++] = HisseView(realEstateId, 0, Hisse(0,0,address(0),false), realEstateData, 0);    
                }                
            }else{                
                result[index++] = HisseView(realEstateId, 0, Hisse(0,0,address(0),false), realEstateData, 0);
            }
        }
        return result;
    }

}